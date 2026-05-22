class ApiConstants {
  const ApiConstants._();

  static const String webBaseUrl = 'https://wtr-lab.com';
  static const String apiProxyBaseUrl = 'https://cors-bypasser-pro.vercel.app/proxy?url=https://wtr-lab.com';

  // WTR API request paths used by the app screens.
  static const String serieRanking = '/api/serie/ranking';
  static const String search = '/api/search';
  static const String novelDetails = '/api/novel/details';
  static const String chapterList = '/api/novel/chapters';
  static const String readerGet = '/api/reader/get';
}
