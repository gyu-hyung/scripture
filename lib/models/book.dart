class Book {
  final int id;
  final String name;
  final String abbreviation;
  final String testament;

  const Book({
    required this.id,
    required this.name,
    required this.abbreviation,
    required this.testament,
  });

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] as int,
      name: map['name'] as String,
      abbreviation: map['abbreviation'] as String,
      testament: map['testament'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'abbreviation': abbreviation,
      'testament': testament,
    };
  }

  bool get isOldTestament => testament == 'old';
  bool get isNewTestament => testament == 'new';
}
