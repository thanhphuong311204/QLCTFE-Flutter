class ApiConstants {
  static const String baseUrl = "http://192.168.1.107:8080";


  static const String register = "$baseUrl/api/auth/register";
  static const String login = "$baseUrl/api/auth/login";
  static const String categories = "$baseUrl/api/categories";

  static const String expenses = "$baseUrl/api/expenses";
  static const String incomes = "$baseUrl/api/incomes";

  static const String addExpense = "$baseUrl/api/expenses";
  static const String addIncome = "$baseUrl/api/incomes";

  static const String addTransaction = "$baseUrl/api/recurring";
  static const String getTransactions = "$baseUrl/api/recurring";
  
  static const String wallets = "$baseUrl/api/wallets"; 

  static const String goals = "$baseUrl/api/goals";

  static const String budgets = "$baseUrl/api/budgets";

  static const String reports = "$baseUrl/api/reports";

  static const String recurring = "$baseUrl/api/recurring";

  static const String notifications = "$baseUrl/api/notifications";
  
  static const String settings = "$baseUrl/api/settings";

  static const String getCurrentUser = "$baseUrl/api/users/me";

  static const String users = "$baseUrl/api/users";

  static const String aiSuggest = "$baseUrl/api/ai/suggest-category";


}
