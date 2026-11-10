class Application {
  final String id;
  final String title;
  final String description;
  final String applicationType;
  final String status;
  final String applicantId;
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  Application({
    required this.id,
    required this.title,
    required this.description,
    required this.applicationType,
    required this.status,
    required this.applicantId,
    required this.submittedAt,
    this.updatedAt,
    this.metadata,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      applicationType: json['applicationType'],
      status: json['status'],
      applicantId: json['applicantId'],
      submittedAt: DateTime.parse(json['submittedAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'applicationType': applicationType,
      'status': status,
      'applicantId': applicantId,
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}
