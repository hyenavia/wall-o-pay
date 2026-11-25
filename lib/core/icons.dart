/// Peta ikon dan daftar warna standar untuk kategori pemasukan/pengeluaran.
/// Disimpan sebagai kunci string dan nilai integer warna agar mudah disimpan di SQLite & Firestore.
library;

import 'package:flutter/material.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

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

/// Peta ikon Phosphor Duotone untuk kategori dan modul aplikasi.
const Map<String, PhosphorDuotoneIconData> phosphorCategoryIcons = {
  'restaurant': PhosphorIconsDuotone.forkKnife,
  'coffee': PhosphorIconsDuotone.coffee,
  'bus': PhosphorIconsDuotone.bus,
  'fuel': PhosphorIconsDuotone.gasPump,
  'flight': PhosphorIconsDuotone.airplaneTilt,
  'home': PhosphorIconsDuotone.house,
  'wifi': PhosphorIconsDuotone.wifiHigh,
  'phone': PhosphorIconsDuotone.deviceMobile,
  'school': PhosphorIconsDuotone.graduationCap,
  'book': PhosphorIconsDuotone.bookOpen,
  'shopping': PhosphorIconsDuotone.shoppingBag,
  'clothes': PhosphorIconsDuotone.tShirt,
  'gift': PhosphorIconsDuotone.gift,
  'movie': PhosphorIconsDuotone.filmSlate,
  'game': PhosphorIconsDuotone.gameController,
  'fitness': PhosphorIconsDuotone.barbell,
  'health': PhosphorIconsDuotone.firstAidKit,
  'pets': PhosphorIconsDuotone.pawPrint,
  'family': PhosphorIconsDuotone.usersThree,
  'award': PhosphorIconsDuotone.medal,
  'work': PhosphorIconsDuotone.briefcase,
  'payments': PhosphorIconsDuotone.coins,
  'savings': PhosphorIconsDuotone.piggyBank,
  'account_balance': PhosphorIconsDuotone.bank,
  'account_balance_wallet': PhosphorIconsDuotone.wallet,
  'swap_horiz': PhosphorIconsDuotone.arrowsLeftRight,
  'more': PhosphorIconsDuotone.squaresFour,
  'receipt': PhosphorIconsDuotone.receipt,
  'smartphone': PhosphorIconsDuotone.deviceMobile,
  'devices': PhosphorIconsDuotone.laptop,
  'digital': PhosphorIconsDuotone.deviceMobile,
  'bank': PhosphorIconsDuotone.bank,
  'ewallet': PhosphorIconsDuotone.creditCard,
  'cash': PhosphorIconsDuotone.money,
  'wallet': PhosphorIconsDuotone.wallet,
};

/// Mengambil [PhosphorDuotoneIconData] berdasarkan kunci kategori string.
PhosphorDuotoneIconData? phosphorForKey(String? key) =>
    key != null ? phosphorCategoryIcons[key] : null;

/// Mengambil [PhosphorDuotoneIconData] berdasarkan [IconData].
PhosphorDuotoneIconData? phosphorForIcon(IconData icon) {
  if (icon == Icons.restaurant || icon == Icons.restaurant_outlined) {
    return PhosphorIconsDuotone.forkKnife;
  }
  if (icon == Icons.local_cafe || icon == Icons.local_cafe_outlined) {
    return PhosphorIconsDuotone.coffee;
  }
  if (icon == Icons.directions_bus || icon == Icons.directions_bus_outlined) {
    return PhosphorIconsDuotone.bus;
  }
  if (icon == Icons.local_gas_station || icon == Icons.local_gas_station_outlined) {
    return PhosphorIconsDuotone.gasPump;
  }
  if (icon == Icons.flight || icon == Icons.flight_outlined) {
    return PhosphorIconsDuotone.airplaneTilt;
  }
  if (icon == Icons.shopping_bag || icon == Icons.shopping_bag_outlined) {
    return PhosphorIconsDuotone.shoppingBag;
  }
  if (icon == Icons.checkroom || icon == Icons.checkroom_outlined) {
    return PhosphorIconsDuotone.tShirt;
  }
  if (icon == Icons.card_giftcard || icon == Icons.card_giftcard_outlined) {
    return PhosphorIconsDuotone.gift;
  }
  if (icon == Icons.school || icon == Icons.school_outlined) {
    return PhosphorIconsDuotone.graduationCap;
  }
  if (icon == Icons.menu_book || icon == Icons.menu_book_outlined) {
    return PhosphorIconsDuotone.bookOpen;
  }
  if (icon == Icons.fitness_center || icon == Icons.fitness_center_outlined) {
    return PhosphorIconsDuotone.barbell;
  }
  if (icon == Icons.medical_services || icon == Icons.medical_services_outlined) {
    return PhosphorIconsDuotone.firstAidKit;
  }
  if (icon == Icons.movie || icon == Icons.movie_outlined) {
    return PhosphorIconsDuotone.filmSlate;
  }
  if (icon == Icons.sports_esports || icon == Icons.sports_esports_outlined) {
    return PhosphorIconsDuotone.gameController;
  }
  if (icon == Icons.pets || icon == Icons.pets_outlined) {
    return PhosphorIconsDuotone.pawPrint;
  }
  if (icon == Icons.wifi || icon == Icons.wifi_outlined) {
    return PhosphorIconsDuotone.wifiHigh;
  }
  if (icon == Icons.smartphone ||
      icon == Icons.smartphone_outlined ||
      icon == Icons.phone_android ||
      icon == Icons.phone_android_outlined) {
    return PhosphorIconsDuotone.deviceMobile;
  }
  if (icon == Icons.devices ||
      icon == Icons.devices_outlined ||
      icon == Icons.devices_other ||
      icon == Icons.devices_other_outlined) {
    return PhosphorIconsDuotone.laptop;
  }
  if (icon == Icons.work || icon == Icons.work_outlined) {
    return PhosphorIconsDuotone.briefcase;
  }
  if (icon == Icons.payments ||
      icon == Icons.payments_outlined ||
      icon == Icons.attach_money ||
      icon == Icons.money) {
    return PhosphorIconsDuotone.coins;
  }
  if (icon == Icons.savings || icon == Icons.savings_outlined) {
    return PhosphorIconsDuotone.piggyBank;
  }
  if (icon == Icons.account_balance ||
      icon == Icons.account_balance_outlined ||
      icon == Icons.account_balance_rounded) {
    return PhosphorIconsDuotone.bank;
  }
  if (icon == Icons.account_balance_wallet ||
      icon == Icons.account_balance_wallet_outlined ||
      icon == Icons.account_balance_wallet_rounded ||
      icon == Icons.wallet ||
      icon == Icons.wallet_outlined ||
      icon == Icons.wallet_rounded) {
    return PhosphorIconsDuotone.wallet;
  }
  if (icon == Icons.swap_horiz ||
      icon == Icons.swap_horiz_rounded ||
      icon == Icons.swap_horizontal_circle ||
      icon == Icons.sync_alt) {
    return PhosphorIconsDuotone.arrowsLeftRight;
  }
  if (icon == Icons.home ||
      icon == Icons.home_rounded ||
      icon == Icons.home_outlined ||
      icon == Icons.home_work ||
      icon == Icons.home_work_outlined ||
      icon == Icons.home_work_rounded) {
    return PhosphorIconsDuotone.house;
  }
  if (icon == Icons.flag ||
      icon == Icons.flag_outlined ||
      icon == Icons.flag_rounded) {
    return PhosphorIconsDuotone.target;
  }
  if (icon == Icons.workspace_premium ||
      icon == Icons.workspace_premium_outlined ||
      icon == Icons.family_restroom ||
      icon == Icons.emoji_events ||
      icon == Icons.emoji_events_outlined) {
    return PhosphorIconsDuotone.trophy;
  }
  if (icon == Icons.calculate || icon == Icons.calculate_outlined) {
    return PhosphorIconsDuotone.calculator;
  }
  if (icon == Icons.pie_chart ||
      icon == Icons.pie_chart_outline ||
      icon == Icons.pie_chart_outline_rounded) {
    return PhosphorIconsDuotone.chartPieSlice;
  }
  if (icon == Icons.receipt ||
      icon == Icons.receipt_long ||
      icon == Icons.receipt_outlined ||
      icon == Icons.receipt_long_outlined ||
      icon == Icons.receipt_long_rounded) {
    return PhosphorIconsDuotone.receipt;
  }
  if (icon == Icons.credit_card ||
      icon == Icons.credit_card_outlined ||
      icon == Icons.credit_card_rounded ||
      icon == Icons.ios_share ||
      icon == Icons.ios_share_rounded) {
    return PhosphorIconsDuotone.creditCard;
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
    return PhosphorIconsDuotone.calendarBlank;
  }
  if (icon == Icons.add ||
      icon == Icons.add_rounded ||
      icon == Icons.add_circle ||
      icon == Icons.add_circle_outline ||
      icon == Icons.add_circle_rounded) {
    return PhosphorIconsDuotone.plusCircle;
  }
  if (icon == Icons.remove ||
      icon == Icons.remove_rounded ||
      icon == Icons.remove_circle ||
      icon == Icons.remove_circle_outline ||
      icon == Icons.arrow_upward ||
      icon == Icons.arrow_upward_rounded ||
      icon == Icons.arrow_upward_outlined) {
    return PhosphorIconsDuotone.minusCircle;
  }
  if (icon == Icons.history || icon == Icons.history_rounded) {
    return PhosphorIconsDuotone.clockCounterClockwise;
  }
  if (icon == Icons.settings ||
      icon == Icons.settings_outlined ||
      icon == Icons.settings_rounded) {
    return PhosphorIconsDuotone.gearSix;
  }
  if (icon == Icons.edit ||
      icon == Icons.edit_outlined ||
      icon == Icons.edit_rounded) {
    return PhosphorIconsDuotone.pencilSimple;
  }
  if (icon == Icons.search ||
      icon == Icons.search_rounded ||
      icon == Icons.search_outlined) {
    return PhosphorIconsDuotone.magnifyingGlass;
  }
  if (icon == Icons.filter_list ||
      icon == Icons.filter_list_rounded ||
      icon == Icons.filter_alt ||
      icon == Icons.filter_alt_outlined ||
      icon == Icons.filter_alt_rounded ||
      icon == Icons.tune ||
      icon == Icons.tune_rounded ||
      icon == Icons.tune_outlined) {
    return PhosphorIconsDuotone.funnel;
  }
  if (icon == Icons.lock ||
      icon == Icons.lock_outline ||
      icon == Icons.lock_outline_rounded) {
    return PhosphorIconsDuotone.lockKey;
  }
  if (icon == Icons.security ||
      icon == Icons.shield_outlined ||
      icon == Icons.shield_rounded) {
    return PhosphorIconsDuotone.shieldCheck;
  }
  if (icon == Icons.fingerprint || icon == Icons.fingerprint_rounded) {
    return PhosphorIconsDuotone.fingerprint;
  }
  if (icon == Icons.notifications ||
      icon == Icons.notifications_outlined ||
      icon == Icons.notifications_rounded ||
      icon == Icons.notifications_active ||
      icon == Icons.notifications_active_outlined) {
    return PhosphorIconsDuotone.bellRinging;
  }
  if (icon == Icons.schedule ||
      icon == Icons.schedule_rounded ||
      icon == Icons.alarm ||
      icon == Icons.alarm_rounded ||
      icon == Icons.alarm_outlined) {
    return PhosphorIconsDuotone.alarm;
  }
  if (icon == Icons.file_upload ||
      icon == Icons.file_upload_outlined ||
      icon == Icons.cloud_upload ||
      icon == Icons.cloud_upload_outlined) {
    return PhosphorIconsDuotone.cloudArrowUp;
  }
  if (icon == Icons.file_download ||
      icon == Icons.file_download_outlined ||
      icon == Icons.cloud_download ||
      icon == Icons.cloud_download_outlined) {
    return PhosphorIconsDuotone.cloudArrowDown;
  }
  if (icon == Icons.cloud_sync ||
      icon == Icons.sync ||
      icon == Icons.sync_rounded ||
      icon == Icons.cloud_done ||
      icon == Icons.cloud_done_outlined ||
      icon == Icons.cloud_off ||
      icon == Icons.cloud_off_outlined ||
      icon == Icons.refresh ||
      icon == Icons.autorenew) {
    return PhosphorIconsDuotone.arrowsClockwise;
  }
  if (icon == Icons.info_outline ||
      icon == Icons.info_outline_rounded ||
      icon == Icons.help_outline) {
    return PhosphorIconsDuotone.info;
  }
  if (icon == Icons.history_edu || icon == Icons.history_edu_rounded) {
    return PhosphorIconsDuotone.scroll;
  }
  if (icon == Icons.table_view || icon == Icons.table_view_outlined) {
    return PhosphorIconsDuotone.table;
  }
  if (icon == Icons.feedback_outlined || icon == Icons.chat_outlined) {
    return PhosphorIconsDuotone.chatCircleDots;
  }
  if (icon == Icons.delete_outline ||
      icon == Icons.delete_forever_outlined ||
      icon == Icons.person_remove_outlined) {
    return PhosphorIconsDuotone.trash;
  }
  if (icon == Icons.person ||
      icon == Icons.person_outline ||
      icon == Icons.account_circle) {
    return PhosphorIconsDuotone.userCircle;
  }
  if (icon == Icons.groups || icon == Icons.groups_outlined) {
    return PhosphorIconsDuotone.usersThree;
  }
  if (icon == Icons.handshake_outlined) {
    return PhosphorIconsDuotone.handshake;
  }
  if (icon == Icons.event_repeat ||
      icon == Icons.event_repeat_rounded ||
      icon == Icons.redo ||
      icon == Icons.redo_rounded) {
    return PhosphorIconsDuotone.repeat;
  }
  if (icon == Icons.picture_as_pdf || icon == Icons.picture_as_pdf_outlined) {
    return PhosphorIconsDuotone.filePdf;
  }
  if (icon == Icons.auto_stories ||
      icon == Icons.auto_stories_outlined ||
      icon == Icons.auto_stories_rounded) {
    return PhosphorIconsDuotone.bookOpen;
  }
  if (icon == Icons.auto_awesome ||
      icon == Icons.auto_awesome_outlined ||
      icon == Icons.auto_awesome_rounded) {
    return PhosphorIconsDuotone.sparkle;
  }
  if (icon == Icons.forest || icon == Icons.forest_outlined) {
    return PhosphorIconsDuotone.treePalm;
  }
  if (icon == Icons.offline_bolt ||
      icon == Icons.offline_bolt_outlined ||
      icon == Icons.bolt_rounded) {
    return PhosphorIconsDuotone.database;
  }
  if (icon == Icons.warning_amber_rounded || icon == Icons.warning_rounded) {
    return PhosphorIconsDuotone.warningCircle;
  }
  if (icon == Icons.trending_down || icon == Icons.trending_down_rounded) {
    return PhosphorIconsDuotone.trendDown;
  }
  if (icon == Icons.favorite_border || icon == Icons.favorite) {
    return PhosphorIconsDuotone.heart;
  }
  if (icon == Icons.check_circle_outline) {
    return PhosphorIconsDuotone.checkCircle;
  }
  if (icon == Icons.trending_up ||
      icon == Icons.trending_up_rounded ||
      icon == Icons.show_chart ||
      icon == Icons.arrow_downward ||
      icon == Icons.arrow_downward_rounded ||
      icon == Icons.arrow_downward_outlined) {
    return PhosphorIconsDuotone.trendUp;
  }
  if (icon == Icons.more_horiz ||
      icon == Icons.category ||
      icon == Icons.category_outlined ||
      icon == Icons.grid_view ||
      icon == Icons.grid_view_rounded ||
      icon == Icons.grid_view_outlined ||
      icon == Icons.apps ||
      icon == Icons.widgets) {
    return PhosphorIconsDuotone.squaresFour;
  }
  if (icon == Icons.speed || icon == Icons.stacked_line_chart) {
    return PhosphorIconsDuotone.pulse;
  }
  if (icon == Icons.track_changes ||
      icon == Icons.track_changes_rounded ||
      icon == Icons.gps_fixed ||
      icon == Icons.crisis_alert) {
    return PhosphorIconsDuotone.target;
  }
  if (icon == Icons.location_on ||
      icon == Icons.location_on_outlined ||
      icon == Icons.place ||
      icon == Icons.place_outlined ||
      icon == Icons.pin_drop) {
    return PhosphorIconsDuotone.mapPin;
  }
  if (icon == Icons.eco || icon == Icons.eco_outlined || icon == Icons.park) {
    return PhosphorIconsDuotone.plant;
  }
  if (icon == Icons.logout ||
      icon == Icons.exit_to_app ||
      icon == Icons.exit_to_app_rounded) {
    return PhosphorIconsDuotone.signOut;
  }
  if (icon == Icons.local_activity ||
      icon == Icons.local_activity_outlined ||
      icon == Icons.local_activity_rounded) {
    return PhosphorIconsDuotone.ticket;
  }
  return null;
}

/// Mengambil [PhosphorDuotoneIconData] dari kunci kategori atau [IconData] fallback.
PhosphorDuotoneIconData phosphorForCategoryOrIcon(String? key, IconData icon) =>
    phosphorForKey(key) ?? phosphorForIcon(icon) ?? PhosphorIconsDuotone.squaresFour;

/// Ikon Phosphor Duotone adaptif yang otomatis menyesuaikan layer duotone untuk tema Sunset & Daylight.
class AppDuotoneIcon extends StatelessWidget {
  final PhosphorDuotoneIconData icon;
  final double size;
  final Color? color;
  final Color? secondaryColor;

  const AppDuotoneIcon(
    this.icon, {
    super.key,
    this.size = 20,
    this.color,
    this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    final effectiveSecondary =
        secondaryColor ?? effectiveColor.withValues(alpha: isDark ? 0.34 : 0.24);
    return PhosphorDuotoneIcon(
      icon,
      size: size,
      color: effectiveColor,
      secondaryColor: effectiveSecondary,
    );
  }
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
