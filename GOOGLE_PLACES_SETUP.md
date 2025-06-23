# Google Places API Setup Guide

## Overview
The Besinova app uses Google Places API to find nearby markets and grocery stores. This guide will help you set up the API key properly.

## Step 1: Get Google Places API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Places API**:
   - Go to "APIs & Services" > "Library"
   - Search for "Places API"
   - Click on it and press "Enable"

## Step 2: Create API Key

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key

## Step 3: Configure API Key Restrictions (Recommended)

For security, restrict your API key:

1. Click on the API key you just created
2. Under "Application restrictions", select "Android apps"
3. Add your app's details:
   - **Package name**: `com.example.besinova`
   - **SHA-1 certificate fingerprint**: Get this from your development environment

### Getting SHA-1 Fingerprint

#### For Debug Build:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

#### For Release Build:
```bash
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

4. Under "API restrictions", select "Restrict key"
5. Select "Places API" from the list
6. Click "Save"

## Step 4: Add API Key to App

1. Open `lib/core/constants/api_keys.dart`
2. Replace `'YOUR_GOOGLE_PLACES_API_KEY'` with your actual API key:

```dart
static const String googlePlacesApiKey = 'AIzaSyYourActualApiKeyHere';
```

## Step 5: Test the Integration

1. Build and run the app
2. Go to the Nutrition screen
3. Click on a product's location icon
4. The app should now find nearby markets

## Troubleshooting

### "REQUEST_DENIED" Error
- Check if the API key is correct
- Verify that Places API is enabled
- Ensure API key restrictions are properly configured
- Check if billing is enabled (required for Places API)

### "OVER_QUERY_LIMIT" Error
- You've exceeded the free quota (1000 requests/day)
- Consider upgrading to a paid plan

### "INVALID_REQUEST" Error
- Check the API request format
- Verify coordinates are valid

### "ZERO_RESULTS" Error
- No markets found in the specified radius
- Try increasing the search radius

## API Usage Limits

- **Free tier**: 1000 requests/day
- **Paid tier**: $17 per 1000 requests after free quota

## Security Best Practices

1. **Always restrict your API key** to your app's package name and SHA-1
2. **Never commit API keys to public repositories**
3. **Use environment variables** for production builds
4. **Monitor API usage** in Google Cloud Console
5. **Set up billing alerts** to avoid unexpected charges

## Alternative Setup (Environment Variables)

For better security, you can use environment variables:

1. Create a `.env` file in your project root:
```
GOOGLE_PLACES_API_KEY=your_actual_api_key_here
```

2. Add `.env` to your `.gitignore` file

3. Use a package like `flutter_dotenv` to load the key:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

static const String _apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
```

## Support

If you encounter issues:
1. Check the Google Cloud Console for error details
2. Verify your API key configuration
3. Test the API directly using curl or Postman
4. Check the [Google Places API documentation](https://developers.google.com/maps/documentation/places/web-service/overview) 