import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(child: Text("Data tidak ditemukan")),
      );
    }

    final double thrLow = (args['threshold_low'] ?? 0.45).toDouble();
    final double thrHigh = (args['threshold_high'] ?? 0.80).toDouble();
    final String imagePath = args['imagePath'] ?? '';
    final Map<String, dynamic> result =
        Map<String, dynamic>.from(args['result'] ?? {});

    // ── Data hasil model ──────────────────────────────
    final String zona = result['zona'] ?? 'LAYAK';
    final double confidence = (result['confidence'] ?? 0.0).toDouble();
    final double tingkatKelayakan =
        (result['tingkat_kelayakan'] ?? 0.0).toDouble();
    final double normalProb = tingkatKelayakan;
    final double retakProb = 100.0 - tingkatKelayakan;

    // ── GradCAM (null kalau zona LAYAK) ──────────────
    final String? gradcamB64 = result['gradcam_image'];

    // ── Warna & label zona ────────────────────────────
    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    String detailText1, detailText2, detailText3;

    switch (zona) {
      case 'TIDAK LAYAK':
        statusColor = Colors.red;
        statusLabel = 'Tidak Layak';
        statusIcon = Icons.cancel;
        detailText1 =
            'Model mendeteksi adanya indikasi retakan pada permukaan cangkang';
        detailText2 =
            'Probabilitas kelas retak lebih dominan dibanding kelas normal';
        detailText3 =
            'Telur direkomendasikan untuk dipisahkan dari batch utama';
        break;
      case 'PERLU CEK':
        statusColor = Colors.orange;
        statusLabel = 'Perlu Dicek';
        statusIcon = Icons.help_outline;
        detailText1 =
            'Model mendeteksi kemungkinan adanya retakan halus, namun tingkat keyakinan rendah';
        detailText2 =
            'Probabilitas retak dan normal relatif berimbang — model tidak yakin sepenuhnya';
        detailText3 =
            'Disarankan inspeksi dari beberapa sudut sebelum memutuskan kelayakan telur ini';
        break;
      default: // LAYAK
        statusColor = Colors.green;
        statusLabel = 'Layak';
        statusIcon = Icons.check_circle;
        detailText1 =
            'Model mendeteksi permukaan cangkang telur dalam kondisi utuh';
        detailText2 =
            'Probabilitas telur normal lebih dominan dibanding kelas retak';
        detailText3 =
            'Telur direkomendasikan layak untuk distribusi maupun konsumsi';
    }

    // ── Interpretasi confidence ───────────────────────
    String confidenceText;
    if (confidence >= 90) {
      confidenceText = 'Sangat Tinggi';
    } else if (confidence >= 75) {
      confidenceText = 'Tinggi';
    } else if (confidence >= 60) {
      confidenceText = 'Sedang';
    } else {
      confidenceText = 'Rendah';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEFFAF),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────
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
                            'Hasil Deteksi',
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
                            'Analisis kelayakan telur ras',
                            style: GoogleFonts.alice(
                              fontSize: 13,
                              color: const Color(0xFFFEFFAF),
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Single Egg',
                                style: GoogleFonts.alice(
                                    fontSize: 11, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'T: ${(thrLow * 100).toStringAsFixed(0)}% / ${(thrHigh * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.alice(
                                    fontSize: 10, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusLabel,
                                style: GoogleFonts.alice(
                                    fontSize: 11, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // ── Preview foto asli ──────────────────
                  Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: const Color(0xFFD08B0A), width: 1),
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: imagePath.isNotEmpty
                              ? Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : const Center(
                                  child: Text("Gambar tidak tersedia")),
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  zona == 'PERLU CEK'
                                      ? 'Perlu Dicek'
                                      : zona == 'TIDAK LAYAK'
                                          ? 'Retak Terdeteksi'
                                          : 'Layak',
                                  style: GoogleFonts.alice(
                                      fontSize: 11, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── GradCAM section ────────────────────
                  // Hanya muncul kalau zona PERLU CEK atau TIDAK LAYAK
                  if (gradcamB64 != null && gradcamB64.isNotEmpty) ...[
                    _buildGradcamSection(gradcamB64, zona, statusColor),
                    const SizedBox(height: 16),
                  ],

                  // ── Tombol Cek dari Sudut Lain ─────────
                  // Hanya muncul kalau zona PERLU CEK
                  if (zona == 'PERLU CEK') ...[
                    _buildSudutLainButton(
                        context, result, imagePath, thrLow, thrHigh),
                    const SizedBox(height: 16),
                  ],

                  // ── Status card ────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: const Color(0xFFD08B0A), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUS KELAYAKAN',
                          style: GoogleFonts.alice(
                            fontSize: 12,
                            color: const Color(0xFF9B6500),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 28),
                            const SizedBox(width: 10),
                            Text(
                              statusLabel,
                              style: GoogleFonts.alice(
                                  fontSize: 26, color: statusColor),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            zona == 'PERLU CEK'
                                ? 'Model tidak cukup yakin — disarankan inspeksi dari beberapa sudut'
                                : zona == 'TIDAK LAYAK'
                                    ? 'Ditemukan indikasi retakan pada cangkang telur'
                                    : 'Cangkang telur dalam kondisi normal',
                            style: GoogleFonts.alice(
                                fontSize: 12, color: statusColor),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Confidence bar
                        Text(
                          'Confidence Model',
                          style: GoogleFonts.alice(
                              fontSize: 13, color: const Color(0xFF9B6500)),
                        ),
                        const SizedBox(height: 8),
                        Stack(
                          children: [
                            Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: (confidence / 100).clamp(0.0, 1.0),
                              child: Container(
                                height: 12,
                                decoration: BoxDecoration(
                                  color: confidence >= 90
                                      ? Colors.green
                                      : confidence >= 75
                                          ? Colors.orange
                                          : Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              confidenceText,
                              style: GoogleFonts.alice(
                                  fontSize: 11, color: const Color(0xFF9B6500)),
                            ),
                            Text(
                              '${confidence.toStringAsFixed(2)}%',
                              style: GoogleFonts.alice(
                                fontSize: 13,
                                color: const Color(0xFF9B6500),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Probability cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildProbabilityCard(
                                title: 'Tingkat Kelayakan',
                                value: normalProb,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildProbabilityCard(
                                title: 'Probabilitas Retak',
                                value: retakProb,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Badge
                        Row(
                          children: [
                            _buildBadge(statusLabel, statusColor),
                            const SizedBox(width: 8),
                            _buildBadge(
                              confidenceText,
                              confidence >= 75 ? Colors.green : Colors.orange,
                            ),
                            if (zona == 'PERLU CEK') ...[
                              const SizedBox(width: 8),
                              _buildBadge('Perlu Inspeksi', Colors.orange),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Detail analisis ────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF46C),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: const Color(0xFF9B6500), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics_outlined,
                                color: Color(0xFF9B6500), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Detail Analisis',
                              style: GoogleFonts.alice(
                                  fontSize: 16, color: const Color(0xFF9B6500)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailItem(detailText1, zona),
                        _buildDetailItem(detailText2, zona),
                        _buildDetailItem(detailText3, zona),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE9A512),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 32),
                      elevation: 4,
                    ),
                    icon:
                        const Icon(Icons.search, color: Colors.white, size: 20),
                    label: Text(
                      'Ulangi Deteksi',
                      style:
                          GoogleFonts.alice(fontSize: 16, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── GradCAM section ────────────────────────────────────
  Widget _buildGradcamSection(
      String gradcamB64, String zona, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thermostat_outlined, color: statusColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Area Terdeteksi (GradCAM)',
                style: GoogleFonts.alice(
                    fontSize: 15, color: const Color(0xFF9B6500)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Area merah = area yang mempengaruhi keputusan model',
            style: GoogleFonts.alice(fontSize: 11, color: Colors.black45),
          ),
          const SizedBox(height: 12),

          // Gambar GradCAM overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              base64Decode(gradcamB64),
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 10),

          // Legenda warna heatmap
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _heatmapLegendItem(Colors.blue.shade300, 'Tidak relevan'),
              const SizedBox(width: 12),
              _heatmapLegendItem(Colors.green.shade400, 'Sedikit relevan'),
              const SizedBox(width: 12),
              _heatmapLegendItem(Colors.yellow.shade600, 'Relevan'),
              const SizedBox(width: 12),
              _heatmapLegendItem(Colors.red, 'Sangat relevan'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heatmapLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: GoogleFonts.alice(fontSize: 9, color: Colors.black54),
        ),
      ],
    );
  }

  // ── Tombol Cek dari Sudut Lain ─────────────────────────
  Widget _buildSudutLainButton(
    BuildContext context,
    Map<String, dynamic> result,
    String imagePath,
    double thrLow,
    double thrHigh,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.rotate_90_degrees_ccw_outlined,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hasil masih meragukan?',
                  style: GoogleFonts.alice(fontSize: 14, color: Colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Foto telur dari 3 sudut berbeda untuk hasil yang lebih pasti. '
            'Sistem akan mengaggregasi probabilitas dari tiap sudut.',
            style: GoogleFonts.alice(
                fontSize: 11, color: Colors.black54, height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/detail_check',
                  arguments: {
                    'initial_result': result,
                    'initial_image': imagePath,
                    'threshold_low': thrLow,
                    'threshold_high': thrHigh,
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                elevation: 2,
              ),
              icon: const Icon(Icons.camera_alt_outlined,
                  color: Colors.white, size: 18),
              label: Text(
                'Cek dari Sudut Lain',
                style: GoogleFonts.alice(fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ─────────────────────────────────────
  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.alice(fontSize: 13, color: color),
      ),
    );
  }

  Widget _buildDetailItem(String text, String zona) {
    Color iconColor;
    IconData icon;
    switch (zona) {
      case 'TIDAK LAYAK':
        iconColor = Colors.red;
        icon = Icons.cancel;
        break;
      case 'PERLU CEK':
        iconColor = Colors.orange;
        icon = Icons.help_outline;
        break;
      default:
        iconColor = Colors.green;
        icon = Icons.check_circle;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.alice(
                fontSize: 13,
                color: const Color(0xFF9B6500),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProbabilityCard({
    required String title,
    required double value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.alice(fontSize: 12, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(2)}%',
            style: GoogleFonts.alice(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
