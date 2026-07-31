import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetectionScreen extends StatefulWidget {
  const DetectionScreen({super.key});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  File? _imageFile;
  bool _isProcessing = false;
  bool _serverReady = false;
  final ImagePicker _picker = ImagePicker();

  // ─── Threshold dinamis (berbasis data pengujian) ──────
  double _thrLow = 0.45;
  static const double _thrHigh = 0.80;

  static const String _serverUrl =
      'https://web-production-fcf99.up.railway.app/';

  // ─── Data hasil pengujian threshold ──────────────────
  static const List<Map<String, dynamic>> _thresholdOptions = [
    {
      'value': 0.35,
      'accuracy': 97.53,
      'precision': 98.75,
      'recall': 96.34,
      'f1': 97.53,
      'note': 'Recall tertinggi',
    },
    {
      'value': 0.40,
      'accuracy': 97.33,
      'precision': 98.74,
      'recall': 97.93,
      'f1': 97.32,
      'note': 'F1 tertinggi',
    },
    {
      'value': 0.45,
      'accuracy': 97.53,
      'precision': 99.16,
      'recall': 95.93,
      'f1': 97.52,
      'note': 'Default semhas',
    },
    {
      'value': 0.50,
      'accuracy': 97.33,
      'precision': 99.16,
      'recall': 95.53,
      'f1': 97.31,
      'note': '',
    },
    {
      'value': 0.55,
      'accuracy': 96.91,
      'precision': 99.15,
      'recall': 94.72,
      'f1': 96.88,
      'note': 'Precision 100%',
    },
    {
      'value': 0.60,
      'accuracy': 96.50,
      'precision': 99.14,
      'recall': 93.90,
      'f1': 96.45,
      'note': '',
    },
    {
      'value': 0.65,
      'accuracy': 96.50,
      'precision': 99.14,
      'recall': 93.90,
      'f1': 94.45,
      'note': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    try {
      final response = await http
          .get(Uri.parse('$_serverUrl/'))
          .timeout(const Duration(seconds: 3));
      setState(() => _serverReady = response.statusCode == 200);
    } catch (e) {
      setState(() => _serverReady = false);
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (photo != null) {
      setState(() => _imageFile = File(photo.path));
      await _checkServer();
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (photo != null) {
      setState(() => _imageFile = File(photo.path));
      await _checkServer();
    }
  }

  Future<void> _analyzeEgg() async {
    if (_imageFile == null) return;

    setState(() => _isProcessing = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_serverUrl/predict'),
      );

      // ─── Fields DULU, baru file ───────────────────
      request.fields['threshold_low'] = _thrLow.toStringAsFixed(2);
      request.fields['threshold_high'] = _thrHigh.toStringAsFixed(2);

      request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path),
      );

      var response = await request.send().timeout(
            const Duration(seconds: 60),
          );

      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        var data = jsonDecode(respStr);

        debugPrint('=========== DEBUG BACKEND ===========');
        debugPrint('total: ${data['total']}');
        debugPrint('=====================================');

        if (!mounted) return;

        final int total = data['total'] ?? 0;
        final List results = data['results'] ?? [];

        // ─────────────────────────────────────────────
        // ROUTING:
        // total == 1 → result_screen (single egg + GradCAM)
        // total > 1  → multi_result_screen (grid nampan)
        // ─────────────────────────────────────────────
        if (total == 1 && results.isNotEmpty) {
          // Single egg → ke result_screen
          Navigator.pushNamed(
            context,
            '/result',
            arguments: {
              'result': Map<String, dynamic>.from(results[0]),
              'imagePath': _imageFile!.path,
              'threshold_low': data['threshold_low'] ?? _thrLow,
              'threshold_high': data['threshold_high'] ?? _thrHigh,
            },
          );
        } else {
          // Multi egg → ke multi_result_screen
          Navigator.pushNamed(
            context,
            '/multi_result',
            arguments: {
              'results': List<Map<String, dynamic>>.from(results),
              'imagePath': _imageFile!.path,
              'total': total,
              'layak': data['layak'] ?? 0,
              'perlu_cek': data['perlu_cek'] ?? 0,
              'tidak_layak': data['tidak_layak'] ?? 0,
              'threshold_low': data['threshold_low'] ?? _thrLow,
              'threshold_high': data['threshold_high'] ?? _thrHigh,
            },
          );
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ERROR: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal terhubung ke server: $e',
              style: GoogleFonts.alice(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _analyzeEgg,
            ),
          ),
        );
      }
    }

    if (mounted) setState(() => _isProcessing = false);
  }

  // ─── Warna chip threshold ─────────────────────────────
  Color _chipColor(double val) {
    if (val <= 0.40) return Colors.green.shade600;
    if (val <= 0.45) return const Color(0xFFE9A512);
    if (val <= 0.55) return Colors.orange;
    return Colors.red.shade400;
  }

  // ─── Panel threshold ──────────────────────────────────
  Widget _buildThresholdPanel() {
    final selected = _thresholdOptions.firstWhere((o) => o['value'] == _thrLow);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD08B0A), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Judul + reset ───────────────────────────
          Row(
            children: [
              const Icon(Icons.tune, color: Color(0xFF9B6500), size: 18),
              const SizedBox(width: 6),
              Text(
                'Threshold Klasifikasi',
                style: GoogleFonts.alice(
                    fontSize: 15, color: const Color(0xFF9B6500)),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _thrLow = 0.45),
                child: Text(
                  'Reset',
                  style: GoogleFonts.alice(
                    fontSize: 11,
                    color: const Color(0xFFD08B0A),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Chip pilihan threshold ──────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _thresholdOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final opt = _thresholdOptions[i];
                final bool isSelected = opt['value'] == _thrLow;
                final Color chipColor = _chipColor(opt['value'] as double);

                return GestureDetector(
                  onTap: () => setState(() => _thrLow = opt['value'] as double),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? chipColor : chipColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: chipColor,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      '${((opt['value'] as double) * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.alice(
                        fontSize: 13,
                        color: isSelected ? Colors.white : chipColor,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 14),

          // ── Kartu metrik threshold terpilih ─────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildMetricCard(selected),
          ),

          const SizedBox(height: 10),

          // ── Zona aktif ──────────────────────────────
          _buildZonaSummary(),
        ],
      ),
    );
  }

  Widget _buildMetricCard(Map<String, dynamic> opt) {
    final double val = opt['value'] as double;

    String tradeoff;
    if (val < 0.45) {
      tradeoff = 'Lebih sensitif — FN lebih kecil, FP lebih besar';
    } else if (val == 0.45) {
      tradeoff = 'Nilai default semhas — keseimbangan terbaik';
    } else {
      tradeoff = 'Lebih konservatif — FP = 0, FN lebih besar';
    }

    return Container(
      key: ValueKey(val),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9A512).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Threshold ${(val * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.alice(
                    fontSize: 14, color: const Color(0xFF9B6500)),
              ),
              if ((opt['note'] as String).isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _chipColor(val).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    opt['note'] as String,
                    style:
                        GoogleFonts.alice(fontSize: 10, color: _chipColor(val)),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metricTile(
                  'Accuracy',
                  '${(opt['accuracy'] as double).toStringAsFixed(2)}%',
                  Colors.blue),
              _metricTile(
                  'Precision',
                  '${(opt['precision'] as double).toStringAsFixed(2)}%',
                  Colors.purple),
              _metricTile(
                  'Recall',
                  '${(opt['recall'] as double).toStringAsFixed(2)}%',
                  Colors.teal),
              _metricTile(
                  'F1-Score',
                  '${(opt['f1'] as double).toStringAsFixed(2)}%',
                  Colors.orange),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 12, color: Color(0xFF9B6500)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  tradeoff,
                  style: GoogleFonts.alice(
                      fontSize: 11, color: const Color(0xFF9B6500)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.alice(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.alice(fontSize: 9, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _buildZonaSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _zonaBadge('✅ Layak', '< ${(_thrLow * 100).toStringAsFixed(0)}%',
            Colors.green),
        _zonaBadge(
            '⚠️ Perlu Cek',
            '${(_thrLow * 100).toStringAsFixed(0)}–${(_thrHigh * 100).toStringAsFixed(0)}%',
            Colors.orange),
        _zonaBadge('❌ Tidak Layak', '> ${(_thrHigh * 100).toStringAsFixed(0)}%',
            Colors.red),
      ],
    );
  }

  Widget _zonaBadge(String label, String range, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.alice(fontSize: 10, color: color)),
        Text(range,
            style: GoogleFonts.alice(fontSize: 9, color: Colors.black45)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFFAF),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Header ──────────────────────────────────
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
                                'Deteksi Telur',
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
                                'Ambil atau Pilih Foto Telur',
                                style: GoogleFonts.alice(
                                  fontSize: 15,
                                  color: const Color(0xFFFEFFAF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preview foto
                      Container(
                        width: double.infinity,
                        height: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFD08B0A), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            _buildCorner(
                                top: 12, left: 12, flipH: false, flipV: false),
                            _buildCorner(
                                top: 12, right: 12, flipH: true, flipV: false),
                            _buildCorner(
                                bottom: 12,
                                left: 12,
                                flipH: false,
                                flipV: true),
                            _buildCorner(
                                bottom: 12,
                                right: 12,
                                flipH: true,
                                flipV: true),
                            Center(
                              child: _imageFile == null
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/images/egg_mascot.png',
                                          width: 80,
                                          height: 80,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          'Foto Telur akan Muncul disini',
                                          style: GoogleFonts.alice(
                                            fontSize: 10,
                                            color: const Color(0xFFE9A512),
                                          ),
                                        ),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.file(
                                        _imageFile!,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Sumber Gambar',
                        style: GoogleFonts.alice(
                          fontSize: 18,
                          color: const Color(0xFF9B6500),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: _buildSourceCard(
                              icon: Icons.camera_alt_outlined,
                              label: 'Kamera',
                              sublabel:
                                  'Ambil foto langsung\ndari kamera ponsel',
                              onTap: _pickFromCamera,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildSourceCard(
                              icon: Icons.image_outlined,
                              label: 'Galeri',
                              sublabel:
                                  'Pilih foto dari galeri\nyang sudah ada',
                              onTap: _pickFromGallery,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Threshold panel ──────────────────
                      _buildThresholdPanel(),

                      const SizedBox(height: 28),

                      // Tombol Analisis
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: (_imageFile == null || _isProcessing)
                              ? null
                              : _analyzeEgg,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE9A512),
                            disabledBackgroundColor:
                                const Color(0xFFE9A512).withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 32),
                            elevation: 4,
                          ),
                          icon: const Icon(Icons.search,
                              color: Colors.white, size: 20),
                          label: Text(
                            'Analisis Telur',
                            style: GoogleFonts.alice(
                                fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Status koneksi server
                      Center(
                        child: GestureDetector(
                          onTap: _checkServer,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _serverReady
                                    ? Icons.cloud_done_outlined
                                    : Icons.cloud_off_outlined,
                                size: 14,
                                color:
                                    _serverReady ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _serverReady
                                    ? 'Server siap'
                                    : 'Server tidak terhubung — ketuk untuk coba lagi',
                                style: GoogleFonts.alice(
                                  fontSize: 12,
                                  color: _serverReady
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Loading overlay ──────────────────────────
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFFE9A512)),
                      const SizedBox(height: 16),
                      Text(
                        'Menganalisis telur...',
                        style: GoogleFonts.alice(
                          fontSize: 15,
                          color: const Color(0xFF9B6500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Threshold: ${(_thrLow * 100).toStringAsFixed(0)}% / ${(_thrHigh * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.alice(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────
  Widget _buildSourceCard({
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9A512), width: 1),
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF46C),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(icon, color: const Color(0xFF9B6500), size: 28),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: GoogleFonts.alice(
                    fontSize: 14, color: const Color(0xFF9B6500))),
            const SizedBox(height: 4),
            Text(
              sublabel,
              textAlign: TextAlign.center,
              style: GoogleFonts.alice(
                  fontSize: 10, color: const Color(0xFFD08B0A), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required bool flipH,
    required bool flipV,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.scale(
        scaleX: flipH ? -1 : 1,
        scaleY: flipV ? -1 : 1,
        child: CustomPaint(
          size: const Size(20, 20),
          painter: _CornerPainter(),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD0C8A0)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
