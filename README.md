# 🥚 Egg Check Mobile

AI-powered mobile application for egg quality inspection using Computer Vision and Convolutional Neural Networks (CNN).

This application enables users to detect cracked eggs through image analysis with support for both single-egg and multi-egg inspection. The mobile application communicates with a cloud-based backend API that performs image preprocessing and CNN inference before returning the prediction results.

> This project was developed as part of my Bachelor's Thesis in Computer Science at Universitas Pakuan.

---

## ✨ Features

- 📷 Capture images directly from camera or gallery
- 🥚 Single egg quality inspection
- 🥚🥚 Multi-egg inspection (up to 30 eggs)
- 🔍 Automatic detail check from multiple viewing angles
- 📊 Confidence score for every prediction
- 🔥 Grad-CAM visualization for model interpretability
- ☁️ Cloud-based inference through REST API
- 📱 Cross-platform application built with Flutter

---

## 🎥 Application Demo

The following demonstration shows the complete workflow of the application, from capturing an egg image to receiving AI-powered prediction results.

<p align="center">
  <img src="demo.gif" alt="Egg Check Mobile Demo" width="320">
</p>

---

## 🏗 System Architecture

```
Flutter App
      │
      │ HTTP Request
      ▼
Flask REST API
      │
Automatic Preprocessing Pipeline
      │
CNN (MobileNetV2)
      │
Prediction + GradCAM
      │
JSON Response
      ▼
Flutter Application
```

---

## ⚙ Tech Stack

### Mobile

- Flutter
- Dart

### Backend Communication

- REST API
- HTTP Package

### AI

- TensorFlow
- MobileNetV2
- Computer Vision

### Other

- Image Picker
- JSON
- Railway

---

## 🚀 Key Features

### Single Egg Inspection

Users can capture or upload a single egg image to receive:

- Egg quality classification
- Confidence score
- Grad-CAM visualization

---

### Multi Egg Inspection

The application supports simultaneous inspection of multiple eggs.

The backend automatically:

- detects the egg tray
- segments individual eggs
- preprocesses each image
- performs CNN inference
- returns prediction for every detected egg

Supports up to **30 eggs** in a single image. :contentReference[oaicite:0]{index=0}

---

### Detail Check

When an egg falls into the **Need Further Inspection** zone, users are guided to capture images from different angles.

The application:

- captures up to three viewing angles
- performs prediction for every image
- stops early if a cracked egg is detected
- uses the highest crack probability as the final result

---

## 🔗 Backend Repository

This mobile application communicates with:

➡️ **[Egg Check Server]([https://github.com/sahdacantik/egg-check-server.git])**

---

## 👨‍💻 Author

Sahda Rahani Susilawati

• Computer Science • Software Engineer • Computer Vision
