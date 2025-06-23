/// API Keys configuration
/// 
/// ⚠️  IMPORTANT: You MUST replace the placeholder below with your actual API key!
/// 
/// To get your Google Places API key:
/// 1. Go to https://console.cloud.google.com/
/// 2. Create a project or select existing one
/// 3. Enable Places API (APIs & Services > Library > Places API)
/// 4. Create API key (APIs & Services > Credentials > Create Credentials > API Key)
/// 5. Replace 'YOUR_GOOGLE_PLACES_API_KEY' below with your actual key
/// 
/// For security, consider using environment variables or secure storage
class ApiKeys {
  /// Google Places API Key
  /// Get your API key from: https://console.cloud.google.com/apis/credentials
  /// Make sure to:
  /// 1. Enable Places API in your Google Cloud Console
  /// 2. Set up proper API key restrictions (Android apps, IP addresses, etc.)
  /// 3. Add your app's package name and SHA-1 fingerprint to the restrictions
  /// 4. Enable billing (required for Places API)
  static const String googlePlacesApiKey = 'AIzaSyAeG0moNtz4jQiVS61NYa3mUYik3eaz29A';
  
  /// Other API keys can be added here
  /// static const String otherApiKey = 'YOUR_OTHER_API_KEY';
} 