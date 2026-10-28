// Hand-written reference data. The university documents do not include
// notices or FAQ answers, so those are sensible defaults for the demo.
// kPrereq is transcribed from the official course catalog (166 credits).

/// Course -> courses that must be passed first, from the course catalog.
/// Courses with no prerequisite (and labs printed with a blank cell) are
/// left out.
///
/// CSE 464 and CSE 466 have no prerequisite on purpose: the catalog names
/// courses for them (CSE 445, CSE 227) that exist nowhere, and the team chose
/// to skip them.
const Map<String, List<String>> kPrereq = {
  // Language and mathematics
  'ENG 111': ['AA 099'],
  'MATH 107': ['AA 150'],
  'MATH 203': ['MATH 107'],
  'MATH 205': ['MATH 107'],
  'MATH 207': ['MATH 107'],
  'MATH 301': ['MATH 107'],
  // Interdisciplinary
  'CSE 223': ['CSE 215'],
  // Program core
  'CSE 113': ['CSE 111'],
  'CSE 123': ['CSE 113'],
  'CSE 115': ['CSE 113'],
  'CSE 211': ['CSE 113'],
  'CSE 221': ['CSE 211', 'CSE 123'],
  'CSE 225': ['CSE 123'],
  'CSE 242': ['CSE 225', 'CSE 123'],
  'CSE 311': ['CSE 123'],
  'CSE 315': ['CSE 215', 'CSE 113'],
  'CSE 317': ['CSE 211', 'CSE 123'],
  'CSE 319': ['CSE 123', 'CSE 115', 'CSE 211'],
  'CSE 321': ['CSE 221'],
  'CSE 325': ['CSE 313'],
  'CSE 327': ['CSE 115', 'CSE 221', 'CSE 315'],
  'CSE 342': ['CSE 315'],
  'CSE 411': ['CSE 123', 'CSE 211'],
  'CSE 463': ['CSE 225', 'CSE 327'],
  'CSE 443': ['CSE 327'],
  // Options
  'CSE 301': ['CSE 325', 'CSE 311', 'CSE 225'],
  'CSE 429': ['CSE 225', 'CSE 221'],
  'CSE 439': ['CSE 321'],
  'CSE 455': ['CSE 225', 'CSE 327'],
  'CSE 457': ['CSE 325'],
  'CSE 459': ['CSE 325'],
  'ETE 309': ['CSE 313'],
  'ETE 310': ['CSE 313'],
  'ETE 435': ['CSE 313'],
  'ETE 436': ['CSE 313'],
  'EEE 213': ['EEE 111'],
  'ETE 317': ['CSE 215', 'EEE 213'],
};

/// Seed notices: (title, body, category, pinned, days ago).
const List<(String, String, String, bool, int)> kNotices = [
  (
    'Fall 2026 advising is open',
    'Regular advising for Fall 2026 is now open in the EDU Advising app. '
        'Check your accounts clearance first, then pick one section of your '
        'semester and confirm your courses. Seats are given first come, '
        'first served.',
    'Advising',
    true,
    1,
  ),
  (
    'Accounts clearance before advising',
    'Only students with Cleared or Special consideration status can advise. '
        'If you paid through the E-payment portal, wait at least 30 minutes. '
        'If you paid at the bank, upload the deposit slip and wait at least '
        '15 minutes.',
    'Accounts',
    true,
    2,
  ),
  (
    'Extra course requests',
    'After regular advising, vacant seats in junior and senior sections '
        'can be requested from the Extra course tab. Every request needs a '
        'reason and is reviewed by the course faculty and the Dean.',
    'Advising',
    false,
    3,
  ),
  (
    'Fall 2026 class routine published',
    'The undergraduate routine for all CSE and EEE semesters is available '
        'under Menu > Classes > Class routine. Choose your semester and '
        'section to see your weekly timetable, labs included.',
    'Academic',
    false,
    5,
  ),
  (
    'Final exam routine',
    'The Fall 2026 final exam routine (Day 1 to Day 8) is available under '
        'Menu > Classes > Exam routine. You can download your semester as a '
        'PDF.',
    'Exam',
    false,
    6,
  ),
  (
    'Payment deadline without late fee',
    'Pay the first installment of the Fall 2026 tuition fee by the deadline '
        'shown on the Advising Information Portal to avoid a late fee.',
    'Accounts',
    false,
    9,
  ),
];

/// Seed FAQs: (question, answer, category, keywords).
const List<(String, String, String, List<String>)> kFaq = [
  (
    'How do I do my advising?',
    'Open Menu > Advising. The app checks your accounts clearance first. If '
        'you are Cleared or have Special consideration, tap Proceed to '
        'Advising, open one section of your semester, tick your courses (or '
        'Select all) and press Confirm.',
    'Advising',
    ['advising', 'advise', 'how', 'register', 'enroll', 'enrol'],
  ),
  (
    'Why can I not advise?',
    'Advising needs two things: accounts clearance (Cleared or Special '
        'consideration) and the regular advising window to be open. The '
        'clearance page shows your status and what to do next.',
    'Advising',
    ['cannot', "can't", 'locked', 'blocked', 'not allowed', 'why'],
  ),
  (
    'What is accounts clearance?',
    'Accounts checks that your dues are paid. Cleared means you may '
        'proceed. Special consideration means you applied or were granted '
        'special consideration and may also proceed. Not cleared means you '
        'must pay or upload your bank deposit slip first.',
    'Accounts',
    ['clearance', 'cleared', 'accounts', 'dues', 'special consideration'],
  ),
  (
    'I paid but I am still not cleared.',
    'If you paid through the E-payment portal, wait at least 30 minutes. If '
        'you paid at the bank, upload your deposit slip with the Upload '
        'Deposit Form and wait at least 15 minutes. Then check again.',
    'Accounts',
    ['paid', 'payment', 'deposit', 'bank', 'slip', 'still'],
  ),
  (
    'Can I take courses from two sections?',
    'No. Once you enroll in any course of a section, the other sections of '
        'your semester become view-only. Only faculty or the Dean can move '
        'you.',
    'Advising',
    ['two sections', 'another section', 'change section', 'section lock', 'switch'],
  ),
  (
    'Can I drop a course?',
    'Students cannot drop regular courses. Ask the course faculty or the '
        'Dean. For an extra course you can send a drop request from the '
        'Extra course tab.',
    'Advising',
    ['drop', 'remove', 'cancel course', 'withdraw course'],
  ),
  (
    'The section is full. What now?',
    'Tap Join waitlist. Your place is decided by the server time of your '
        'request. When a seat frees up, the first student on the waitlist is '
        'enrolled automatically and gets a notification.',
    'Advising',
    ['full', 'waitlist', 'wait list', 'no seat', 'seats'],
  ),
  (
    'How do extra course requests work?',
    'When the Extra course window is open, vacant seats from other '
        'semesters appear in the Extra course tab. Send a request with a '
        'reason. The course faculty or the Dean approves or rejects it. You '
        'can withdraw a request while it is Pending.',
    'Advising',
    ['extra', 'open credit', 'retake', 'improvement', 'request'],
  ),
  (
    'What if two courses clash?',
    'If two courses meet at the same time, or their final exams are on the '
        'same day, the app shows a warning before you confirm. You can '
        'cancel, or accept the warning and take the courses anyway. It is '
        'your decision.',
    'Advising',
    ['clash', 'conflict', 'same time', 'overlap', 'exam day'],
  ),
  (
    'Is there a credit limit?',
    'The app does not stop you at a credit limit. How many credits you can '
        'take may depend on your faculty, so check with them.',
    'Advising',
    ['credit', 'credits', 'limit', 'maximum', 'how many'],
  ),
  (
    'What is a prerequisite?',
    'A course you must pass before taking another course. Use Menu > '
        'Reference > Prerequisite checker to see the prerequisites of any '
        'course and whether you have passed them.',
    'Academic',
    ['prerequisite', 'prereq', 'pre-requisite', 'requirement'],
  ),
  (
    'Where is my class routine?',
    'Menu > Classes > Class routine. "My routine" shows your enrolled '
        'courses; you can also view the routine of any semester and section. '
        'The number after the dot is the section, e.g. CSE 443.3 is section 3.',
    'Academic',
    ['routine', 'schedule', 'timetable', 'class time', 'room'],
  ),
  (
    'When are the final exams?',
    'Menu > Classes > Exam routine shows Day 1 to Day 8 for every semester. '
        'You can download your semester as a PDF.',
    'Exam',
    ['exam', 'final', 'test', 'day'],
  ),
  (
    'How do I pay my fees?',
    'Pay through the E-payment Portal, or pay at the bank and upload the '
        'deposit slip. Links are on the clearance page.',
    'Accounts',
    ['fee', 'fees', 'pay', 'tuition', 'epayment', 'e-payment', 'bkash'],
  ),
];
