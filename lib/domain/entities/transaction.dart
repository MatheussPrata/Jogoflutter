enum TransactionType { income, expense }

/// Entidade que representa uma transação financeira.
class Transaction {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
  });

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  /// Valor com sinal: positivo para receitas, negativo para despesas.
  double get signedAmount => isIncome ? amount : -amount;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      description: json['description'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => TransactionType.expense,
      ),
      category: json['category'] as String? ?? 'Outros',
      date: DateTime.parse(json['date'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.name,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  Transaction copyWith({
    String? id,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
    );
  }
}