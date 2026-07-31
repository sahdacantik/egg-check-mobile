import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFFAF),
      body: Stack(
        children: [
          // ── ScrollView ───────────────────────────────────────────
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Card ──────────────────────────────────────
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
                        top: -80,
                        right: -80,
                        child: Container(
                          width: 380,
                          height: 380,
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
                            top: 52, left: 20, right: 20, bottom: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: const Color(0xFFFEFFAF),
                                      width: 1,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: Image.asset(
                                      'assets/images/egg_mascot.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Stack(
                                          children: [
                                            Text(
                                              'Egg',
                                              style: GoogleFonts.arbutus(
                                                fontSize: 20,
                                                foreground: Paint()
                                                  ..style = PaintingStyle.stroke
                                                  ..strokeWidth = 2
                                                  ..color = Colors.black
                                                      .withOpacity(0.35),
                                              ),
                                            ),
                                            Text(
                                              'Egg',
                                              style: GoogleFonts.arbutus(
                                                fontSize: 20,
                                                color: const Color(0xFFFEFFAF),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        Stack(
                                          children: [
                                            Text(
                                              'Check',
                                              style: GoogleFonts.alice(
                                                fontSize: 20,
                                                fontStyle: FontStyle.italic,
                                                foreground: Paint()
                                                  ..style = PaintingStyle.stroke
                                                  ..strokeWidth = 2
                                                  ..color = Colors.black
                                                      .withOpacity(0.35),
                                              ),
                                            ),
                                            Text(
                                              'Check',
                                              style: GoogleFonts.alice(
                                                fontSize: 20,
                                                fontStyle: FontStyle.italic,
                                                color: const Color(0xFFFEFFAF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Text(
                                      'Klasifikasi Telur Ras',
                                      style: GoogleFonts.balooBhai2(
                                        fontSize: 16,
                                        fontStyle: FontStyle.italic,
                                        color: const Color(0xFFFEFFAF),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Cek Kelayakan\nTelur Ras',
                              style: TextStyle(
                                fontFamily: 'Arial',
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFFFEFFAF),
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFF9B6500),
                                    offset: Offset(0, 3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 1,
                              color: const Color(0xFF9B6500),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Deteksi Cepat & Akurat Berbasis Teknologi AI',
                              style: TextStyle(
                                fontFamily: 'Arial',
                                fontSize: 15,
                                color: Color(0xFFFEFFAF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Petunjuk Penggunaan ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Petunjuk Penggunaan',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.balooBhai2(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF9B6500),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Single Egg
                      _buildSectionTitle('🥚 Satu Telur (Single Egg)'),
                      const SizedBox(height: 10),
                      _buildStep(1,
                          'Letakkan satu telur pada latar belakang POLOS dan TERANG (putih atau abu-abu muda). Hindari latar berwarna kuning, coklat, atau oranye.'),
                      _buildStep(2,
                          'Ambil gambar dari jarak 10–20 cm secara tegak lurus dari atas atau depan telur.'),
                      _buildStep(3,
                          'Pastikan pencahayaan merata, tidak terlalu gelap/terang, dan tidak ada bayangan yang menutupi cangkang.'),
                      _buildStep(4,
                          'Pastikan telur diam dan seluruh permukaan cangkang terlihat jelas dalam frame.'),
                      _buildStep(5,
                          'Tekan "Mulai Deteksi", pilih foto, lalu tunggu hasil analisis.'),

                      const SizedBox(height: 20),

                      // Multi Egg
                      _buildSectionTitle('🥚🥚 Beberapa Telur (Multi Egg)'),
                      const SizedBox(height: 10),
                      _buildStep(1,
                          'Susun telur di atas egg tray dengan posisi rapi di latar belakang POLOS dan TERANG. Hindari egg tray berwarna kuning, coklat, atau warna gelap.'),
                      _buildStep(2,
                          'Pastikan setiap telur TIDAK BERDEMPETAN — beri jarak antar telur agar sistem dapat memisahkan tiap telur secara individual.'),
                      _buildStep(3,
                          'Foto dari atas secara tegak lurus dengan jarak 20–40 cm agar seluruh egg tray masuk dalam frame dengan jelas.'),
                      _buildStep(4,
                          'Pastikan pencahayaan merata dan tidak ada bayangan yang menutupi salah satu telur.'),
                      _buildStep(5,
                          'Tekan "Mulai Deteksi", pilih foto, lalu tunggu hasil analisis per telur.'),
                      _buildStep(6,
                          'Maksimal 50 telur per foto. Jika terdeteksi lebih dari 50, sistem akan meminta foto ulang dengan jumlah telur lebih sedikit.'),
                      _buildStep(7,
                          'Untuk akurasi optimal pada telur yang dicurigai retak, disarankan menggunakan mode Single Egg.'),
                      const SizedBox(height: 100),
                    ],
                  ),
                ), // ← tutup Padding petunjuk
              ],
            ),
          ), // ← tutup SingleChildScrollView

          // ── FAB Mulai Deteksi ────────────────────────────────────
          Positioned(
            bottom: 28,
            right: 24,
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/detection');
              },
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF9B6500),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mulai Deteksi',
                      style: GoogleFonts.balooBhai2(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ), // ← tutup Positioned FAB
        ],
      ), // ← tutup Stack
    ); // ← tutup Scaffold
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9A512).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9A512), width: 1),
      ),
      child: Text(
        title,
        style: GoogleFonts.balooBhai2(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF9B6500),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: GoogleFonts.balooBhai2(
              fontSize: 16,
              color: const Color(0xFF9B6500),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.balooBhai2(
                fontSize: 16,
                color: const Color(0xFF9B6500),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
