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
  'receipt': Icons.receipt_long,
  'smartphone': Icons.smartphone,
  'devices': Icons.devices_other_outlined,
  'wallet': Icons.account_balance_wallet,
};

/// Mengambil [IconData] berdasarkan kunci string [key], atau ikon default jika tidak ditemukan.
IconData iconFor(String key) => categoryIcons[key] ?? Icons.category;

/// Peta aset ikon Miami Sunset Finance untuk kategori dan modul aplikasi.
const Map<String, String> viceCityCategoryAssets = {
  'restaurant': 'assets/icon-compress/153_food_basket-kompres.png',
  'coffee': 'assets/icon-compress/145_coffee_cup-kompres.png',
  'bus': 'assets/icon-compress/129_bus-kompres.png',
  'fuel': 'assets/icon-compress/131_car-kompres.png',
  'flight': 'assets/icon-compress/62_plane-kompres.png',
  'home': 'assets/icons/vice_city/home.png',
  'wifi': 'assets/icon-compress/110_wifi-kompres.png',
  'phone': 'assets/icon-compress/114_smartphone-kompres.png',
  'school': 'assets/icon-compress/093_presentation_board-kompres.png',
  'book': 'assets/icon-compress/39_file_document-kompres.png',
  'shopping': 'assets/icon-compress/46_cart-kompres.png',
  'clothes': 'assets/icon-compress/47_tag-kompres.png',
  'gift': 'assets/icon-compress/149_gift_box-kompres.png',
  'movie': 'assets/icon-compress/151_ticket-kompres.png',
  'game': 'assets/icon-compress/52_headphones-kompres.png',
  'fitness': 'assets/icon-compress/148_fitness_activity-kompres.png',
  'health': 'assets/icon-compress/152_medical_cross-kompres.png',
  'pets': 'assets/icon-compress/64_heart-kompres.png',
  'family': 'assets/icon-compress/106_users_group-kompres.png',
  'award': 'assets/icon-compress/36_award_medal-kompres.png',
  'work': 'assets/icon-compress/076_wallet_cash-kompres.png',
  'payments': 'assets/icon-compress/083_coin_stack-kompres.png',
  'savings': 'assets/icons/vice_city/savings.png',
  'account_balance': 'assets/icon-compress/080_bank_building-kompres.png',
  'account_balance_wallet': 'assets/icons/vice_city/wallet.png',
  'swap_horiz': 'assets/icons/vice_city/transfer.png',
  'more': 'assets/icons/vice_city/diamond.png',
  'receipt': 'assets/icon-compress/28_receipt-kompres.png',
  'smartphone': 'assets/icon-compress/114_smartphone-kompres.png',
  'devices': 'assets/icon-compress/116_laptop-kompres.png',
  'digital': 'assets/icon-compress/067_mobile_banking-kompres.png',
  'bank': 'assets/icon-compress/080_bank_building-kompres.png',
  'ewallet': 'assets/icon-compress/068_contactless_pay-kompres.png',
  'cash': 'assets/icon-compress/59_cash-kompres.png',
  'wallet': 'assets/icons/vice_city/wallet.png',
};

/// Alias kanonikal untuk kompatibilitas mundur
const Map<String, String> glasshouseCategoryAssets = viceCityCategoryAssets;

/// Mengambil path aset ikon Vice City berdasarkan kunci kategori string.
String? viceCityAssetFor(String? key) =>
    key != null ? viceCityCategoryAssets[key] : null;

/// Alias kompatibilitas mundur
String? glasshouseAssetFor(String? key) => viceCityAssetFor(key);

/// Mengambil path aset ikon Vice City berdasarkan [IconData].
String? viceCityAssetForIcon(IconData icon) {
  if (icon == Icons.restaurant || icon == Icons.restaurant_outlined) {
    return 'assets/icon-compress/153_food_basket-kompres.png';
  }
  if (icon == Icons.local_cafe || icon == Icons.local_cafe_outlined) {
    return 'assets/icon-compress/145_coffee_cup-kompres.png';
  }
  if (icon == Icons.directions_bus || icon == Icons.directions_bus_outlined) {
    return 'assets/icon-compress/129_bus-kompres.png';
  }
  if (icon == Icons.local_gas_station || icon == Icons.local_gas_station_outlined) {
    return 'assets/icon-compress/131_car-kompres.png';
  }
  if (icon == Icons.flight || icon == Icons.flight_outlined) {
    return 'assets/icon-compress/62_plane-kompres.png';
  }
  if (icon == Icons.shopping_bag || icon == Icons.shopping_bag_outlined) {
    return 'assets/icon-compress/46_cart-kompres.png';
  }
  if (icon == Icons.checkroom || icon == Icons.checkroom_outlined) {
    return 'assets/icon-compress/47_tag-kompres.png';
  }
  if (icon == Icons.card_giftcard || icon == Icons.card_giftcard_outlined) {
    return 'assets/icon-compress/149_gift_box-kompres.png';
  }
  if (icon == Icons.school || icon == Icons.school_outlined) {
    return 'assets/icon-compress/093_presentation_board-kompres.png';
  }
  if (icon == Icons.menu_book || icon == Icons.menu_book_outlined) {
    return 'assets/icon-compress/39_file_document-kompres.png';
  }
  if (icon == Icons.fitness_center || icon == Icons.fitness_center_outlined) {
    return 'assets/icon-compress/148_fitness_activity-kompres.png';
  }
  if (icon == Icons.medical_services || icon == Icons.medical_services_outlined) {
    return 'assets/icon-compress/152_medical_cross-kompres.png';
  }
  if (icon == Icons.movie || icon == Icons.movie_outlined) {
    return 'assets/icon-compress/151_ticket-kompres.png';
  }
  if (icon == Icons.sports_esports || icon == Icons.sports_esports_outlined) {
    return 'assets/icon-compress/52_headphones-kompres.png';
  }
  if (icon == Icons.wifi || icon == Icons.wifi_outlined) {
    return 'assets/icon-compress/110_wifi-kompres.png';
  }
  if (icon == Icons.smartphone ||
      icon == Icons.smartphone_outlined ||
      icon == Icons.phone_android ||
      icon == Icons.phone_android_outlined) {
    return 'assets/icon-compress/114_smartphone-kompres.png';
  }
  if (icon == Icons.devices ||
      icon == Icons.devices_outlined ||
      icon == Icons.devices_other ||
      icon == Icons.devices_other_outlined) {
    return 'assets/icon-compress/116_laptop-kompres.png';
  }
  if (icon == Icons.work || icon == Icons.work_outlined) {
    return 'assets/icon-compress/076_wallet_cash-kompres.png';
  }
  if (icon == Icons.payments ||
      icon == Icons.payments_outlined ||
      icon == Icons.attach_money ||
      icon == Icons.money) {
    return 'assets/icon-compress/083_coin_stack-kompres.png';
  }
  if (icon == Icons.savings || icon == Icons.savings_outlined) {
    return 'assets/icons/vice_city/savings.png';
  }
  if (icon == Icons.account_balance ||
      icon == Icons.account_balance_outlined ||
      icon == Icons.account_balance_rounded) {
    return 'assets/icon-compress/080_bank_building-kompres.png';
  }
  if (icon == Icons.account_balance_wallet ||
      icon == Icons.account_balance_wallet_outlined ||
      icon == Icons.account_balance_wallet_rounded ||
      icon == Icons.wallet ||
      icon == Icons.wallet_outlined ||
      icon == Icons.wallet_rounded) {
    return 'assets/icons/vice_city/wallet.png';
  }
  if (icon == Icons.swap_horiz ||
      icon == Icons.swap_horiz_rounded ||
      icon == Icons.swap_horizontal_circle ||
      icon == Icons.sync_alt) {
    return 'assets/icons/vice_city/transfer.png';
  }
  if (icon == Icons.home ||
      icon == Icons.home_rounded ||
      icon == Icons.home_outlined ||
      icon == Icons.home_work ||
      icon == Icons.home_work_outlined ||
      icon == Icons.home_work_rounded) {
    return 'assets/icons/vice_city/home.png';
  }
  if (icon == Icons.flag ||
      icon == Icons.flag_outlined ||
      icon == Icons.flag_rounded) {
    return 'assets/icon-compress/077_savings_goal-kompres.png';
  }
  if (icon == Icons.workspace_premium ||
      icon == Icons.workspace_premium_outlined ||
      icon == Icons.family_restroom ||
      icon == Icons.emoji_events ||
      icon == Icons.emoji_events_outlined) {
    return 'assets/icons/vice_city/trophy.png';
  }
  if (icon == Icons.calculate ||
      icon == Icons.calculate_outlined ||
      icon == Icons.pie_chart ||
      icon == Icons.pie_chart_outline ||
      icon == Icons.pie_chart_outline_rounded) {
    return 'assets/icons/vice_city/pie_chart.png';
  }
  if (icon == Icons.receipt ||
      icon == Icons.receipt_long ||
      icon == Icons.receipt_outlined ||
      icon == Icons.receipt_long_outlined ||
      icon == Icons.receipt_long_rounded ||
      icon == Icons.credit_card ||
      icon == Icons.credit_card_outlined ||
      icon == Icons.credit_card_rounded ||
      icon == Icons.ios_share ||
      icon == Icons.ios_share_rounded) {
    return 'assets/icons/vice_city/card.png';
  }
  if (icon == Icons.calendar_month ||
      icon == Icons.calendar_month_outlined ||
      icon == Icons.calendar_month_rounded ||
      icon == Icons.calendar_today ||
      icon == Icons.calendar_today_outlined ||
      icon == Icons.calendar_today_rounded ||
      icon == Icons.date_range ||
      icon == Icons.date_range_outlined ||
      icon == Icons.date_range_rounded) {
    return 'assets/icons/vice_city/calendar.png';
  }
  if (icon == Icons.add ||
      icon == Icons.add_rounded ||
      icon == Icons.add_circle ||
      icon == Icons.add_circle_outline ||
      icon == Icons.add_circle_rounded) {
    return 'assets/icons/vice_city/add.png';
  }
  if (icon == Icons.remove ||
      icon == Icons.remove_rounded ||
      icon == Icons.remove_circle ||
      icon == Icons.remove_circle_outline ||
      icon == Icons.arrow_upward ||
      icon == Icons.arrow_upward_rounded ||
      icon == Icons.arrow_upward_outlined) {
    return 'assets/icons/vice_city/minus.png';
  }
  if (icon == Icons.history || icon == Icons.history_rounded) {
    return 'assets/icons/vice_city/calendar.png';
  }
  if (icon == Icons.settings ||
      icon == Icons.settings_outlined ||
      icon == Icons.settings_rounded ||
      icon == Icons.edit ||
      icon == Icons.edit_outlined ||
      icon == Icons.edit_rounded) {
    return 'assets/icons/vice_city/settings.png';
  }
  if (icon == Icons.search ||
      icon == Icons.search_rounded ||
      icon == Icons.search_outlined) {
    return 'assets/icons/vice_city/search.png';
  }
  if (icon == Icons.filter_list ||
      icon == Icons.filter_list_rounded ||
      icon == Icons.filter_alt ||
      icon == Icons.filter_alt_outlined ||
      icon == Icons.filter_alt_rounded ||
      icon == Icons.tune ||
      icon == Icons.tune_rounded ||
      icon == Icons.tune_outlined) {
    return 'assets/icons/vice_city/filter.png';
  }
  if (icon == Icons.lock ||
      icon == Icons.lock_outline ||
      icon == Icons.lock_outline_rounded) {
    return 'assets/icon-compress/56_lock-kompres.png';
  }
  if (icon == Icons.security ||
      icon == Icons.shield_outlined ||
      icon == Icons.shield_rounded) {
    return 'assets/icon-compress/34_security_shield-kompres.png';
  }
  if (icon == Icons.fingerprint ||
      icon == Icons.fingerprint_rounded) {
    return 'assets/icon-compress/107_fingerprint-kompres.png';
  }
  if (icon == Icons.notifications ||
      icon == Icons.notifications_outlined ||
      icon == Icons.notifications_rounded ||
      icon == Icons.notifications_active ||
      icon == Icons.notifications_active_outlined) {
    return 'assets/icons/vice_city/notifications.png';
  }
  if (icon == Icons.schedule || icon == Icons.schedule_rounded) {
    return 'assets/icon-compress/098_alarm_clock-kompres.png';
  }
  if (icon == Icons.file_upload ||
      icon == Icons.file_upload_outlined ||
      icon == Icons.cloud_upload ||
      icon == Icons.cloud_upload_outlined) {
    return 'assets/icon-compress/41_cloud_upload-kompres.png';
  }
  if (icon == Icons.file_download ||
      icon == Icons.file_download_outlined ||
      icon == Icons.cloud_download ||
      icon == Icons.cloud_download_outlined) {
    return 'assets/icon-compress/42_cloud_download-kompres.png';
  }
  if (icon == Icons.cloud_sync ||
      icon == Icons.sync ||
      icon == Icons.sync_rounded) {
    return 'assets/icon-compress/155_cloud_sync-kompres.png';
  }
  if (icon == Icons.info_outline ||
      icon == Icons.info_outline_rounded ||
      icon == Icons.help_outline) {
    return 'assets/icons/vice_city/diamond.png';
  }
  if (icon == Icons.history_edu ||
      icon == Icons.history_edu_rounded) {
    return 'assets/icon-compress/39_file_document-kompres.png';
  }
  if (icon == Icons.table_view ||
      icon == Icons.table_view_outlined) {
    return 'assets/icon-compress/38_analytics_bars-kompres.png';
  }
  if (icon == Icons.feedback_outlined ||
      icon == Icons.chat_outlined) {
    return 'assets/icon-compress/50_chat-kompres.png';
  }
  if (icon == Icons.delete_outline ||
      icon == Icons.delete_forever_outlined ||
      icon == Icons.person_remove_outlined) {
    return 'assets/icon-compress/121_trash-kompres.png';
  }
  if (icon == Icons.person ||
      icon == Icons.person_outline ||
      icon == Icons.account_circle) {
    return 'assets/icon-compress/26_profile_avatar-kompres.png';
  }
  if (icon == Icons.groups ||
      icon == Icons.groups_outlined ||
      icon == Icons.handshake_outlined) {
    return 'assets/icon-compress/106_users_group-kompres.png';
  }
  if (icon == Icons.event_repeat ||
      icon == Icons.event_repeat_rounded ||
      icon == Icons.redo ||
      icon == Icons.redo_rounded) {
    return 'assets/icons/vice_city/recurring.png';
  }
  if (icon == Icons.picture_as_pdf ||
      icon == Icons.picture_as_pdf_outlined) {
    return 'assets/icon-compress/39_file_document-kompres.png';
  }
  if (icon == Icons.alarm ||
      icon == Icons.alarm_rounded ||
      icon == Icons.alarm_outlined) {
    return 'assets/icon-compress/098_alarm_clock-kompres.png';
  }
  if (icon == Icons.auto_stories ||
      icon == Icons.auto_stories_outlined ||
      icon == Icons.auto_stories_rounded) {
    return 'assets/icon-compress/094_pie_analytics-kompres.png';
  }
  if (icon == Icons.auto_awesome ||
      icon == Icons.auto_awesome_outlined ||
      icon == Icons.auto_awesome_rounded) {
    return 'assets/icon-compress/65_star-kompres.png';
  }
  if (icon == Icons.forest || icon == Icons.forest_outlined) {
    return 'assets/icon-compress/141_palm_tree-kompres.png';
  }
  if (icon == Icons.offline_bolt ||
      icon == Icons.offline_bolt_outlined ||
      icon == Icons.bolt_rounded) {
    return 'assets/icon-compress/156_database-kompres.png';
  }
  if (icon == Icons.cloud_done ||
      icon == Icons.cloud_done_outlined ||
      icon == Icons.cloud_off ||
      icon == Icons.cloud_off_outlined) {
    return 'assets/icon-compress/155_cloud_sync-kompres.png';
  }
  if (icon == Icons.warning_amber_rounded || icon == Icons.warning_rounded) {
    return 'assets/icon-compress/102_message_alert-kompres.png';
  }
  if (icon == Icons.trending_down || icon == Icons.trending_down_rounded) {
    return 'assets/icons/vice_city/minus.png';
  }
  if (icon == Icons.favorite_border || icon == Icons.favorite) {
    return 'assets/icon-compress/64_heart-kompres.png';
  }
  if (icon == Icons.check_circle_outline) {
    return 'assets/icon-compress/096_calendar_check-kompres.png';
  }
  if (icon == Icons.trending_up ||
      icon == Icons.trending_up_rounded ||
      icon == Icons.show_chart ||
      icon == Icons.arrow_downward ||
      icon == Icons.arrow_downward_rounded ||
      icon == Icons.arrow_downward_outlined) {
    return 'assets/icons/vice_city/growth.png';
  }
  if (icon == Icons.more_horiz ||
      icon == Icons.category ||
      icon == Icons.category_outlined ||
      icon == Icons.grid_view ||
      icon == Icons.grid_view_rounded ||
      icon == Icons.grid_view_outlined ||
      icon == Icons.apps ||
      icon == Icons.widgets) {
    return 'assets/icons/vice_city/diamond.png';
  }
  if (icon == Icons.speed ||
      icon == Icons.stacked_line_chart) {
    return 'assets/icons/vice_city/pulse.png';
  }
  if (icon == Icons.track_changes ||
      icon == Icons.track_changes_rounded ||
      icon == Icons.gps_fixed ||
      icon == Icons.crisis_alert) {
    return 'assets/icons/vice_city/goals.png';
  }
  if (icon == Icons.location_on ||
      icon == Icons.location_on_outlined ||
      icon == Icons.place ||
      icon == Icons.place_outlined ||
      icon == Icons.pin_drop) {
    return 'assets/icons/vice_city/location.png';
  }
  if (icon == Icons.eco ||
      icon == Icons.eco_outlined ||
      icon == Icons.park) {
    return 'assets/icons/vice_city/investment.png';
  }
  if (icon == Icons.sync ||
      icon == Icons.refresh ||
      icon == Icons.autorenew) {
    return 'assets/icons/vice_city/recurring.png';
  }
  if (icon == Icons.logout ||
      icon == Icons.exit_to_app ||
      icon == Icons.exit_to_app_rounded) {
    return 'assets/icons/vice_city/logout.png';
  }
  if (icon == Icons.local_activity ||
      icon == Icons.local_activity_outlined ||
      icon == Icons.local_activity_rounded) {
    return 'assets/icons/vice_city/gift.png';
  }
  return null;
}

/// Alias kompatibilitas mundur
String? glasshouseAssetForIcon(IconData icon) => viceCityAssetForIcon(icon);

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
