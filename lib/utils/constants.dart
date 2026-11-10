class AppConstants {
  // API Endpoints
  static const String baseUrl = 'http://localhost:3000/api';
  
  // App Colors
  static const int primaryColor = 0xFF2E7D32;
  static const int secondaryColor = 0xFF4CAF50;
  
  // App Strings
  static const String appName = 'Nyamira EDAMS';
  static const String appDescription = 'Electronic Development Application Management System';
  
  // Status Values
  static const List<String> applicationStatuses = [
    'Pending',
    'Under Review',
    'Approved',
    'Rejected',
    'Completed'
  ];
  
  static const List<String> applicationTypes = [
    'Building Permit',
    'Development Permit',
    'Change of Use',
    'Subdivision Permit',
    'Renewal Application'
  ];
}
