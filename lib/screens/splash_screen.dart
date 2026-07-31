import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late Animation<double> _contentSlide;

  @override
  void initState() {
    super.initState();

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _contentSlide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _contentController.forward();
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _contentController,
        builder: (context, child) {
          return Stack(
            children: [
              // Background dari asset
              Positioned.fill(
                child: Image.asset(
                  'assets/images/background_splash_screen.png',
                  fit: BoxFit.cover,
                ),
              ),

              // Sparkle dots
              if (_contentController.value > 0) ...[
                _buildSparkle(size, 0.12, 0.15, 20),
                _buildSparkle(size, 0.80, 0.12, 14),
                _buildSparkle(size, 0.06, 0.50, 12),
                _buildSparkle(size, 0.88, 0.45, 18),
                _buildSparkle(size, 0.20, 0.80, 10),
                _buildSparkle(size, 0.75, 0.75, 16),
                _buildSparkle(size, 0.50, 0.08, 12),
                _buildSparkle(size, 0.35, 0.88, 8),
              ],

              // Konten: mascot + teks + tombol
              Opacity(
                opacity: _contentFade.value,
                child: Transform.translate(
                  offset: Offset(0, _contentSlide.value),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Lingkaran putih blur di belakang maskot
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.75),
                                    Colors.white.withOpacity(0.35),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                  stops: const [0.0, 0.55, 1.0],
                                ),
                              ),
                            ),
                            Image.asset(
                              'assets/images/egg_mascot.png',
                              width: 190,
                              height: 190,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ✅ Logo EggCheck — "Egg" dan "Check" dipisah pakai Row biar bisa kasih jarak
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outline hitam — opacity dikurangin biar ga tebel
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Egg',
                                  style: GoogleFonts.arbutus(
                                    fontSize: 40,
                                    foreground:
                                        Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 2.5
                                          ..color = Colors.black.withOpacity(
                                            0.45,
                                          ), // ✅ opacity dikurangin
                                  ),
                                ),
                                const SizedBox(width: 6), // ✅ jarak Egg & Check
                                Text(
                                  'Check',
                                  style: GoogleFonts.alice(
                                    fontSize: 36,
                                    fontStyle: FontStyle.italic,
                                    foreground:
                                        Paint()
                                          ..style = PaintingStyle.stroke
                                          ..strokeWidth = 2.5
                                          ..color = Colors.black.withOpacity(
                                            0.45,
                                          ), // ✅ opacity dikurangin
                                  ),
                                ),
                              ],
                            ),
                            // Fill warna FEFFAF
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Egg',
                                  style: GoogleFonts.arbutus(
                                    fontSize: 40,
                                    color: const Color(0xFFFEFFAF),
                                  ),
                                ),
                                const SizedBox(width: 6), // ✅ jarak Egg & Check
                                Text(
                                  'Check',
                                  style: GoogleFonts.alice(
                                    fontSize: 36,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFFFEFFAF),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 18,
                        ), // ✅ jarak EggCheck ke deskripsi
                        // ✅ Subtitle — ukuran 25
                        const Text(
                          'KLASIFIKASI KELAYAKAN TELUR RAS\nBERBASIS KECERDASAN BUATAN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Arial',
                            fontSize:
                                16, // sedikit dikecilkan agar tidak overflow, sesuaikan jika perlu
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFFFEFFAF),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Tombol Start
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFEFFAF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 48,
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            'Start',
                            style: GoogleFonts.bagelFatOne(
                              fontSize: 25,
                              color: const Color(0xFF9B6500),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSparkle(Size size, double xFrac, double yFrac, double radius) {
    return Positioned(
      left: size.width * xFrac,
      top: size.height * yFrac,
      child: Opacity(
        opacity: _contentFade.value * 0.7,
        child: Container(
          width: radius,
          height: radius,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
