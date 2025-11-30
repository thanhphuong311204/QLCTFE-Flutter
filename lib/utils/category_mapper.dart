import '../models/category_model.dart';

class CategoryMapper {
  static CategoryModel mapAIResult({
    required String aiText,
    required List<CategoryModel> categories,
  }) {
    aiText = aiText.toLowerCase();

    // 1. Chuẩn hóa nhóm AI → Category của DB
    final mapping = {
      "di chuyển": "Đi lại / Taxi",
      "đi lại": "Đi lại / Taxi",
      "taxi": "Đi lại / Taxi",

      "mua sắm": "Mua sắm quần áo",
      "shopping": "Mua sắm quần áo",

      "ăn uống": "Ăn uống",

      "giải trí": "Giải trí",

      "giáo dục": "Giáo dục",

      "y tế": "Y tế / Sức khỏe",
      "sức khỏe": "Y tế / Sức khỏe",

      "hóa đơn": "Phí dịch vụ / Chung cư",
      "nhà cửa": "Nhà ở",

      "gia đình": "Gia đình / Con cái",
      "con cái": "Gia đình / Con cái",

      "nhiên liệu": "Nhiên liệu / Xăng",
      "xăng": "Nhiên liệu / Xăng",
    };

    // 2. Nếu AI trả ra nhóm nằm trong mapping → dùng tên category tương ứng
    for (var key in mapping.keys) {
      if (aiText.contains(key)) {
        final targetName = mapping[key]!.toLowerCase();

        return categories.firstWhere(
          (c) => c.categoryName.toLowerCase() == targetName,
          orElse: () =>
              categories.firstWhere((c) => c.categoryName.toLowerCase() == "khác"),
        );
      }
    }

    // 3. Nếu AI trả ra đúng tên category luôn
    return categories.firstWhere(
      (c) => c.categoryName.toLowerCase() == aiText,
      orElse: () =>
          categories.firstWhere((c) => c.categoryName.toLowerCase() == "khác"),
    );
  }
}
