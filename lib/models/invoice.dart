class InvoiceLineItem {
  String description;
  double amount;

  InvoiceLineItem({required this.description, required this.amount});

  Map<String, dynamic> toMap() => {
        'description': description,
        'amount': amount,
      };

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Invoice {
  final String id;
  final String clientName;
  final String reportId;
  final List<InvoiceLineItem> items;
  final double amount;
  final DateTime dueDate;
  final DateTime createdAt;
  final String? paymentUrl;
  final String? clientEmail;
  final bool isPaid;

  Invoice({
    this.id = '',
    required this.clientName,
    required this.reportId,
    this.items = const [],
    double? amount,
    required this.dueDate,
    this.paymentUrl,
    this.clientEmail,
    this.isPaid = false,
    DateTime? createdAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        amount = amount ??
            items.fold(0, (double s, item) => s + item.amount);

  Map<String, dynamic> toMap() {
    return {
      'clientName': clientName,
      'reportId': reportId,
      'items': items.map((e) => e.toMap()).toList(),
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      if (paymentUrl != null) 'paymentUrl': paymentUrl,
      if (clientEmail != null) 'clientEmail': clientEmail,
      'isPaid': isPaid,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      clientName: map['clientName'] ?? '',
      reportId: map['reportId'] ?? '',
      items: (map['items'] as List?)
              ?.map((e) => InvoiceLineItem.fromMap(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      dueDate: map['dueDate'] is String
          ? DateTime.tryParse(map['dueDate']) ?? DateTime.now()
          : (map['dueDate'] as DateTime? ?? DateTime.now()),
      paymentUrl: map['paymentUrl'] as String?,
      clientEmail: map['clientEmail'] as String?,
      isPaid: map['isPaid'] as bool? ?? false,
      createdAt: map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : (map['createdAt'] as DateTime? ?? DateTime.now()),
    );
  }
}
