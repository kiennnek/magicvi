class ApiConstants {
  // Gemini API Configuration
  static const String geminiApiKey = 'AIzaSyC8qwaTDj-JHB_Xs48SeStAJucOUke3jWA';
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String geminiModel = 'gemini-2.0-flash';
  
  // API Endpoints
  static String get generateContentUrl => 
      '$geminiBaseUrl/models/$geminiModel:generateContent?key=$geminiApiKey';
  
  static String get streamGenerateContentUrl => 
      '$geminiBaseUrl/models/$geminiModel:streamGenerateContent?key=$geminiApiKey';
  
  // Request Configuration
  static const int requestTimeout = 30; // seconds
  static const int maxRetries = 3;
  static const int retryDelay = 2; // seconds
  
  // Content Safety Settings
  static const Map<String, String> safetySettings = {
    'HARM_CATEGORY_HARASSMENT': 'BLOCK_MEDIUM_AND_ABOVE',
    'HARM_CATEGORY_HATE_SPEECH': 'BLOCK_MEDIUM_AND_ABOVE',
    'HARM_CATEGORY_SEXUALLY_EXPLICIT': 'BLOCK_MEDIUM_AND_ABOVE',
    'HARM_CATEGORY_DANGEROUS_CONTENT': 'BLOCK_MEDIUM_AND_ABOVE',
  };
  
  // Generation Configuration
  static const Map<String, dynamic> generationConfig = {
    'temperature': 0.7,
    'topK': 40,
    'topP': 0.95,
    'maxOutputTokens': 2048,
  };
}

