import 'package:intl/intl.dart';

String formatRupiah(int number) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(number);
}

String formatDate(DateTime date) {
  return DateFormat('dd MMM yyyy', 'id_ID').format(date);
}
