import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MultiResultScreen extends StatelessWidget {
  const MultiResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null || args is! Map<String, dynamic>) {
      return const Scaffold(
        body: Center(child: Text("Data tidak ditemukan")),
      );
    }

    final String imagePath = args['imagePath'] ?? '';
    final List<Map<String, dynamic>> results =
        List<Map<String, dynamic>>.from(args['results'] ?? []);

    final double thrLow = (args['threshold_low'] ?? 0.45).toDouble();
    final double thrHigh = (args['threshold_high'] ?? 0.80).toDouble();

    final int totalTelur = args['total'] ?? results.length;
    final int layakCount = args['layak'] ?? 0;
    final int perluCekCount = args['perlu_cek'] ?? 0;
    final int tidakLayakCount = args['tidak_layak'] ?? 0;

    String trayType;
    if (totalTelur >= 30) {
      trayType = 'Tray 30';
    } else if (totalTelur >= 15) {
      trayType = 'Half Tray';
    } else if (totalTelur >= 6) {
      trayType = 'Mini Tray';
    } else {
      trayType = 'Tanpa Tray';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFEFFAF),
      body: Column(
        children: [
          // ================= HEADER =================
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE9A512),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Padding(
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
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Hasil Deteksi',
                        style: GoogleFonts.alice(
                          fontSize: 24,
                          color: const Color(0xFFFEFFAF),
                        ),
                      ),
                      Text(
                        trayType,
                        style: GoogleFonts.alice(
                          fontSize: 13,
                          color: const Color(0xFFFEFFAF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Threshold: ${(thrLow * 100).toStringAsFixed(0)}% / ${(thrHigh * 100).toStringAsFixed(0)}%',
                        style: GoogleFonts.alice(
                          fontSize: 11,
                          color: const Color(0xFFFFF8DC),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ================= BODY =================
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Foto nampan ────────────────────────
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: imagePath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              File(imagePath),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : const Center(child: Text("Gambar tidak tersedia")),
                  ),

                  const SizedBox(height: 16),

                  // ── Summary 4 box ──────────────────────
                  Row(
                    children: [
                      _summaryBox('$layakCount', 'Layak', Colors.green),
                      _summaryBox('$perluCekCount', 'Perlu Cek', Colors.orange),
                      _summaryBox('$tidakLayakCount', 'Retak', Colors.red),
                      _summaryBox(
                          '$totalTelur', 'Total', const Color(0xFF9B6500)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Legenda zona (dinamis) ─────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFD08B0A), width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _legendItem(
                          Colors.green,
                          '✅ Layak',
                          '< ${(thrLow * 100).toStringAsFixed(0)}% retak',
                        ),
                        _legendItem(
                          Colors.orange,
                          '⚠️ Perlu Cek',
                          '${(thrLow * 100).toStringAsFixed(0)}–${(thrHigh * 100).toStringAsFixed(0)}% retak',
                        ),
                        _legendItem(
                          Colors.red,
                          '❌ Tidak Layak',
                          '> ${(thrHigh * 100).toStringAsFixed(0)}% retak',
                        ),
                      ],
                    ),
                  ),

                  // ── Info tap untuk PERLU CEK ───────────
                  if (perluCekCount > 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.orange.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app_outlined,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap telur ⚠️ untuk cek lebih lanjut dari 3 sudut',
                              style: GoogleFonts.alice(
                                  fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Grid telur ─────────────────────────
                  results.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Tidak ada hasil deteksi.',
                            style: GoogleFonts.alice(
                              fontSize: 14,
                              color: const Color(0xFF9B6500),
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: totalTelur > 10 ? 3 : 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final r = results[index];
                            final String zona = r['zona'] ?? 'LAYAK';
                            final double tingkatKelayakan =
                                (r['tingkat_kelayakan'] ?? 0).toDouble();
                            final int eggNumber = r['egg'] ?? (index + 1);
                            final String? cropImage = r['crop_image'];

                            return _eggCard(
                              context: context,
                              index: eggNumber,
                              zona: zona,
                              tingkatKelayakan: tingkatKelayakan,
                              cropImage: cropImage,
                              result: r,
                              thrLow: thrLow,
                              thrHigh: thrHigh,
                            );
                          },
                        ),

                  const SizedBox(height: 20),

                  // ── Info banner ────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: tidakLayakCount > 0
                          ? Colors.red.withOpacity(0.08)
                          : perluCekCount > 0
                              ? Colors.orange.withOpacity(0.08)
                              : Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: tidakLayakCount > 0
                            ? Colors.red
                            : perluCekCount > 0
                                ? Colors.orange
                                : Colors.green,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tidakLayakCount > 0
                              ? Icons.warning_amber_rounded
                              : perluCekCount > 0
                                  ? Icons.info_outline
                                  : Icons.check_circle_outline,
                          color: tidakLayakCount > 0
                              ? Colors.red
                              : perluCekCount > 0
                                  ? Colors.orange
                                  : Colors.green,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            tidakLayakCount > 0
                                ? "Ada $tidakLayakCount telur retak, segera pisahkan!"
                                : perluCekCount > 0
                                    ? "$perluCekCount telur perlu inspeksi lanjut — tap untuk cek sudut lain"
                                    : "Semua $totalTelur telur dalam kondisi baik 👍",
                            style: GoogleFonts.alice(
                              fontSize: 14,
                              color: tidakLayakCount > 0
                                  ? Colors.red
                                  : perluCekCount > 0
                                      ? Colors.orange
                                      : Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Tombol Ulangi ──────────────────────
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE9A512),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 32),
                    ),
                    icon: const Icon(Icons.refresh,
                        color: Colors.white, size: 20),
                    label: Text(
                      'Ulangi',
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

  // ================= WIDGETS =================

  Widget _legendItem(Color color, String label, String sublabel) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.alice(fontSize: 11, color: color)),
        Text(sublabel,
            style: GoogleFonts.alice(fontSize: 10, color: Colors.black45)),
      ],
    );
  }

  Widget _summaryBox(String value, String label, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.alice(fontSize: 10, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eggCard({
    required BuildContext context,
    required int index,
    required String zona,
    required double tingkatKelayakan,
    required String? cropImage,
    required Map<String, dynamic> result,
    required double thrLow,
    required double thrHigh,
  }) {
    Color borderColor;
    Color bgColor;
    String zonaLabel;
    IconData zonaIcon;

    switch (zona) {
      case 'TIDAK LAYAK':
        borderColor = Colors.red;
        bgColor = Colors.red.withOpacity(0.05);
        zonaLabel = '❌ TIDAK LAYAK';
        zonaIcon = Icons.warning_amber_rounded;
        break;
      case 'PERLU CEK':
        borderColor = Colors.orange;
        bgColor = Colors.orange.withOpacity(0.05);
        zonaLabel = '⚠️ PERLU CEK';
        zonaIcon = Icons.help_outline;
        break;
      default:
        borderColor = Colors.green;
        bgColor = Colors.green.withOpacity(0.05);
        zonaLabel = '✅ LAYAK';
        zonaIcon = Icons.check_circle_outline;
    }

    final bool isTappable = zona == 'PERLU CEK';

    return GestureDetector(
      onTap: isTappable
          ? () {
              // Decode crop image untuk diteruskan ke detail_check
              // sebagai preview awal
              Navigator.pushNamed(
                context,
                '/detail_check',
                arguments: {
                  'initial_result': result,
                  // crop_image (base64) diteruskan sebagai referensi visual
                  'initial_crop_b64': result['crop_image'],
                  'threshold_low': thrLow,
                  'threshold_high': thrHigh,
                  // dari multi egg, tidak ada imagePath file lokal
                  // detail_check akan langsung minta foto baru
                  'from_multi': true,
                  'egg_number': index,
                },
              );
            }
          : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              children: [
                // Gambar crop telur
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                    child: cropImage != null && cropImage.isNotEmpty
                        ? Image.memory(
                            base64Decode(cropImage),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey.withOpacity(0.1),
                            child: Icon(zonaIcon, color: borderColor, size: 32),
                          ),
                  ),
                ),

                // Info
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                  child: Column(
                    children: [
                      Text(
                        'Telur $index',
                        style: GoogleFonts.alice(
                          fontSize: 11,
                          color: const Color(0xFF9B6500),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        zonaLabel,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.alice(
                          fontSize: 9,
                          color: borderColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${tingkatKelayakan.toStringAsFixed(1)}%',
                        style: GoogleFonts.alice(
                            fontSize: 9, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Badge "Tap" di pojok kanan atas kalau PERLU CEK ──
          if (isTappable)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Cek Lanjut',
                  style: GoogleFonts.alice(fontSize: 8, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
