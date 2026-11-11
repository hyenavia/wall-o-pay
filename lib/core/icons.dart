/// Peta ikon dan daftar warna standar untuk kategori pemasukan/pengeluaran.
/// Disimpan sebagai kunci string dan nilai integer warna agar mudah disimpan di SQLite & Firestore.
library;

import 'package:flutter/material.dart';

/// Ikon kategori disimpan sebagai kunci teks di database.
const Map<String, IconData> categoryIcons = {
  'restaurant': Icons.restaurant,
  'coffee': Icons.local_cafe,
  'bus': Icons.directions_bus,
  'fuel': Icons.local_gas_station,
  'home': Icons.home,
  'wifi': Icons.wifi,
  'phone': Icons.smartphone,
  'school': Icons.school,
  'book': Icons.menu_book,
  'shopping': Icons.shopping_bag,
  'clothes': Icons.checkroom,
  'movie': Icons.movie,
  'game': Icons.sports_esports,
  'fitness': Icons.fitness_center,
  'health': Icons.medical_services,
  'pets': Icons.pets,
  'gift': Icons.card_giftcard,
  'flight': Icons.flight,
  'family': Icons.family_restroom,
  'award': Icons.workspace_premium,
  'work': Icons.work,
  'payments': Icons.payments,
  'savings': Icons.savings,
  'account_balance': Icons.account_balance,
  'account_balance_wallet': Icons.account_balance_wallet,
  'swap_horiz': Icons.swap_horiz,
  'more': Icons.more_horiz,
  'smartphone': Icons.smartphone,
  'devices': Icons.devices_other_outlined,
  'wallet': Icons.account_balance_wallet,
};

/// Mengambil [IconData] berdasarkan kunci string [key], atau ikon default jika tidak ditemukan.
IconData iconFor(String key) => categoryIcons[key] ?? Icons.category;

/// Peta aset ikon 3D Enchanted Glasshouse untuk kategori dan modul aplikasi.
const Map<String, String> glasshouseCategoryAssets = {
  'restaurant': 'assets/icons/glasshouse/food.png',
  'coffee': 'assets/icons/glasshouse/food.png',
  'bus': 'assets/icons/glasshouse/transport.png',
  'fuel': 'assets/icons/glasshouse/transport.png',
  'flight': 'assets/icons/glasshouse/transport.png',
  'home': 'assets/icons/glasshouse/home.png',
  'wifi': 'assets/icons/glasshouse/bills.png',
  'phone': 'assets/icons/glasshouse/bills.png',
  'school': 'assets/icons/glasshouse/education.png',
  'book': 'assets/icons/glasshouse/education.png',
  'shopping': 'assets/icons/glasshouse/shopping.png',
  'clothes': 'assets/icons/glasshouse/shopping.png',
  'gift': 'assets/icons/glasshouse/shopping.png',
  'movie': 'assets/icons/glasshouse/entertainment.png',
  'game': 'assets/icons/glasshouse/entertainment.png',
  'fitness': 'assets/icons/glasshouse/health.png',
  'health': 'assets/icons/glasshouse/health.png',
  'pets': 'assets/icons/glasshouse/other.png',
  'family': 'assets/icons/glasshouse/goals.png',
  'award': 'assets/icons/glasshouse/goals.png',
  'work': 'assets/icons/glasshouse/salary.png',
  'payments': 'assets/icons/glasshouse/salary.png',
  'savings': 'assets/icons/glasshouse/savings.png',
  'account_balance': 'assets/icons/glasshouse/savings.png',
  'account_balance_wallet': 'assets/icons/glasshouse/wallet.png',
  'swap_horiz': 'assets/icons/glasshouse/wallet.png',
  'more': 'assets/icons/glasshouse/other.png',
  'smartphone': 'assets/icons/glasshouse/bills.png',
  'devices': 'assets/icons/glasshouse/bills.png',
  'digital': 'assets/icons/glasshouse/bills.png',
  'bank': 'assets/icons/glasshouse/savings.png',
  'ewallet': 'assets/icons/glasshouse/wallet.png',
  'cash': 'assets/icons/glasshouse/salary.png',
  'wallet': 'assets/icons/glasshouse/wallet.png',
};

/// Mengambil path aset ikon 3D Glasshouse berdasarkan kunci kategori string.
String? glasshouseAssetFor(String? key) =>
    key != null ? glasshouseCategoryAssets[key] : null;

/// Mengambil path aset ikon 3D Glasshouse berdasarkan [IconData].
String? glasshouseAssetForIcon(IconData icon) {
  if (icon == Icons.restaurant ||
      icon == Icons.restaurant_outlined ||
      icon == Icons.local_cafe ||
      icon == Icons.local_cafe_outlined) {
    return 'assets/icons/glasshouse/food.png';
  }
  if (icon == Icons.directions_bus ||
      icon == Icons.directions_bus_outlined ||
      icon == Icons.local_gas_station ||
      icon == Icons.local_gas_station_outlined ||
      icon == Icons.flight ||
      icon == Icons.flight_outlined) {
    return 'assets/icons/glasshouse/transport.png';
  }
  if (icon == Icons.shopping_bag ||
      icon == Icons.shopping_bag_outlined ||
      icon == Icons.checkroom ||
      icon == Icons.checkroom_outlined ||
      icon == Icons.card_giftcard ||
      icon == Icons.card_giftcard_outlined) {
    return 'assets/icons/glasshouse/shopping.png';
  }
  if (icon == Icons.school ||
      icon == Icons.school_outlined ||
      icon == Icons.menu_book ||
      icon == Icons.menu_book_outlined) {
    return 'assets/icons/glasshouse/education.png';
  }
  if (icon == Icons.fitness_center ||
      icon == Icons.fitness_center_outlined ||
      icon == Icons.medical_services ||
      icon == Icons.medical_services_outlined) {
    return 'assets/icons/glasshouse/health.png';
  }
  if (icon == Icons.movie ||
      icon == Icons.movie_outlined ||
      icon == Icons.sports_esports ||
      icon == Icons.sports_esports_outlined) {
    return 'assets/icons/glasshouse/entertainment.png';
  }
  if (icon == Icons.wifi ||
      icon == Icons.wifi_outlined ||
      icon == Icons.smartphone ||
      icon == Icons.smartphone_outlined ||
      icon == Icons.devices ||
      icon == Icons.devices_outlined ||
      icon == Icons.devices_other ||
      icon == Icons.devices_other_outlined ||
      icon == Icons.phone_android ||
      icon == Icons.phone_android_outlined) {
    return 'assets/icons/glasshouse/bills.png';
  }
  if (icon == Icons.work ||
      icon == Icons.work_outlined ||
      icon == Icons.payments ||
      icon == Icons.payments_outlined ||
      icon == Icons.attach_money ||
      icon == Icons.money) {
    return 'assets/icons/glasshouse/salary.png';
  }
  if (icon == Icons.savings ||
      icon == Icons.savings_outlined ||
      icon == Icons.account_balance ||
      icon == Icons.account_balance_outlined) {
    return 'assets/icons/glasshouse/savings.png';
  }
  if (icon == Icons.account_balance_wallet ||
      icon == Icons.account_balance_wallet_outlined ||
      icon == Icons.wallet ||
      icon == Icons.wallet_outlined) {
    return 'assets/icons/glasshouse/wallet.png';
  }
  if (icon == Icons.swap_horiz || icon == Icons.swap_horiz_rounded) {
    return 'assets/icons/glasshouse/wallet.png';
  }
  if (icon == Icons.home ||
      icon == Icons.home_rounded ||
      icon == Icons.home_outlined) {
    return 'assets/icons/glasshouse/home.png';
  }
  if (icon == Icons.flag ||
      icon == Icons.flag_outlined ||
      icon == Icons.workspace_premium ||
      icon == Icons.family_restroom) {
    return 'assets/icons/glasshouse/goals.png';
  }
  if (icon == Icons.calculate ||
      icon == Icons.calculate_outlined) {
    return 'assets/icons/glasshouse/calculator.png';
  }
  if (icon == Icons.receipt ||
      icon == Icons.receipt_long ||
      icon == Icons.receipt_outlined ||
      icon == Icons.receipt_long_outlined) {
    return 'assets/icons/glasshouse/receipt.png';
  }
  if (icon == Icons.calendar_month ||
      icon == Icons.calendar_today ||
      icon == Icons.calendar_today_outlined ||
      icon == Icons.date_range) {
    return 'assets/icons/glasshouse/calendar.png';
  }
  if (icon == Icons.add ||
      icon == Icons.add_circle ||
      icon == Icons.add_circle_outline) {
    return 'assets/icons/glasshouse/add.png';
  }
  if (icon == Icons.history || icon == Icons.history_rounded) {
    return 'assets/icons/glasshouse/history.png';
  }
  if (icon == Icons.settings || icon == Icons.settings_outlined) {
    return 'assets/icons/glasshouse/settings.png';
  }
  if (icon == Icons.search || icon == Icons.search_rounded) {
    return 'assets/icons/glasshouse/search.png';
  }
  if (icon == Icons.lock ||
      icon == Icons.lock_outline ||
      icon == Icons.security) {
    return 'assets/icons/glasshouse/security.png';
  }
  if (icon == Icons.notifications ||
      icon == Icons.notifications_outlined) {
    return 'assets/icons/glasshouse/notifications.png';
  }
  if (icon == Icons.person ||
      icon == Icons.person_outline ||
      icon == Icons.account_circle) {
    return 'assets/icons/glasshouse/profile.png';
  }
  if (icon == Icons.trending_up ||
      icon == Icons.show_chart) {
    return 'assets/icons/glasshouse/investment.png';
  }
  if (icon == Icons.more_horiz ||
      icon == Icons.category ||
      icon == Icons.category_outlined) {
    return 'assets/icons/glasshouse/other.png';
  }
  return null;
}

/// Pilihan warna untuk kategori.
const List<int> categoryColors = [
  0xFFEF6C00,
  0xFF1E88E5,
  0xFF6D4C41,
  0xFF5E35B1,
  0xFFD81B60,
  0xFF8E24AA,
  0xFFE53935,
  0xFF607D8B,
  0xFF2E7D32,
  0xFF00897B,
  0xFF558B2F,
  0xFFF9A825,
];
