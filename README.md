# SE4AI: Agri Helper - Intelligent Plant Disease Detection System

## Overview
This project is the final semester examination for the Software Engineering for AI course, implementing an intelligent plant disease detection system. The system combines modern mobile development with machine learning to create a practical tool for agricultural disease management.

## Project Architecture

### System Components
```
┌─────────────────┐     ┌──────────────┐     ┌─────────────────┐
│   Mobile App    │     │   Backend    │     │   ML Module     │
│   (Flutter)     │────▶│   (Python)   │────▶│  (TensorFlow)   │
└─────────────────┘     └──────────────┘     └─────────────────┘
        ▲                      │                      │
        │                      ▼                      ▼
        │              ┌──────────────┐     ┌─────────────────┐
        └──────────── │   Firebase   │     │  Image Storage  │
                      │   Services    │     │    (S3/Cloud)   │
                      └──────────────┘     └─────────────────┘
```

### Architectural Components:
1. **Frontend (Mobile Application)**
   - Flutter-based cross-platform application
   - MVC architecture with Provider pattern
   - Responsive UI with material design

2. **Backend Service**
   - RESTful API using Python
   - Lambda functions for serverless operation
   - Image processing and ML model inference

3. **ML Module**
   - TensorFlow-based disease detection model
   - Real-time image processing
   - Multi-class disease classification

4. **Cloud Infrastructure**
   - Firebase Authentication & Firestore
   - AWS/Cloud storage for images
   - Streaming service for real-time updates

## Features
- 🌿 Support for multiple plant types:
  - Rice
  - Apple
  - Strawberry
  - Potato
  - Durian
  - Mango
  - Corn
  - Banana
  - Grape
  - Pepper
  - Tomato
  - Orange
  - Peach

- 📸 Image-based disease detection
- 🔍 Detailed disease information
- 📊 Multiple disease probability predictions
- 🖼️ Disease reference images
- 🌍 Multi-language support (Vietnamese/English)
- 👤 User authentication and profiles
- 📱 Modern and user-friendly interface

## Technical Stack
- **Frontend**: Flutter/Dart
- **Backend Services**: 
  - Firebase Authentication
  - Cloud Firestore
  - Custom API for disease detection
- **Key Dependencies**:
  - flutter_riverpod: State management
  - firebase_auth: User authentication
  - cloud_firestore: Database
  - image_picker: Image selection
  - google_maps_flutter: Location services
  - flutter_local_notifications: Push notifications
  - lottie: Animations
  - google_fonts: Typography

## Getting Started

### Prerequisites
- Flutter SDK ^3.7.2
- Dart SDK
- Android Studio or VS Code
- Firebase account
- Python backend service for model inference

### Installation
1. Clone the repository
```bash
git clone [repository-url]
cd agri_helper
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
- Create a new Firebase project
- Add your Android/iOS app to Firebase
- Download and add the configuration files:
  - `google-services.json` for Android
  - `GoogleService-Info.plist` for iOS

4. Create .env file in the root directory with required environment variables:
```
API_URL=[your-api-endpoint]
```

5. Run the application
```bash
flutter run
```

## Project Structure
```
SE4AI/
├── agri_helper/          # Flutter mobile application
│   ├── lib/             # Application source code
│   ├── assets/          # Static assets and images
│   └── pubspec.yaml     # Flutter dependencies
├── backend/             # Python backend service
│   └── lambda_function.py  # AWS Lambda handler
├── MODEL/               # ML model and training
│   ├── train_model.py  # Model training script
│   ├── model_use.py    # Model inference code
│   └── utils.py        # Utility functions
├── streaming/          # Real-time data streaming
│   ├── Dockerfile      # Container configuration
│   └── nginx.conf      # Nginx configuration
└── requirements.txt    # Python dependencies
```

## Implementation Details

### 1. Mobile Application (agri_helper/)
- **Framework**: Flutter/Dart
- **State Management**: Riverpod
- **Key Features**:
  - Real-time image capture and processing
  - Disease detection results display
  - User authentication and profile management
  - Offline capability

### 2. Backend Service (backend/)
- **Technology**: Python, AWS Lambda
- **API Endpoints**:
  - `/predict`: Disease detection endpoint
  - `/upload`: Image upload handler
  - `/results`: Detection results retrieval

### 3. ML Module (MODEL/)
- **Framework**: Pytorch
- **Model Architecture**: CNN-based classification
- **Performance Metrics**:
  - Accuracy
  - Precision
  - Recall
  - F1 Score

### 4. Streaming Service (streaming/)
- **Technology**: Nginx, Docker
- **Features**:
  - Real-time data streaming
  - Load balancing
  - Cache management

### Disease Detection
- Upload plant images through camera or gallery
- Real-time disease detection
- Multiple disease predictions with confidence scores
- Reference images for detected diseases

### User Features
- User authentication
- Profile management
- History tracking
- Customizable settings

## Deployment Guide

### Prerequisites
1. **Development Environment**
   - Python 3.8+
   - Flutter SDK 3.7.2+
   - AWS CLI configured
   - Docker installed

2. **Cloud Services**
   - AWS Account with Lambda access
   - Firebase project
   - S3 bucket for image storage

### Deployment Steps

1. **ML Model Deployment**
```bash
cd MODEL
pip install -r requirements.txt
python train_model.py
# Model will be saved in the specified directory
```

2. **Backend Deployment**
```bash
cd backend
# Deploy to AWS Lambda
aws lambda create-function \
  --function-name agri-helper-backend \
  --runtime python3.8 \
  --handler lambda_function.lambda_handler \
  --zip-file fileb://lambda.zip
```

3. **Mobile App Deployment**
```bash
cd agri_helper
flutter pub get
flutter build apk --release
# APK will be available in build/app/outputs/flutter-apk/
```

4. **Streaming Service Deployment**
```bash
cd streaming
docker build -t agri-helper-streaming .
docker run -p 80:80 agri-helper-streaming
```

## Usage Guide

### For Developers

1. **Local Development Setup**
```bash
# Clone repository
git clone https://github.com/your-username/SE4AI.git

# Set up Python environment
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows
pip install -r requirements.txt

# Set up Flutter environment
cd agri_helper
flutter pub get
```

2. **Running Tests**
```bash
# ML Model tests
cd MODEL
python -m pytest tests/

# Flutter tests
cd agri_helper
flutter test
```

3. **API Documentation**
- Backend API endpoints are documented using OpenAPI/Swagger
- Access the documentation at: `http://your-api-url/docs`

### For Users

1. **Mobile App Installation**
- Download from Google Play Store or App Store
- Or install the APK directly from releases

2. **Using the App**
- Create an account or log in
- Grant necessary permissions (camera, storage)
- Select plant type from the dropdown
- Take or upload a photo of the plant
- View detection results and recommendations

## Performance Metrics

### ML Model Performance
- Training Accuracy: XX%
- Validation Accuracy: XX%
- Test Accuracy: XX%
- Average Inference Time: XXms

### System Performance
- API Response Time: < XXms
- Image Processing Time: < XXs
- App Memory Usage: < XXMB

## Contributing
Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## Authors
- [Your Name] - *Initial work* - [Your GitHub]

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments
- Course instructors and TAs
- Open-source ML model contributors
- Flutter and Firebase teams

## Contact
For support or queries, please contact: taomab123@gmail.com