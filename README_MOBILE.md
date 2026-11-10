# EDAMS Mobile Application

## Overview
The EDAMS Mobile Application is a Flutter-based mobile app that provides citizens and stakeholders with access to Nyamira County's Electronic Development Application Management System. The app enables users to submit applications, track their status, make payments, and view land information.

## Features

### 🔐 Authentication System
- User login and registration
- Secure token-based authentication
- Password management
- Session persistence

### 📱 Core Functionality
- **Home Dashboard**: Quick access to main features and recent activities
- **Applications Management**: Create, view, and track permit applications
- **Payments**: View payment history and make new payments
- **Profile Management**: User profile and account settings
- **Map View**: Interactive map showing land parcels and administrative units

### 🏗️ Application Types
- Building Permits
- Development Permits
- Change of Use Applications
- Subdivision Permits
- Permit Renewals

### 📄 Document Management
- Photo and document uploads
- Support for multiple file formats (PDF, DOC, images)
- Document categorization and organization

### 🗺️ Map Features
- Land parcel visualization
- Administrative unit boundaries
- Zoning area information
- Search and filter capabilities

## Technical Architecture

### Frontend
- **Framework**: Flutter 3.2+
- **State Management**: Provider pattern
- **UI Components**: Material Design 3
- **Navigation**: Flutter Navigator 2.0

### Backend Integration
- **API Service**: RESTful API integration
- **Authentication**: JWT token-based auth
- **File Upload**: Multipart form data support
- **Error Handling**: Comprehensive error management

### Local Storage
- **Secure Storage**: Flutter Secure Storage for sensitive data
- **Preferences**: Shared Preferences for user settings
- **Offline Support**: Basic offline functionality

## Project Structure

```
lib/
├── main.dart                 # App entry point and main configuration
├── services/                 # API and business logic services
│   ├── api_service.dart     # HTTP client and API communication
│   ├── auth_service.dart    # Authentication and user management
│   └── application_service.dart # Application-related operations
├── providers/               # State management
│   └── auth_provider.dart  # Authentication state provider
├── pages/                   # Screen implementations
│   ├── login_page.dart     # User authentication screen
│   ├── new_application_page.dart # Application creation form
│   └── map_page.dart       # Map and parcel viewing
└── assets/                  # Images and static resources
```

## Dependencies

### Core Dependencies
- `flutter`: Core Flutter framework
- `http`: HTTP client for API communication
- `provider`: State management solution
- `shared_preferences`: Local data persistence
- `flutter_secure_storage`: Secure data storage
- `image_picker`: Camera and gallery access
- `file_picker`: File selection and upload
- `url_launcher`: External URL handling
- `intl`: Internationalization support

### Development Dependencies
- `flutter_test`: Testing framework
- `flutter_lints`: Code quality and style enforcement

## Getting Started

### Prerequisites
- Flutter SDK 3.2.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / VS Code
- Android SDK (API level 21+)
- iOS development tools (for iOS builds)

### Installation
1. Clone the repository
2. Navigate to the mobile app directory:
   ```bash
   cd edams_mobile
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

### Configuration
1. Update API base URL in `lib/services/api_service.dart`
2. Configure signing for Android/iOS builds
3. Set up Firebase services if needed

## Development Guidelines

### Code Style
- Follow Flutter/Dart style guidelines
- Use meaningful variable and function names
- Add comprehensive comments for complex logic
- Maintain consistent indentation and formatting

### State Management
- Use Provider for simple state management
- Keep business logic in services
- Minimize widget rebuilds with proper state design

### Error Handling
- Implement comprehensive error handling
- Show user-friendly error messages
- Log errors for debugging
- Handle network failures gracefully

### Testing
- Write unit tests for business logic
- Test UI components with widget tests
- Ensure proper error handling coverage

## API Integration

### Authentication Endpoints
- `POST /api/users/login` - User authentication
- `POST /api/users/register` - User registration
- `PUT /api/users/profile` - Profile updates
- `POST /api/users/logout` - User logout

### Application Endpoints
- `GET /api/applications/user` - User applications
- `POST /api/applications` - Create application
- `PUT /api/applications/:id` - Update application
- `GET /api/applications/:id` - Application details

### Document Endpoints
- `POST /api/applications/:id/documents` - Upload documents
- `GET /api/applications/:id/documents` - Get documents

## Deployment

### Android
1. Build APK:
   ```bash
   flutter build apk --release
   ```
2. Build App Bundle:
   ```bash
   flutter build appbundle --release
   ```

### iOS
1. Build for device:
   ```bash
   flutter build ios --release
   ```
2. Archive and distribute via Xcode

## Future Enhancements

### Planned Features
- Push notifications for application updates
- Offline-first architecture
- Advanced map features with real coordinates
- Payment gateway integration
- Multi-language support
- Dark mode theme
- Advanced search and filtering
- Report generation
- Social sharing capabilities

### Technical Improvements
- Integration with real mapping services
- Advanced caching strategies
- Performance optimization
- Accessibility improvements
- Comprehensive testing suite

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Support

For technical support or questions:
- Create an issue in the repository
- Contact the development team
- Check the API documentation

## License

This project is proprietary software developed for Nyamira County Government.

---

**Note**: This mobile application is designed to work in conjunction with the EDAMS backend API and admin panel. Ensure all backend services are properly configured and running before testing mobile app functionality.
