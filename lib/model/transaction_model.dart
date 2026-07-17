class TransactionModel {
  final int id;
  final String date;
  final int acId;
  final String detail;
  final double credit;
  final double debit;
  final int isSynced;
  final int isDeleted;
  final int updatedAt;

  TransactionModel({
    required this.id,
    required this.date,
    required this.acId,
    required this.detail,
    required this.credit,
    required this.debit,
    required this.isSynced,
    required this.isDeleted,
    required this.updatedAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] is int ? map['id'] : (int.tryParse(map['id']?.toString() ?? '') ?? 0),
      date: map['date']?.toString() ?? '',
      acId: map['AcId'] is int ? map['AcId'] : (int.tryParse(map['AcId']?.toString() ?? '') ?? 0),
      detail: map['detail']?.toString() ?? '',
      credit: double.tryParse(map['credit']?.toString() ?? '0.0') ?? 0.0,
      debit: double.tryParse(map['debit']?.toString() ?? '0.0') ?? 0.0,
      isSynced: map['is_synced'] is int ? map['is_synced'] : (int.tryParse(map['is_synced']?.toString() ?? '') ?? 0),
      isDeleted: map['is_deleted'] is int ? map['is_deleted'] : (int.tryParse(map['is_deleted']?.toString() ?? '') ?? 0),
      updatedAt: map['updated_at'] is int ? map['updated_at'] : (int.tryParse(map['updated_at']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'AcId': acId,
      'detail': detail,
      'credit': credit,
      'debit': debit,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
      'updated_at': updatedAt,
    };
  }
}
