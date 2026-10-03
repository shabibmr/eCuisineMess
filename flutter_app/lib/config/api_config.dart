class ApiConfig {
  // Default to local FastAPI / Frappe compatible Python backend
  static String baseUrl = 'http://127.0.0.1:8000';
  
  // Set custom server address
  static void setBaseUrl(String url) {
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
