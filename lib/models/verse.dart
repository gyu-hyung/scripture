class Verse {
  final int id;
  final int bookId;
  final int chapter;
  final int verse;
  final String text;
  final String? bookName;
  final String? bookAbbreviation;

  const Verse({
    required this.id,
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
    this.bookName,
    this.bookAbbreviation,
  });

  factory Verse.fromMap(Map<String, dynamic> map) {
    return Verse(
      id: map['id'] as int,
      bookId: map['book_id'] as int,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int,
      text: map['text'] as String,
      bookName: map['book_name'] as String?,
      bookAbbreviation: map['abbreviation'] as String?,
    );
  }

  String get reference {
    final name = bookName ?? bookAbbreviation ?? '';
    return '$name $chapter:$verse';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'chapter': chapter,
      'verse': verse,
      'text': text,
    };
  }
}
