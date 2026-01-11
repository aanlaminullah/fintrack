import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';
import '../../domain/entities/transaction.dart';
import '../../core/utils/app_icons.dart';

class TransactionItem extends StatelessWidget {
  final Transaction transaction;
  final bool showDate;

  const TransactionItem({
    super.key,
    required this.transaction,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == 'expense';
    final color = isExpense ? Colors.red[700] : Colors.green[700];

    // Convert integer color back to Color object
    final categoryColor = Color(transaction.category?.color ?? 0xFF9E9E9E);

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            AppIcons.getIcon(transaction.category?.icon ?? ''),
            color: categoryColor,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          transaction.category?.name ?? 'Umum',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${isExpense ? '-' : '+'} ${formatRupiah(transaction.amount)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (showDate) ...[
              const SizedBox(height: 4),
              Text(
                formatDate(transaction.date),
                style: TextStyle(color: Colors.grey[400], fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
