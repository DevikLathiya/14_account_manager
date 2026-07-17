class AccountModel {
  final int id;
  final String name;
  final double credit;
  final double debit;
  final double balance;
  final int isSynced;
  final int isDeleted;
  final int updatedAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.credit,
    required this.debit,
    required this.balance,
    required this.isSynced,
    required this.isDeleted,
    required this.updatedAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map) {
    return AccountModel(
      id: map['id'] is int ? map['id'] : (int.tryParse(map['id']?.toString() ?? '') ?? 0),
      name: map['name']?.toString() ?? '',
      credit: double.tryParse(map['credit']?.toString() ?? '0.0') ?? 0.0,
      debit: double.tryParse(map['debit']?.toString() ?? '0.0') ?? 0.0,
      balance: double.tryParse(map['balance']?.toString() ?? '0.0') ?? 0.0,
      isSynced: map['is_synced'] is int ? map['is_synced'] : (int.tryParse(map['is_synced']?.toString() ?? '') ?? 0),
      isDeleted: map['is_deleted'] is int ? map['is_deleted'] : (int.tryParse(map['is_deleted']?.toString() ?? '') ?? 0),
      updatedAt: map['updated_at'] is int ? map['updated_at'] : (int.tryParse(map['updated_at']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'credit': credit, 'debit': debit, 'balance': balance, 'is_synced': isSynced, 'is_deleted': isDeleted, 'updated_at': updatedAt};
  }
}
