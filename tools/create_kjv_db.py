#!/usr/bin/env python3
"""
KJV Bible DB 생성 스크립트
소스: https://github.com/aruljohn/Bible-kjv (Public Domain)
출력: assets/db/en_kjv.db
"""

import json
import sqlite3
import urllib.request
import os
import sys

BASE_URL = "https://raw.githubusercontent.com/aruljohn/Bible-kjv/master/"

# (id, 공식이름, 약자, testament, 파일명)
BOOKS = [
    (1,  'Genesis',          'Gen',    'old', 'Genesis'),
    (2,  'Exodus',           'Exod',   'old', 'Exodus'),
    (3,  'Leviticus',        'Lev',    'old', 'Leviticus'),
    (4,  'Numbers',          'Num',    'old', 'Numbers'),
    (5,  'Deuteronomy',      'Deut',   'old', 'Deuteronomy'),
    (6,  'Joshua',           'Josh',   'old', 'Joshua'),
    (7,  'Judges',           'Judg',   'old', 'Judges'),
    (8,  'Ruth',             'Ruth',   'old', 'Ruth'),
    (9,  '1 Samuel',         '1Sam',   'old', '1Samuel'),
    (10, '2 Samuel',         '2Sam',   'old', '2Samuel'),
    (11, '1 Kings',          '1Kgs',   'old', '1Kings'),
    (12, '2 Kings',          '2Kgs',   'old', '2Kings'),
    (13, '1 Chronicles',     '1Chr',   'old', '1Chronicles'),
    (14, '2 Chronicles',     '2Chr',   'old', '2Chronicles'),
    (15, 'Ezra',             'Ezra',   'old', 'Ezra'),
    (16, 'Nehemiah',         'Neh',    'old', 'Nehemiah'),
    (17, 'Esther',           'Esth',   'old', 'Esther'),
    (18, 'Job',              'Job',    'old', 'Job'),
    (19, 'Psalms',           'Ps',     'old', 'Psalms'),
    (20, 'Proverbs',         'Prov',   'old', 'Proverbs'),
    (21, 'Ecclesiastes',     'Eccl',   'old', 'Ecclesiastes'),
    (22, 'Song of Solomon',  'Song',   'old', 'SongofSolomon'),
    (23, 'Isaiah',           'Isa',    'old', 'Isaiah'),
    (24, 'Jeremiah',         'Jer',    'old', 'Jeremiah'),
    (25, 'Lamentations',     'Lam',    'old', 'Lamentations'),
    (26, 'Ezekiel',          'Ezek',   'old', 'Ezekiel'),
    (27, 'Daniel',           'Dan',    'old', 'Daniel'),
    (28, 'Hosea',            'Hos',    'old', 'Hosea'),
    (29, 'Joel',             'Joel',   'old', 'Joel'),
    (30, 'Amos',             'Amos',   'old', 'Amos'),
    (31, 'Obadiah',          'Obad',   'old', 'Obadiah'),
    (32, 'Jonah',            'Jonah',  'old', 'Jonah'),
    (33, 'Micah',            'Mic',    'old', 'Micah'),
    (34, 'Nahum',            'Nah',    'old', 'Nahum'),
    (35, 'Habakkuk',         'Hab',    'old', 'Habakkuk'),
    (36, 'Zephaniah',        'Zeph',   'old', 'Zephaniah'),
    (37, 'Haggai',           'Hag',    'old', 'Haggai'),
    (38, 'Zechariah',        'Zech',   'old', 'Zechariah'),
    (39, 'Malachi',          'Mal',    'old', 'Malachi'),
    (40, 'Matthew',          'Matt',   'new', 'Matthew'),
    (41, 'Mark',             'Mark',   'new', 'Mark'),
    (42, 'Luke',             'Luke',   'new', 'Luke'),
    (43, 'John',             'John',   'new', 'John'),
    (44, 'Acts',             'Acts',   'new', 'Acts'),
    (45, 'Romans',           'Rom',    'new', 'Romans'),
    (46, '1 Corinthians',    '1Cor',   'new', '1Corinthians'),
    (47, '2 Corinthians',    '2Cor',   'new', '2Corinthians'),
    (48, 'Galatians',        'Gal',    'new', 'Galatians'),
    (49, 'Ephesians',        'Eph',    'new', 'Ephesians'),
    (50, 'Philippians',      'Phil',   'new', 'Philippians'),
    (51, 'Colossians',       'Col',    'new', 'Colossians'),
    (52, '1 Thessalonians',  '1Thess', 'new', '1Thessalonians'),
    (53, '2 Thessalonians',  '2Thess', 'new', '2Thessalonians'),
    (54, '1 Timothy',        '1Tim',   'new', '1Timothy'),
    (55, '2 Timothy',        '2Tim',   'new', '2Timothy'),
    (56, 'Titus',            'Titus',  'new', 'Titus'),
    (57, 'Philemon',         'Phlm',   'new', 'Philemon'),
    (58, 'Hebrews',          'Heb',    'new', 'Hebrews'),
    (59, 'James',            'Jas',    'new', 'James'),
    (60, '1 Peter',          '1Pet',   'new', '1Peter'),
    (61, '2 Peter',          '2Pet',   'new', '2Peter'),
    (62, '1 John',           '1John',  'new', '1John'),
    (63, '2 John',           '2John',  'new', '2John'),
    (64, '3 John',           '3John',  'new', '3John'),
    (65, 'Jude',             'Jude',   'new', 'Jude'),
    (66, 'Revelation',       'Rev',    'new', 'Revelation'),
]

# KJV 유명 구절 (book_id, chapter, verse, category)
# 한국어 DB의 동일한 구절들을 영어로 대응
POPULAR_VERSES = [
    # comfort
    (23, 41, 10, 'comfort'),
    (19, 23, 4,  'comfort'),
    (19, 46, 1,  'comfort'),
    (40, 11, 28, 'comfort'),
    (45, 8,  28, 'comfort'),
    (19, 34, 18, 'comfort'),
    (23, 40, 31, 'comfort'),
    (50, 4,  13, 'comfort'),
    (19, 55, 22, 'comfort'),
    (47, 12, 9,  'comfort'),
    (24, 29, 11, 'comfort'),
    (19, 121,1,  'comfort'),
    # thanksgiving
    (52, 5,  18, 'thanksgiving'),
    (19, 100,4,  'thanksgiving'),
    (19, 107,1,  'thanksgiving'),
    (19, 136,1,  'thanksgiving'),
    (19, 118,24, 'thanksgiving'),
    (19, 103,2,  'thanksgiving'),
    (51, 3,  17, 'thanksgiving'),
    # hope
    (45, 15, 13, 'hope'),
    (58, 11, 1,  'hope'),
    (19, 27, 14, 'hope'),
    (19, 62, 5,  'hope'),
    (25, 3,  25, 'hope'),
    (45, 8,  25, 'hope'),
    # love
    (46, 13, 4,  'love'),
    (46, 13, 7,  'love'),
    (46, 13, 13, 'love'),
    (43, 3,  16, 'love'),
    (62, 4,  19, 'love'),
    (62, 4,  8,  'love'),
    (45, 8,  38, 'love'),
    (43, 15, 13, 'love'),
    # faith
    (45, 10, 17, 'faith'),
    (40, 17, 20, 'faith'),
    (48, 2,  20, 'faith'),
    (59, 1,  6,  'faith'),
    (47, 5,  7,  'faith'),
    # peace
    (43, 14, 27, 'peace'),
    (50, 4,  6,  'peace'),
    (50, 4,  7,  'peace'),
    (23, 26, 3,  'peace'),
    (19, 4,  8,  'peace'),
    (40, 6,  34, 'peace'),
    # wisdom
    (20, 3,  5,  'wisdom'),
    (20, 3,  6,  'wisdom'),
    (59, 1,  5,  'wisdom'),
    (20, 1,  7,  'wisdom'),
    (20, 9,  10, 'wisdom'),
    (19, 119,105,'wisdom'),
    (21, 3,  1,  'wisdom'),
]


def fetch_book(filename):
    url = BASE_URL + filename + ".json"
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            return json.loads(resp.read().decode('utf-8'))
    except Exception as e:
        print(f"  ERROR fetching {filename}: {e}", file=sys.stderr)
        return None


def main():
    db_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db', 'en_kjv.db')
    db_path = os.path.normpath(db_path)

    # 기존 DB 삭제
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # 스키마 생성
    cur.executescript("""
        CREATE TABLE books (
            id           INTEGER PRIMARY KEY,
            name         TEXT NOT NULL,
            abbreviation TEXT NOT NULL,
            testament    TEXT NOT NULL
        );
        CREATE TABLE verses (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            book_id  INTEGER NOT NULL,
            chapter  INTEGER NOT NULL,
            verse    INTEGER NOT NULL,
            text     TEXT NOT NULL,
            FOREIGN KEY (book_id) REFERENCES books(id)
        );
        CREATE TABLE popular_verses (
            id       INTEGER PRIMARY KEY AUTOINCREMENT,
            verse_id INTEGER NOT NULL,
            category TEXT NOT NULL,
            FOREIGN KEY (verse_id) REFERENCES verses(id)
        );
        CREATE INDEX idx_verses_book    ON verses(book_id);
        CREATE INDEX idx_verses_chapter ON verses(book_id, chapter);
        CREATE INDEX idx_popular_cat    ON popular_verses(category);
    """)

    # 책 삽입
    for (bid, name, abbr, testament, _) in BOOKS:
        cur.execute(
            "INSERT INTO books VALUES (?,?,?,?)",
            (bid, name, abbr, testament)
        )
    conn.commit()
    print(f"✓ Inserted {len(BOOKS)} books")

    # 구절 삽입: popular_verses에 필요한 (book_id, chapter, verse) 집합
    needed = {(b, c, v) for (b, c, v, _) in POPULAR_VERSES}

    # book_id → 파일명 맵
    file_map = {bid: fname for (bid, _, _, _, fname) in BOOKS}

    # verse_id 역인덱스: (book_id, chapter, verse) → verse_id
    verse_id_map = {}
    total_verses = 0

    for (bid, name, abbr, testament, filename) in BOOKS:
        print(f"  Fetching {name}...", end=' ', flush=True)
        data = fetch_book(filename)
        if data is None:
            continue

        chapters = data.get('chapters', [])
        rows = []
        for ch_obj in chapters:
            ch_num = int(ch_obj['chapter'])
            for v_obj in ch_obj['verses']:
                v_num = int(v_obj['verse'])
                text = v_obj['text'].strip()
                rows.append((bid, ch_num, v_num, text))

        # 전체 구절 삽입
        cur.executemany(
            "INSERT INTO verses (book_id, chapter, verse, text) VALUES (?,?,?,?)",
            rows
        )
        # verse_id를 역조회
        cur.execute(
            "SELECT id, chapter, verse FROM verses WHERE book_id=?", (bid,)
        )
        for (vid, ch, v) in cur.fetchall():
            verse_id_map[(bid, ch, v)] = vid

        total_verses += len(rows)
        print(f"{len(rows)} verses")

    conn.commit()
    print(f"✓ Total verses inserted: {total_verses}")

    # popular_verses 삽입
    pop_rows = []
    missing = []
    for (bid, ch, v, cat) in POPULAR_VERSES:
        vid = verse_id_map.get((bid, ch, v))
        if vid:
            pop_rows.append((vid, cat))
        else:
            missing.append((bid, ch, v, cat))

    cur.executemany(
        "INSERT INTO popular_verses (verse_id, category) VALUES (?,?)",
        pop_rows
    )
    conn.commit()

    print(f"✓ popular_verses inserted: {len(pop_rows)}")
    if missing:
        print(f"⚠ Missing popular verses: {missing}")

    conn.close()

    size_kb = os.path.getsize(db_path) // 1024
    print(f"\n✅ DB created: {db_path} ({size_kb} KB)")


if __name__ == '__main__':
    main()
