class WireModel {
  final String id;

  WireModel({required this.id});

  Map<String, dynamic> toMap() => {'id': id};
  factory WireModel.fromMap(Map<String, dynamic> map) =>
      WireModel(id: map['id'] ?? '');
}
