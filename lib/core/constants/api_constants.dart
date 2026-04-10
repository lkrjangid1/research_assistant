class ApiConstants {
  static const String arxivBaseUrl = 'https://export.arxiv.org/api/query';
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://research-assistant-9p0m.onrender.com',
  );
  static const String chatQuery = '/api/chat/query';
  static const String chatCommand = '/api/chat/command';
  static const String papersProcess = '/api/papers/process';
  static const String papersStatus = '/api/papers/{id}/status';
  static const String summaryGenerate = '/api/summary/generate';
  static const String health = '/health';
}
