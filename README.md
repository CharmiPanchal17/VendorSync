# VendorSync

A Flutter application for vendor-supplier synchronization and order management.

## Getting Started

### Prerequisites

- [Flutter](https://flutter.dev/docs/get-started/install) (latest stable version)
- [Dart](https://dart.dev/get-dart) (comes with Flutter)
- [Android Studio](https://developer.android.com/studio) or [VS Code](https://code.visualstudio.com/)
- For iOS development: Xcode (macOS only)

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repository-url>
   cd VendorSync
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up Firebase** (Required for the app to work)
   
   Since Firebase configuration files are excluded from version control for security reasons, you'll need to:
   
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Add Android and iOS apps to your Firebase project
   - Download the configuration files:
     - `google-services.json` → Place in `android/app/`
     - `GoogleService-Info.plist` → Place in `ios/Runner/`
   - Enable Authentication and Firestore in your Firebase project

4. **Run the app**
   ```bash
   flutter run
   ```

### Development

- **Hot reload**: Press `r` in the terminal while the app is running
- **Hot restart**: Press `R` in the terminal while the app is running
- **Quit**: Press `q` in the terminal

### Building for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
├── screens/                  # UI screens
│   ├── vendor/              # Vendor-specific screens
│   └── supplier/            # Supplier-specific screens
└── mock_data/               # Mock data for development
```

## Features

- User authentication and role-based access
- Vendor dashboard for order management
- Supplier dashboard for order fulfillment
- Real-time notifications
- Order tracking and status updates

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
