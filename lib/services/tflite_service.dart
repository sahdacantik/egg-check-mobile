import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class EggDetectionResult {
  final String status; // 'Normal' atau 'Retak'
  final double confidence; // confidence dari kelas yang diprediksi
  final double normalProb; // probabilitas Normal
  final double retakProb; // probabilitas Retak
  final bool isLayak;
  final img.Image? croppedImage; // gambar hasil crop (untuk multi egg)

  EggDetectionResult({
    required this.status,
    required this.confidence,
    required this.normalProb,
    required this.retakProb,
    required this.isLayak,
    this.croppedImage,
  });
}

class TfliteService {
  static Interpreter? _interpreter;
  static bool _isInitialized = false;

  // Index label sesuai class_dict.csv: 0=normal, 1=retak
  static const int _normalIndex = 0;
  static const int _retakIndex = 1;
  static const int _inputSize = 224;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model_telur.tflite',
        options: options,
      );
      _isInitialized = true;
      print('TFLite model loaded successfully');
    } catch (e) {
      print('Error loading model: $e');
      rethrow;
    }
  }

  // ============================================================
  // MAIN PREDICT — otomatis handle single vs multi egg
  // ============================================================
  static Future<List<EggDetectionResult>> predict(File imageFile) async {
    if (!_isInitialized) await initialize();

    // Load gambar
    final bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) throw Exception('Gagal membaca gambar');

    // Deteksi kontur telur
    final eggRegions = _detectEggRegions(originalImage);

    if (eggRegions.isEmpty) {
      // Fallback: proses gambar penuh
      print('Tidak ada telur terdeteksi, proses gambar penuh');
      final result = await _predictSingleCrop(originalImage, null);
      return [result];
    }

    if (eggRegions.length == 1) {
      // Single egg
      print('Single egg terdeteksi');
      final result = await _predictSingleCrop(originalImage, eggRegions.first);
      return [result];
    }

    // Multi egg
    print('Multi egg terdeteksi: ${eggRegions.length} telur');
    if (eggRegions.length > 5) {
      // Warning lebih dari 5, tapi tetap proses
      print('Warning: lebih dari 5 telur, hasil mungkin kurang optimal');
    }

    final results = <EggDetectionResult>[];
    for (final region in eggRegions) {
      final result = await _predictSingleCrop(originalImage, region);
      results.add(result);
    }
    return results;
  }

  // ============================================================
  // PREDICT SATU CROP
  // ============================================================
  static Future<EggDetectionResult> _predictSingleCrop(
      img.Image original, List<int>? region) async {
    img.Image processed;

    if (region != null) {
      // Crop ke area telur dengan padding
      final x = max(0, region[0] - 10);
      final y = max(0, region[1] - 10);
      final w = min(original.width - x, region[2] + 20);
      final h = min(original.height - y, region[3] + 20);
      processed = img.copyCrop(original, x: x, y: y, width: w, height: h);
    } else {
      processed = img.copyResize(original,
          width: original.width, height: original.height);
    }

    // Remove background — set piksel non-telur jadi putih
    processed = _removeBackground(processed);

    // Resize ke 224x224
    final resized =
        img.copyResize(processed, width: _inputSize, height: _inputSize);

    // Normalisasi ke [0,1] dan buat input tensor
    final input = _imageToInput(resized);

    // Jalankan inferensi
    final output = List.filled(2, 0.0).reshape([1, 2]);
    _interpreter!.run(input, output);

    final normalProb = output[0][_normalIndex] as double;
    final retakProb = output[0][_retakIndex] as double;

    final isNormal = normalProb > retakProb;
    final status = isNormal ? 'Normal' : 'Retak';
    final confidence = isNormal ? normalProb : retakProb;

    print(
        'Hasil: $status | Normal: ${(normalProb * 100).toStringAsFixed(1)}% | Retak: ${(retakProb * 100).toStringAsFixed(1)}%');

    return EggDetectionResult(
      status: status,
      confidence: confidence,
      normalProb: normalProb,
      retakProb: retakProb,
      isLayak: isNormal,
      croppedImage: processed,
    );
  }

  // ============================================================
  // DETEKSI REGION TELUR (kontur-based)
  // ============================================================
  static List<List<int>> _detectEggRegions(img.Image image) {
    final regions = <List<int>>[];

    // Convert ke grayscale
    final gray = img.grayscale(img.copyResize(image,
        width: image.width ~/ 2, height: image.height ~/ 2));

    // Deteksi area non-background dengan threshold adaptif
    // Cari area yang bukan background (bukan putih/kuning terang)
    final width = gray.width;
    final height = gray.height;

    // Buat binary mask
    final mask = List.generate(height, (_) => List.filled(width, false));

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = gray.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Deteksi warna telur (coklat/krem) — bukan putih/background
        final isEggColor = _isEggPixel(r, g, b);
        mask[y][x] = isEggColor;
      }
    }

    // Connected component labeling sederhana untuk temukan blob
    final blobs = _findBlobs(mask, width, height);

    // Scale back ke ukuran original
    final scaleX = image.width / width;
    final scaleY = image.height / height;

    final minBlobArea = (width * height * 0.02).toInt(); // min 2% area

    for (final blob in blobs) {
      if (blob['area']! < minBlobArea) continue;

      final x = (blob['minX']! * scaleX).toInt();
      final y = (blob['minY']! * scaleY).toInt();
      final w = ((blob['maxX']! - blob['minX']!) * scaleX).toInt();
      final h = ((blob['maxY']! - blob['minY']!) * scaleY).toInt();

      // Filter: region harus cukup besar dan mendekati aspek rasio telur
      if (w > 30 && h > 30) {
        final aspectRatio = w / h;
        if (aspectRatio > 0.4 && aspectRatio < 2.5) {
          regions.add([x, y, w, h]);
        }
      }
    }

    print('Regions terdeteksi: ${regions.length}');
    return regions;
  }

  // ============================================================
  // CEK APAKAH PIKSEL WARNA TELUR
  // ============================================================
  static bool _isEggPixel(int r, int g, int b) {
    // Warna telur ayam ras: coklat, krem, oranye kecoklatan
    // Exclude putih (background) dan hitam
    final brightness = (r + g + b) / 3;

    // Bukan terlalu terang (background putih)
    if (brightness > 230) return false;
    // Bukan terlalu gelap
    if (brightness < 30) return false;

    // Warna telur biasanya reddish-brown atau cream
    // r > g dan r > b untuk warna coklat/oranye
    final isWarmColor = r >= g - 20;

    return isWarmColor && brightness > 60 && brightness < 220;
  }

  // ============================================================
  // REMOVE BACKGROUND
  // ============================================================
  static img.Image _removeBackground(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);

    // Fill dengan putih dulu
    img.fill(result, color: img.ColorRgb8(255, 255, 255));

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        if (_isEggPixel(r, g, b)) {
          result.setPixel(x, y, pixel);
        }
        // Piksel non-telur tetap putih
      }
    }

    return result;
  }

  // ============================================================
  // FIND BLOBS (connected components)
  // ============================================================
  static List<Map<String, int>> _findBlobs(
      List<List<bool>> mask, int width, int height) {
    final visited = List.generate(height, (_) => List.filled(width, false));
    final blobs = <Map<String, int>>[];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (mask[y][x] && !visited[y][x]) {
          // BFS untuk temukan blob
          final queue = <List<int>>[
            [x, y]
          ];
          visited[y][x] = true;
          int minX = x, maxX = x, minY = y, maxY = y, area = 0;

          while (queue.isNotEmpty) {
            final point = queue.removeAt(0);
            final px = point[0];
            final py = point[1];
            area++;

            if (px < minX) minX = px;
            if (px > maxX) maxX = px;
            if (py < minY) minY = py;
            if (py > maxY) maxY = py;

            // 4-connectivity neighbors
            for (final dir in [
              [-1, 0],
              [1, 0],
              [0, -1],
              [0, 1]
            ]) {
              final nx = px + dir[0];
              final ny = py + dir[1];
              if (nx >= 0 &&
                  nx < width &&
                  ny >= 0 &&
                  ny < height &&
                  mask[ny][nx] &&
                  !visited[ny][nx]) {
                visited[ny][nx] = true;
                queue.add([nx, ny]);
              }
            }
          }

          blobs.add({
            'minX': minX,
            'maxX': maxX,
            'minY': minY,
            'maxY': maxY,
            'area': area,
          });
        }
      }
    }

    // Urutkan berdasarkan area terbesar
    blobs.sort((a, b) => b['area']!.compareTo(a['area']!));
    return blobs;
  }

  // ============================================================
  // CONVERT IMAGE KE INPUT TENSOR
  // ============================================================
  static List<List<List<List<double>>>> _imageToInput(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );
    return input;
  }

  static void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
