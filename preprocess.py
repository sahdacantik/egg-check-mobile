# 8.4 Fungsi Preprocessing Pipeline untuk Inferensi
# HARUS SAMA dengan preprocessing saat training

import cv2
import numpy as np

def preprocess_image(image_path):

    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"Gambar tidak bisa dibaca: {image_path}")

    # Normalisasi channel (handle grayscale candling)
    if len(img.shape) == 2:
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)

    h_orig, w_orig = img.shape[:2]

    # Deteksi & crop telur
    scale = 600 / max(h_orig, w_orig)
    img_small = cv2.resize(img, (int(w_orig*scale), int(h_orig*scale)))
    gray = cv2.cvtColor(img_small, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (9,9), 2)
    edges = cv2.Canny(blur, 30, 120)
    kernel = np.ones((9,9), np.uint8)
    edges = cv2.dilate(edges, kernel, iterations=2)
    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    crop = img.copy()
    if contours:
        contours_sorted = sorted(contours, key=cv2.contourArea, reverse=True)
        img_small_area = img_small.shape[0] * img_small.shape[1]
        for c in contours_sorted:
            area = cv2.contourArea(c)
            if area < 0.05 * img_small_area or area > 0.95 * img_small_area:
                continue
            x, y, w, h = cv2.boundingRect(c)
            if max(w,h) / (min(w,h) + 1e-5) > 3.0:
                continue
            x,y,w,h = int(x/scale),int(y/scale),int(w/scale),int(h/scale)
            pad_x, pad_y = int(w*0.08), int(h*0.08)
            x1,y1 = max(0,x-pad_x), max(0,y-pad_y)
            x2,y2 = min(w_orig,x+w+pad_x), min(h_orig,y+h+pad_y)
            crop = img[y1:y2, x1:x2]
            break

    # Resize
    resized = cv2.resize(crop, (224, 224))

    # Grayscale
    gray_final = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

    # CLAHE
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    enhanced = clahe.apply(gray_final)

    # Sharpening
    kernel_sharpen = np.array([[0,-1,0],[-1,5,-1],[0,-1,0]])
    sharpened = cv2.filter2D(enhanced, -1, kernel_sharpen)

    # 3 channel untuk MobileNetV2
    final_output = cv2.cvtColor(sharpened, cv2.COLOR_GRAY2RGB)

    return final_output

print("✅ preprocess_image() siap!")