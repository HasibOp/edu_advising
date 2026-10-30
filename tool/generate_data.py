import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / 'resources' / 'pdfs'
OUT = ROOT / 'lib' / 'data'
OFFER_MD = SRC / 'CSE Course Offer List & Section Structures - Fall 2026.md'
ROUTINE_DOCX = SRC / 'CSE & EEE All Semesters - Fall 2026 Routine.docx'

W = '{http://schemas.openxmlformats.org/wordprocessingml/2006/main}'


def dart_str(s):
    return "'" + s.replace('\\', '\\\\').replace("'", "\\'") + "'"


def clean(s):
    s = s.replace('\\-', '-').replace('**', '')
    return re.sub(r'\s+', ' ', s).strip()


def title_case(title):
    small = {'and', 'of', 'for', 'in', 'the', 'to', 'with', 'on', 'a'}
    words = clean(title).split(' ')
    out = []
    for i, w in enumerate(words):
        if w.isupper() and len(w) > 1:
            out.append(w)
        elif i > 0 and w.lower() in small:
            out.append(w.lower())
        else:
            out.append(w[:1].upper() + w[1:])
    return ' '.join(out)


def parse_offer():
    text = OFFER_MD.read_text(encoding='utf-8')
    blocks = re.split(r'\*\*Semester (\d+)\*\*', text)
    semesters = {}
    for i in range(1, len(blocks), 2):
        sem = int(blocks[i])
        body = blocks[i + 1]
        rows = [r for r in body.splitlines() if r.strip().startswith('|')]
        courses, sections, n = [], {}, 0
        mode = None
        for r in rows:
            cells = [clean(c) for c in r.strip().strip('|').split('|')]
            joined = ' '.join(cells)
            if 'Course List' in joined:
                mode = 'courses'
                continue
            if 'Section Structure' in joined:
                mode = 'sections'
                continue
            if set(joined.replace(' ', '')) <= set(':-'):
                continue
            if 'Course Code' in joined or 'Section 1' in joined:
                if 'Section 1' in joined:
                    n = len([c for c in cells if c.startswith('Section')])
                continue
            if mode == 'courses':
                code = re.sub(r'\s+', ' ', cells[0]).strip()
                courses.append((code, title_case(cells[1]), float(cells[2])))
            elif mode == 'sections':
                for g, cell in enumerate(cells[:n]):
                    for code, no, cap in re.findall(
                            r'([A-Z]+ ?\d+)\.(\d+)\s*\((\d+) seats\)', cell):
                        code = re.sub(r'([A-Z]+) ?(\d+)', r'\1 \2', code)
                        sections.setdefault(code, [[] for _ in range(n)])
                        sections[code][g].append((int(no), int(cap)))
        if sem == 10 and 'CSE 466' in sections and n >= 7:
            parts = sections['CSE 466'][6]
            if parts and parts[0][0] == 6:
                parts[0] = (7, parts[0][1])
        semesters[sem] = (n, courses, sections)
    return semesters


def cell_text(tc):
    lines = []
    for p in tc.iter(W + 'p'):
        t = ''.join(x.text or '' for x in p.iter(W + 't')).strip()
        if t:
            lines.append(clean(t))
    return lines


def table_rows(tbl):
    return [[cell_text(tc) for tc in tr.findall(W + 'tc')]
            for tr in tbl.findall(W + 'tr')]


COURSE_RE = re.compile(
    r'^([A-Z]{2,5}) ?(\d{3})(\.\d+)?( ?\(EEE\))?( ?\((\d{1,2}\.\d{2}) ?- ?(\d{1,2}\.\d{2})\))?$')
WEIRD = []


def parse_routine_cell(lines):
    if not lines:
        return None
    glued = re.match(r'^([A-Z]{2,5} ?\d{3}\.\d+)([A-Z].*)$', lines[0])
    if len(lines) == 1 and glued:
        lines = [glued.group(1), glued.group(2)]
    course = lines[0].upper()
    m = COURSE_RE.match(course)
    if not m:
        WEIRD.append(lines)
        return None
    code = f'{m.group(1)} {m.group(2)}{m.group(3) or ""}'
    if m.group(4):
        code += ' (EEE)'
    faculty = lines[1] if len(lines) > 1 else ''
    faculty = re.sub(r'^DR\.? ?', 'Dr. ', faculty)
    time = f'{m.group(6)}-{m.group(7)}' if m.group(5) else None
    return code, faculty, time


def parse_docx():
    root = ET.fromstring(zipfile.ZipFile(ROUTINE_DOCX).read('word/document.xml'))
    tables = root.find(W + 'body').findall(W + 'tbl')
    routine, days, exam, faculty = [], [], {}, []
    day = None
    for tbl in tables:
        rows = table_rows(tbl)
        title = ' '.join(rows[0][0]) if rows and rows[0] else ''
        if title in ('Saturday', 'Sunday', 'Monday', 'Tuesday', 'Wednesday',
                     'Thursday', 'Friday'):
            day = title
            days.append(day)
            rows = rows[1:]
            title = ' '.join(rows[0][0])
        if title in ('Theory Classes', 'Lab Classes'):
            kind = 'T' if title.startswith('Theory') else 'L'
            times = [' '.join(c) for c in rows[1][1:]]
            for r in rows[2:]:
                room = ' '.join(r[0])
                for i, c in enumerate(r[1:]):
                    parsed = parse_routine_cell(c)
                    if parsed:
                        code, fac, time = parsed
                        routine.append((day, kind, time or times[i], room, code, fac))
        elif title == 'Exam Routine':
            dept = None
            for r in rows[1:]:
                first = ' '.join(r[0])
                if first in ('CSE', 'EEE'):
                    dept = first
                    continue
                m = re.match(r'Semester (\d+)', first)
                if dept == 'CSE' and m:
                    sem = int(m.group(1))
                    exam[sem] = [(d + 1, clean(' '.join(c)))
                                 for d, c in enumerate(r[1:9]) if c]
        elif title == 'Faculty Members':
            for r in rows[2:]:
                if len(r) >= 3 and r[1]:
                    faculty.append((clean(' '.join(r[1])).replace('Mr.M', 'Mr. M'),
                                    clean(' '.join(r[2]))))
    return routine, days, exam, faculty


def write_offer(semesters):
    out = ['typedef OfferCourse = (String code, String title, double credits);\n\n',
           'typedef SeatPart = (int sectionNo, int capacity);\n\n',
           'typedef OfferSemester = ({\n',
           '  int n,\n  List<OfferCourse> c,\n  Map<String, List<List<SeatPart>>> s,\n});\n\n',
           'const Map<int, OfferSemester> kOffer = {\n']
    for sem in sorted(semesters):
        n, courses, sections = semesters[sem]
        out.append(f'  {sem}: (\n    n: {n},\n    c: [\n')
        for code, title, cr in courses:
            out.append(f'      ({dart_str(code)}, {dart_str(title)}, {cr}),\n')
        out.append('    ],\n    s: {\n')
        for code, _, _ in courses:
            groups = sections.get(code, [[] for _ in range(n)])
            gs = ', '.join('[' + ', '.join(f'({no}, {cap})' for no, cap in g) + ']'
                           for g in groups)
            out.append(f'      {dart_str(code)}: [{gs}],\n')
        out.append('    },\n  ),\n')
    out.append('};\n')
    (OUT / 'offer_data.dart').write_text(''.join(out), encoding='utf-8')


def write_routine(routine, days):
    out = ['typedef RoutineRow = (\n  String day,\n  String type,\n  String time,\n'
           '  String room,\n  String course,\n  String faculty,\n);\n\n',
           'const List<String> kDays = [',
           ', '.join(dart_str(d) for d in days), '];\n\n',
           'const List<RoutineRow> kRoutine = [\n']
    for row in routine:
        out.append('  (' + ', '.join(dart_str(x) for x in row) + '),\n')
    out.append('];\n')
    (OUT / 'routine_data.dart').write_text(''.join(out), encoding='utf-8')


def write_exam(exam):
    out = ['const Map<int, List<(int day, String course)>> kExam = {\n']
    for sem in sorted(exam):
        items = ', '.join(f'({d}, {dart_str(c)})' for d, c in exam[sem])
        out.append(f'  {sem}: [{items}],\n')
    out.append('};\n')
    (OUT / 'exam_data.dart').write_text(''.join(out), encoding='utf-8')


def write_faculty(faculty):
    out = ['const List<(String name, String short)> kFaculty = [\n']
    for name, short in faculty:
        out.append(f'  ({dart_str(name)}, {dart_str(short)}),\n')
    out.append('];\n')
    (OUT / 'faculty_data.dart').write_text(''.join(out), encoding='utf-8')


def main():
    semesters = parse_offer()
    routine, days, exam, faculty = parse_docx()
    OUT.mkdir(parents=True, exist_ok=True)
    write_offer(semesters)
    write_routine(routine, days)
    write_exam(exam)
    write_faculty(faculty)

    print(f'semesters: {len(semesters)}')
    for sem, (n, courses, sections) in sorted(semesters.items()):
        missing = [c for c, _, _ in courses if c not in sections]
        empty = [c for c, g in sections.items() if any(not p for p in g)]
        print(f'  sem {sem:2}: {n} sections, {len(courses)} courses'
              + (f'  MISSING {missing}' if missing else '')
              + (f'  EMPTY-GROUP {empty}' if empty else ''))
    labs = sum(1 for r in routine if r[1] == 'L')
    print(f'routine slots: {len(routine)} ({labs} labs), days: {days}')
    print(f'exam semesters: {sorted(exam)}')
    print(f'faculty: {len(faculty)}')
    print(f'unparsed cells ({len(WEIRD)}): {WEIRD}')

    offered = {(c, no) for _, (_, _, s) in semesters.items()
               for c, groups in s.items() for g in groups for no, _ in g}
    unknown = sorted({r[4] for r in routine
                      if '(EEE)' not in r[4] and '.' in r[4]
                      and (r[4].split('.')[0], int(r[4].split('.')[1])) not in offered})
    print(f'routine sections not in offer list ({len(unknown)}): {unknown[:60]}')
    no_slot = sorted({f'{c}.{no}' for (c, no) in offered} -
                     {r[4] for r in routine})
    print(f'offered sections with no routine slot ({len(no_slot)}): {no_slot[:80]}')


if __name__ == '__main__':
    sys.exit(main())
