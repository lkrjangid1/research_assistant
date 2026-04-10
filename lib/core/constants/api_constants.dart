class ApiConstants {
  static const String arxivBaseUrl = 'https://export.arxiv.org/api/query';
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const String chatQuery = '/api/chat/query';
  static const String chatCommand = '/api/chat/command';
  static const String papersProcess = '/api/papers/process';
  static const String papersStatus = '/api/papers/{id}/status';
  static const String summaryGenerate = '/api/summary/generate';
  static const String health = '/health';
}
