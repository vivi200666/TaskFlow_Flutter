class Task {
  final int id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? dueDate;
  final bool completed;
  final int? categoryId;
  final Map<String, dynamic>? categoryDetails;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.completed,
    this.categoryId,
    this.categoryDetails,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['titulo'],
      description: json['descripcion'] ?? '',
      status: json['estado'] ?? 'TODO',
      priority: json['prioridad'] ?? 'M',
      dueDate: json['fecha_vencimiento'],
      completed: json['completada'] ?? false,
      categoryId: json['categoria'],
      categoryDetails: json['categoria_detalles'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': title,
      'descripcion': description,
      'estado': status,
      'prioridad': priority,
      'fecha_vencimiento': dueDate,
      'completada': completed,
      'categoria': categoryId,
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? dueDate,
    bool? completed,
    int? categoryId,
    Map<String, dynamic>? categoryDetails,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      categoryId: categoryId ?? this.categoryId,
      categoryDetails: categoryDetails ?? this.categoryDetails,
    );
  }
}