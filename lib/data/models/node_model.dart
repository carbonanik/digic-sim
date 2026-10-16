class NodeModel {
  final String id;

  NodeModel({required this.id});

  Map<String, dynamic> toMap() => {'id': id};
  factory NodeModel.fromMap(Map<String, dynamic> map) =>
      NodeModel(id: map['id'] ?? '');
}
