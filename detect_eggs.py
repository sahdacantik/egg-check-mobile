# 8.5 Fungsi Deteksi Objek Telur (detect_eggs) — versi baru
# Strategi: deteksi nampan dulu → HoughCircles di dalam nampan

import cv2
import numpy as np

def detect_tray(image):
    """
    Deteksi bounding box nampan hitam.
    Return (x, y, w, h) dalam koordinat image,
    atau None kalau tidak terdeteksi.
    """
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    dark_mask = cv2.inRange(hsv, np.array([0,0,0]), np.array([180,255,80]))

    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (20,20))
    dark_mask = cv2.morphologyEx(dark_mask, cv2.MORPH_CLOSE, kernel)
    dark_mask = cv2.morphologyEx(dark_mask, cv2.MORPH_DILATE, kernel)

    contours, _ = cv2.findContours(dark_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    if not contours:
        return None

    h_img, w_img = image.shape[:2]
    total_area = h_img * w_img

    contours_sorted = sorted(contours, key=cv2.contourArea, reverse=True)
    for c in contours_sorted:
        area = cv2.contourArea(c)
        if area < 0.05 * total_area:
            continue
        x, y, bw, bh = cv2.boundingRect(c)
        aspect = max(bw, bh) / (min(bw, bh) + 1e-5)
        if aspect > 2.5:
            continue
        return (x, y, bw, bh)

    return None


def detect_eggs(image):
    h_img, w_img = image.shape[:2]

    scale = 800 / max(h_img, w_img)
    img_small = cv2.resize(image, (int(w_img*scale), int(h_img*scale)))

    gray = cv2.cvtColor(img_small, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (9,9), 2)

    # 🔥 HoughCircles langsung tanpa nampan
    circles = cv2.HoughCircles(
        blur,
        cv2.HOUGH_GRADIENT,
        dp=1.2,
        minDist=80,
        param1=50,
        param2=18,   # 🔥 diturunin biar lebih sensitif
        minRadius=30,
        maxRadius=120
    )

    egg_crops = []

    if circles is not None:
        circles = np.round(circles[0]).astype(int)
        print("Jumlah telur terdeteksi:", len(circles))

        for (cx, cy, r) in circles:
            cx = int(cx / scale)
            cy = int(cy / scale)
            r  = int(r / scale)

            pad = int(r * 0.2)

            x1 = max(0, cx - r - pad)
            y1 = max(0, cy - r - pad)
            x2 = min(w_img, cx + r + pad)
            y2 = min(h_img, cy + r + pad)

            crop = image[y1:y2, x1:x2]

            if crop.size > 0:
                egg_crops.append(crop)

    return egg_crops