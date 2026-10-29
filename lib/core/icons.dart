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
};

IconData iconFor(String key) => categoryIcons[key] ?? Icons.category;

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
