class ApiConstants {
  static String dbName = 'cards_db4.db';
  //static String baseUrl = 'https://api.ra1g.eu/api/cardhub'; // change it for production
  static String baseUrl = 'http://10.0.2.2:3000/api/cardhub'; // change it for developing 10.0.2.2
  static String loginWithCode = '/enterSystemWithCode';
  static String getCardsWithCode = '/getCards';
  static String getShopsWithCode = '/getShops';
  static String logoutWithCode = '/logOut';
  static String uploadCardWithCode = '/uploadCardWithCode';
  static String deleteCardWithCode = '/removeCardWithCode';
  static String editCardWithCode = '/editCard';
}