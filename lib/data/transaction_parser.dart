import 'tables.dart';

/// Parser utilitas teks untuk mendeteksi nominal, sumber aplikasi, dan kategori dari teks yang dibagikan pengguna.
class TransactionParser {
  /// Ekstrak nominal uang dalam format Rupiah (contoh: "Rp 25.000", "Rp25.000,00", "IDR 50.000").
  static int? extractAmount(String text) {
    final regex = RegExp(
      r'(?:Rp|IDR)\s*([0-9]{1,3}(?:\.[0-9]{3})*(?:,[0-9]{1,2})?|[0-9]+)',
      caseSensitive: false,
    );
    final match = regex.firstMatch(text);
    if (match == null) return null;

    var numStr = match.group(1)!;
    if (numStr.contains(',')) {
      numStr = numStr.split(',')[0];
    }
    numStr = numStr.replaceAll('.', '').trim();
    return int.tryParse(numStr);
  }

  /// Deteksi nama aplikasi bank/e-wallet berdasarkan teks.
  static String detectSourceApp(String text, {String? packageName, String? title}) {
    final lower = '${title ?? ''} $text ${packageName ?? ''}'.toLowerCase();

    if (lower.contains('gopay') || lower.contains('gojek')) return 'GoPay';
    if (lower.contains('bca') || lower.contains('mybca')) return 'BCA';
    if (lower.contains('mandiri') || lower.contains('livin')) return "Livin' Mandiri";
    if (lower.contains('brimo') || lower.contains('bri')) return 'BRImo';
    if (lower.contains('dana')) return 'DANA';
    if (lower.contains('ovo')) return 'OVO';
    if (lower.contains('shopeepay') || lower.contains('shopee')) return 'ShopeePay';
    if (lower.contains('bni')) return 'BNI Mobile';

    return 'Bank / E-Wallet';
  }

  /// Deteksi tipe transaksi (Pemasukan vs Pengeluaran).
  static TxType detectType(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('masuk') ||
        lower.contains('menerima') ||
        lower.contains('received') ||
        lower.contains('terima uang') ||
        lower.contains('transfer masuk') ||
        lower.contains('top up berhasil') ||
        lower.contains('kredit')) {
      return TxType.income;
    }

    return TxType.expense;
  }

  /// Menebak kategori pengeluaran berdasarkan nama toko/merchant atau kata kunci.
  static (String id, String name)? suggestCategory(String text, TxType type) {
    if (type == TxType.income) {
      return ('cat-inc-other', 'Other');
    }

    final lower = text.toLowerCase();

    // Makanan & Minuman
    if (lower.contains('kopi') ||
        lower.contains('coffee') ||
        lower.contains('cafe') ||
        lower.contains('kafe') ||
        lower.contains('resto') ||
        lower.contains('makan') ||
        lower.contains('food') ||
        lower.contains('gofood') ||
        lower.contains('shopeefood') ||
        lower.contains('grabfood') ||
        lower.contains('bakso') ||
        lower.contains('ayam') ||
        lower.contains('mie') ||
        lower.contains('boba') ||
        lower.contains('tea') ||
        lower.contains('martabak') ||
        lower.contains('burger') ||
        lower.contains('pizza')) {
      return ('cat-exp-food', 'Food & Drinks');
    }

    // Transportasi
    if (lower.contains('goride') ||
        lower.contains('gocar') ||
        lower.contains('grabride') ||
        lower.contains('grabcar') ||
        lower.contains('grab') ||
        lower.contains('gojek') ||
        lower.contains('ojek') ||
        lower.contains('taksi') ||
        lower.contains('taxi') ||
        lower.contains('bensin') ||
        lower.contains('spbu') ||
        lower.contains('pertamina') ||
        lower.contains('shell') ||
        lower.contains('tol') ||
        lower.contains('parkir') ||
        lower.contains('kereta') ||
        lower.contains('krl') ||
        lower.contains('mrt')) {
      return ('cat-exp-transport', 'Transport');
    }

    // Belanja & Kebutuhan
    if (lower.contains('indomaret') ||
        lower.contains('alfamart') ||
        lower.contains('alfamidi') ||
        lower.contains('superindo') ||
        lower.contains('shopee') ||
        lower.contains('tokopedia') ||
        lower.contains('lazada') ||
        lower.contains('belanja') ||
        lower.contains('mart')) {
      return ('cat-exp-shopping', 'Shopping');
    }

    // Tagihan & Rumah Tangga
    if (lower.contains('pln') ||
        lower.contains('listrik') ||
        lower.contains('pdam') ||
        lower.contains('air') ||
        lower.contains('wifi') ||
        lower.contains('indihome') ||
        lower.contains('biznet') ||
        lower.contains('bpjs') ||
        lower.contains('kos') ||
        lower.contains('kontrakan') ||
        lower.contains('tagihan')) {
      return ('cat-exp-housing', 'Rent & Bills');
    }

    // Hiburan
    if (lower.contains('cinema') ||
        lower.contains('xxi') ||
        lower.contains('cgv') ||
        lower.contains('bioskop') ||
        lower.contains('netflix') ||
        lower.contains('spotify') ||
        lower.contains('game') ||
        lower.contains('steam') ||
        lower.contains('playstation')) {
      return ('cat-exp-fun', 'Entertainment');
    }

    // Kesehatan
    if (lower.contains('apotek') ||
        lower.contains('kimia farma') ||
        lower.contains('k24') ||
        lower.contains('obat') ||
        lower.contains('dokter') ||
        lower.contains('klinik') ||
        lower.contains('rs') ||
        lower.contains('rumah sakit')) {
      return ('cat-exp-health', 'Health');
    }

    return ('cat-exp-other', 'Other');
  }

  /// Ekstrak nama merchant atau catatan singkat dari teks.
  static String extractMerchantNote(String text, String sourceApp) {
    final match = RegExp(
      r'(?:di|ke|merchant|pembayaran)\s+([A-Za-z0-9\s\.\-_&]{3,30}?)(?:\s+berhasil|\s+sukses|\s+sebesar|\.|$)',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null && match.group(1) != null) {
      final merchant = match.group(1)!.trim();
      if (merchant.isNotEmpty && merchant.length > 2) {
        return merchant;
      }
    }

    return 'Transaksi $sourceApp';
  }
}
