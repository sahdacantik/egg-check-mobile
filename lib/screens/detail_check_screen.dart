import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class DetailCheckScreen extends StatefulWidget {
  const DetailCheckScreen({super.key});

  @override
  State<DetailCheckScreen> createState() => _DetailCheckScreenState();
}

class _DetailCheckScreenState extends State<DetailCheckScreen> {
  final ImagePicker _picker = ImagePicker();

  static const String _serverUrl =
      'https://web-production-fcf99.up.railway.app/';

  // ── Data dari screen sebelumnya ───────────────────────
  late Map<String, dynamic> _initialResult;
  late double _thrLow;
  late double _thrHigh;
  bool _fromMulti = false;
  int _eggNumber = 1;
  String? _initialCropB64;

  // ── State 3 sudut ─────────────────────────────────────
  // Index 0 = Sudut 1, 1 = Sudut 2, 2 = Sudut 3
  final List<File?> _sudutFiles = [null, null, null];
  final List<bool> _sudutLoading = [false, false, false];
  final List<Map<String, dynamic>?> _sudutResults = [null, null, null];

  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        _initialResult =
            Map<String, dynamic>.from(args['initial_result'] ?? {});
        _thrLow = (args['threshold_low'] ?? 0.45).toDouble();
        _thrHigh = (args['threshold_high'] ?? 0.80).toDouble();
        _fromMulti = args['from_multi'] ?? false;
        _eggNumber = args['egg_number'] ?? 1;
        _initialCropB64 = args['initial_crop_b64'];
      }
      _isInitialized = true;
    }
  }

  // ── Foto dari kamera / galeri ─────────────────────────
  Future<void> _pickImage(int sudutIndex, ImageSource source) async {
    final XFile? photo = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1280,
      maxHeight: 1280,
    );
    if (photo == null) return;

    setState(() {
      _sudutFiles[sudutIndex] = File(photo.path);
      _sudutResults[sudutIndex] = null;
    });

    await _analyzeOneSudut(sudutIndex);
  }

  // ── Kirim 1 sudut ke /predict_single ─────────────────
  Future<void> _analyzeOneSudut(int sudutIndex) async {
    final file = _sudutFiles[sudutIndex];
    if (file == null) return;

    setState(() => _sudutLoading[sudutIndex] = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/predict_single'),
      );

      request.fields['threshold_low'] = _thrLow.toStringAsFixed(2);
      request.fields['threshold_high'] = _thrHigh.toStringAsFixed(2);
      request.files.add(
        await http.MultipartFile.fromPath('image', file.path),
      );

      final response = await request.send().timeout(
            const Duration(seconds: 90),
          );

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr) as Map<String, dynamic>;
        setState(() => _sudutResults[sudutIndex] = data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DetailCheck] ERROR sudut $sudutIndex: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal analisis sudut ${sudutIndex + 1}: $e',
              style: GoogleFonts.alice(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _sudutLoading[sudutIndex] = false);
  }

  // ── Aggregasi prob_retak dari sudut yang sudah ada hasil ─
  Map<String, dynamic> _aggregateResults() {
    final doneResults = _sudutResults.where((r) => r != null).toList();
    if (doneResults.isEmpty) return {};

    // Ambil probabilitas retak TERTINGGI dari semua sudut yang sudah dianalisis
    // (bukan rata-rata) — karena retakan yang terlihat di satu sudut saja
    // sudah cukup membuat telur dinyatakan tidak layak. Ini yang membuat
    // early-exit valid: nambah sudut lagi tidak akan pernah menurunkan MAX
    // yang sudah tercapai.
    final double maxRetakProb = doneResults
        .map((r) => (r!['prob_retak'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    final double maxNormalProb = 100.0 - maxRetakProb;
    final double probRetakFraction = maxRetakProb / 100.0;

    String zonaFinal;
    if (probRetakFraction < _thrLow) {
      zonaFinal = 'LAYAK';
    } else if (probRetakFraction < _thrHigh) {
      zonaFinal = 'PERLU CEK';
    } else {
      zonaFinal = 'TIDAK LAYAK';
    }

    return {
      'zona': zonaFinal,
      'avg_retak_prob': maxRetakProb.toStringAsFixed(2),
      'avg_normal_prob': maxNormalProb.toStringAsFixed(2),
      'jumlah_sudut': doneResults.length,
    };
  }

  // ── Semua 3 sudut sudah ada hasilnya ─────────────────
  bool get _allDone => _sudutResults.every((r) => r != null);
  int get _doneSudut => _sudutResults.where((r) => r != null).length;

  // ── EARLY-EXIT: sudah ada sudut yang TIDAK LAYAK ──────
  // Fisik retakan tidak "hilang" kalau dilihat dari sudut lain, jadi begitu
  // satu sudut TIDAK LAYAK, sudut lain tidak perlu difoto lagi.
  bool get _hasTidakLayak =>
      _sudutResults.any((r) => r != null && r['zona'] == 'TIDAK LAYAK');

  // ── Sudah bisa disimpulkan: early-exit TIDAK LAYAK, ATAU 3 sudut selesai ─
  bool get _isConcluded => _hasTidakLayak || _allDone;

  @override
  Widget build(BuildContext context) {
    final aggregated = _aggregateResults();
    // Tampilkan card hasil begitu ada minimal 1 hasil early-exit TIDAK LAYAK,
    // atau progres normal begitu 2+ sudut sudah difoto.
    final bool showFinal = _hasTidakLayak || _doneSudut >= 2 || _allDone;

    return Scaffold(
      backgroundColor: const Color(0xFFFEFFAF),
      body: Column(
        children: [
          // ── Header ──────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE9A512),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.55),
                          Colors.white.withOpacity(0.25),
                          Colors.white.withOpacity(0.0),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 52, left: 16, right: 16, bottom: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Color(0xFFFEFFAF),
                            size: 22,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Cek Detail',
                            style: GoogleFonts.alice(
                              fontSize: 25,
                              color: const Color(0xFFFEFFAF),
                              shadows: const [
                                Shadow(
                                  color: Color(0xFF9B6500),
                                  offset: Offset(0, 2),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _fromMulti
                                ? 'Telur #$_eggNumber — Foto 3 Sudut'
                                : 'Foto 3 Sudut untuk Hasil Lebih Pasti',
                            style: GoogleFonts.alice(
                              fontSize: 13,
                              color: const Color(0xFFFEFFAF),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _hasTidakLayak && !_allDone
                                ? '$_doneSudut / 3 sudut (selesai lebih awal)'
                                : '$_doneSudut / 3 sudut',
                            style: GoogleFonts.alice(
                                fontSize: 11, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Preview awal (crop dari hasil sebelumnya) ──
                  if (_initialCropB64 != null || !_fromMulti) ...[
                    _buildInitialPreview(),
                    const SizedBox(height: 20),
                  ],

                  // ── Instruksi ────────────────────────────
                  _buildInstruksi(),
                  const SizedBox(height: 20),

                  // ── 3 Sudut cards ────────────────────────
                  ...List.generate(
                      3,
                      (i) => Column(
                            children: [
                              _buildSudutCard(i),
                              const SizedBox(height: 14),
                            ],
                          )),

                  // ── Hasil aggregasi ───────────────────────
                  if (showFinal && aggregated.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _buildAggregasiCard(aggregated, isFinal: _isConcluded),
                    const SizedBox(height: 20),
                  ],

                  // ── Tombol selesai (early-exit TIDAK LAYAK ATAU 3 sudut selesai) ──
                  if (_isConcluded) ...[
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.popUntil(
                            context,
                            (r) =>
                                r.isFirst ||
                                ModalRoute.of(context)?.settings.name ==
                                    '/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE9A512),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 32),
                          elevation: 4,
                        ),
                        icon: const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 20),
                        label: Text(
                          'Lihat Kesimpulan / Selesai',
                          style: GoogleFonts.alice(
                              fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Preview awal ───────────────────────────────────────
  Widget _buildInitialPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD08B0A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF9B6500), size: 16),
              const SizedBox(width: 6),
              Text(
                'Hasil Awal (Perlu Dicek)',
                style: GoogleFonts.alice(
                    fontSize: 13, color: const Color(0xFF9B6500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Crop image awal
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _initialCropB64 != null
                    ? Image.memory(
                        base64Decode(_initialCropB64!),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey.withOpacity(0.1),
                        child: const Icon(Icons.egg_outlined,
                            color: Color(0xFFE9A512), size: 32),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prob. Retak Awal',
                      style: GoogleFonts.alice(
                          fontSize: 11, color: Colors.black45),
                    ),
                    Text(
                      '${_initialResult['retakProb'] ?? '–'}%',
                      style: GoogleFonts.alice(
                        fontSize: 22,
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Foto dari ${_fromMulti ? 'deteksi nampan' : 'sudut pertama'} — '
                      'belum cukup yakin',
                      style: GoogleFonts.alice(
                          fontSize: 10, color: Colors.black45, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Instruksi ──────────────────────────────────────────
  Widget _buildInstruksi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF46C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF9B6500), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  color: Color(0xFF9B6500), size: 18),
              const SizedBox(width: 8),
              Text(
                'Cara Foto 3 Sudut',
                style: GoogleFonts.alice(
                    fontSize: 14, color: const Color(0xFF9B6500)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _instruksiItem('1', 'Sudut depan — foto bagian yang dicurigai retak'),
          _instruksiItem('2', 'Putar 90° — foto dari sisi samping telur'),
          _instruksiItem('3', 'Putar 90° lagi — foto dari sisi berlawanan'),
          const SizedBox(height: 6),
          Text(
            'Sistem akan mengambil probabilitas retak tertinggi dari sudut-sudut '
            'yang difoto. Kalau salah satu sudut sudah "Tidak Layak", proses '
            'berhenti otomatis — sudut sisanya tidak perlu difoto lagi.',
            style: GoogleFonts.alice(
                fontSize: 10, color: const Color(0xFF9B6500), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _instruksiItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF9B6500),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              num,
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.alice(
                  fontSize: 12, color: const Color(0xFF9B6500), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card per sudut ─────────────────────────────────────
  Widget _buildSudutCard(int i) {
    final File? file = _sudutFiles[i];
    final bool loading = _sudutLoading[i];
    final Map<String, dynamic>? result = _sudutResults[i];

    final String sudutLabel =
        ['Sudut 1 — Depan', 'Sudut 2 — Samping', 'Sudut 3 — Berlawanan'][i];

    // Sudut ini "dilewati" kalau: belum difoto, DAN sudah ada sudut lain
    // yang TIDAK LAYAK (early-exit) — tidak perlu foto lagi.
    final bool isSkipped = file == null && !loading && _hasTidakLayak;

    // Status card
    Color cardBorder = const Color(0xFFD08B0A);
    if (result != null) {
      final String zona = result['zona'] ?? 'LAYAK';
      if (zona == 'LAYAK') cardBorder = Colors.green;
      if (zona == 'PERLU CEK') cardBorder = Colors.orange;
      if (zona == 'TIDAK LAYAK') cardBorder = Colors.red;
    } else if (isSkipped) {
      cardBorder = Colors.grey;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header card sudut ────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: cardBorder.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cardBorder,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sudutLabel,
                    style: GoogleFonts.alice(
                        fontSize: 13, color: const Color(0xFF9B6500)),
                  ),
                ),
                // Status badge
                if (result != null) _buildZonaBadge(result['zona'] ?? 'LAYAK'),
                if (isSkipped) _buildSkippedBadge(),
                if (loading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFE9A512),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // ── Preview foto + GradCAM ─────────────
                if (file != null || result != null)
                  _buildSudutImageRow(file, result, loading),

                if (isSkipped) ...[
                  // ── Early-exit: sudut ini tidak perlu difoto ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.block,
                            color: Colors.black38, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Dilewati — sudah ditemukan "Tidak Layak" dari sudut lain, '
                            'jadi sudut ini tidak perlu difoto lagi.',
                            style: GoogleFonts.alice(
                                fontSize: 11,
                                color: Colors.black45,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (file == null && !loading) ...[
                  // ── Tombol ambil foto ────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickButton(
                          icon: Icons.camera_alt_outlined,
                          label: 'Kamera',
                          onTap: () => _pickImage(i, ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildPickButton(
                          icon: Icons.image_outlined,
                          label: 'Galeri',
                          onTap: () => _pickImage(i, ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ] else if (file != null && result == null && !loading) ...[
                  // File ada tapi belum dianalisis (seharusnya tidak terjadi,
                  // tapi sebagai fallback)
                  const SizedBox(height: 8),
                  Text(
                    'Menganalisis...',
                    style:
                        GoogleFonts.alice(fontSize: 12, color: Colors.black45),
                  ),
                ] else if (result != null) ...[
                  // ── Hasil per sudut ──────────────────
                  const SizedBox(height: 10),
                  _buildSudutMetrics(result),
                  const SizedBox(height: 8),
                  // Tombol foto ulang
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _sudutFiles[i] = null;
                        _sudutResults[i] = null;
                      });
                    },
                    child: Text(
                      'Foto ulang sudut ini',
                      style: GoogleFonts.alice(
                        fontSize: 11,
                        color: const Color(0xFFD08B0A),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSudutImageRow(
      File? file, Map<String, dynamic>? result, bool loading) {
    final String? gradcamB64 = result?['gradcam_image'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          // Foto asli
          Expanded(
            child: Column(
              children: [
                Text(
                  'Foto',
                  style: GoogleFonts.alice(fontSize: 10, color: Colors.black45),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: file != null
                      ? Image.file(file,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover)
                      : Container(
                          height: 100,
                          color: Colors.grey.withOpacity(0.1),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // GradCAM overlay
          Expanded(
            child: Column(
              children: [
                Text(
                  'GradCAM',
                  style: GoogleFonts.alice(fontSize: 10, color: Colors.black45),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: loading
                      ? Container(
                          height: 100,
                          color: Colors.grey.withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFE9A512),
                            ),
                          ),
                        )
                      : gradcamB64 != null
                          ? Image.memory(
                              base64Decode(gradcamB64),
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              height: 100,
                              color: Colors.grey.withOpacity(0.1),
                              child: Center(
                                child: Text(
                                  'N/A',
                                  style: GoogleFonts.alice(
                                      fontSize: 11, color: Colors.black26),
                                ),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSudutMetrics(Map<String, dynamic> result) {
    final double retakProb = (result['prob_retak'] ?? 0).toDouble();
    final double normalProb = (result['prob_normal'] ?? 0).toDouble();
    final String zona = result['zona'] ?? 'LAYAK';

    Color zonaColor;
    switch (zona) {
      case 'TIDAK LAYAK':
        zonaColor = Colors.red;
        break;
      case 'PERLU CEK':
        zonaColor = Colors.orange;
        break;
      default:
        zonaColor = Colors.green;
    }

    return Row(
      children: [
        Expanded(
          child: _miniMetric(
              'Normal', '${normalProb.toStringAsFixed(1)}%', Colors.green),
        ),
        Expanded(
          child: _miniMetric(
              'Retak', '${retakProb.toStringAsFixed(1)}%', Colors.red),
        ),
        Expanded(
          child: _miniMetric(
              'Zona',
              zona == 'TIDAK LAYAK'
                  ? 'Retak'
                  : zona == 'PERLU CEK'
                      ? 'Cek'
                      : 'Layak',
              zonaColor),
        ),
      ],
    );
  }

  Widget _miniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.alice(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.alice(fontSize: 10, color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildPickButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF46C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE9A512)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF9B6500), size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.alice(
                  fontSize: 12, color: const Color(0xFF9B6500)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZonaBadge(String zona) {
    Color color;
    String label;
    switch (zona) {
      case 'TIDAK LAYAK':
        color = Colors.red;
        label = '❌ Tidak Layak';
        break;
      case 'PERLU CEK':
        color = Colors.orange;
        label = '⚠️ Perlu Cek';
        break;
      default:
        color = Colors.green;
        label = '✅ Layak';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.alice(fontSize: 10, color: color),
      ),
    );
  }

  Widget _buildSkippedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black26),
      ),
      child: Text(
        'Dilewati',
        style: GoogleFonts.alice(fontSize: 10, color: Colors.black45),
      ),
    );
  }

  // ── Card aggregasi final ───────────────────────────────
  Widget _buildAggregasiCard(Map<String, dynamic> aggregated,
      {required bool isFinal}) {
    final String zona = aggregated['zona'] ?? 'PERLU CEK';
    final String avgRetak = aggregated['avg_retak_prob'] ?? '–';
    final String avgNormal = aggregated['avg_normal_prob'] ?? '–';
    final int jumlahSudut = aggregated['jumlah_sudut'] ?? 0;

    Color zonaColor;
    IconData zonaIcon;
    String zonaLabel;
    String zonaDesc;

    switch (zona) {
      case 'TIDAK LAYAK':
        zonaColor = Colors.red;
        zonaIcon = Icons.cancel;
        zonaLabel = 'Tidak Layak';
        zonaDesc = _hasTidakLayak && !_allDone
            ? 'Ditemukan indikasi retak yang cukup jelas dari salah satu sudut '
                '($jumlahSudut sudut difoto). Proses dihentikan lebih awal karena '
                'hasil ini tidak mungkin berubah jadi lebih baik meski sudut '
                'lain difoto. Telur sebaiknya dipisahkan dari batch.'
            : 'Dari $jumlahSudut sudut, ditemukan probabilitas retak tinggi '
                'pada salah satu sudut. Telur sebaiknya dipisahkan dari batch.';
        break;
      case 'PERLU CEK':
        zonaColor = Colors.orange;
        zonaIcon = Icons.help_outline;
        zonaLabel = 'Masih Meragukan';
        zonaDesc =
            'Dari $jumlahSudut sudut, model masih belum yakin di semua sudut. '
            'Pertimbangkan inspeksi manual langsung.';
        break;
      default:
        zonaColor = Colors.green;
        zonaIcon = Icons.check_circle;
        zonaLabel = 'Layak';
        zonaDesc =
            'Dari $jumlahSudut sudut, tidak ditemukan indikasi retak yang signifikan '
            'di sudut manapun. Telur kemungkinan besar tidak retak.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: zonaColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: zonaColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: zonaColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                  isFinal
                      ? Icons.flag_circle_outlined
                      : Icons.analytics_outlined,
                  color: const Color(0xFF9B6500),
                  size: 18),
              const SizedBox(width: 8),
              Text(
                isFinal
                    ? 'Kesimpulan Akhir ($jumlahSudut Sudut)'
                    : 'Progres Sementara ($jumlahSudut Sudut)',
                style: GoogleFonts.alice(
                    fontSize: 14, color: const Color(0xFF9B6500)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Zona final
          Row(
            children: [
              Icon(zonaIcon, color: zonaColor, size: 32),
              const SizedBox(width: 10),
              Text(
                zonaLabel,
                style: GoogleFonts.alice(fontSize: 28, color: zonaColor),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Rata-rata prob
          Row(
            children: [
              Expanded(
                child: _aggMetric(
                    'Normal (Sudut Terbaik)', '$avgNormal%', Colors.green),
              ),
              Expanded(
                child: _aggMetric(
                    'Retak (Sudut Terparah)', '$avgRetak%', Colors.red),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Deskripsi
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: zonaColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              zonaDesc,
              style: GoogleFonts.alice(
                  fontSize: 12, color: zonaColor, height: 1.5),
            ),
          ),

          // Progress sudut
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final bool done = _sudutResults[i] != null;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: done ? 32 : 24,
                height: 8,
                decoration: BoxDecoration(
                  color: done ? zonaColor : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              isFinal
                  ? (_hasTidakLayak && !_allDone
                      ? 'Selesai lebih awal — sudut sisanya tidak perlu difoto'
                      : 'Semua sudut selesai dianalisis')
                  : 'Tambah sudut lagi untuk hasil lebih akurat',
              style: GoogleFonts.alice(fontSize: 10, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aggMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.alice(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.alice(fontSize: 10, color: Colors.black45),
          ),
        ],
      ),
    );
  }
}
