import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../widgets/edu_app_bar.dart';
import '../advising/clearance_screen.dart';
import '../classes/class_routine_screen.dart';
import '../classes/exam_routine_screen.dart';
import '../classes/my_classes_screen.dart';
import '../classes/offer_list_screen.dart';
import '../common/faq_chatbot_screen.dart';
import '../common/notice_board_screen.dart';
import '../reference/faculty_directory_screen.dart';
import '../reference/prereq_checker_screen.dart';
import '../reports/finance_screen.dart';
import '../reports/transcript_screen.dart';

class MenuItemData {
  const MenuItemData(this.icon, this.title, this.subtitle, this.page);

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() page;
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  static final List<(String, List<MenuItemData>)> groups = [
    (
      'Advising',
      [
        MenuItemData(Icons.how_to_reg_outlined, 'Advising',
            'Clearance check, regular advising, extra course, waitlist',
            () => const ClearanceScreen()),
        MenuItemData(Icons.list_alt_outlined, 'Course offer list',
            'All semesters, sections and live seats', () => const OfferListScreen()),
      ],
    ),
    (
      'Classes',
      [
        MenuItemData(Icons.class_outlined, 'My classes', 'Courses you are enrolled in',
            () => const MyClassesScreen()),
        MenuItemData(Icons.calendar_view_week_outlined, 'Class routine',
            'Weekly timetable by section, labs included', () => const ClassRoutineScreen()),
        MenuItemData(Icons.event_note_outlined, 'Exam routine', 'Final exams, Day 1 to Day 8',
            () => const ExamRoutineScreen()),
      ],
    ),
    (
      'Reports & Transcripts',
      [
        MenuItemData(Icons.workspace_premium_outlined, 'Transcript', 'Grades and CGPA',
            () => const TranscriptScreen()),
      ],
    ),
    (
      'Finance',
      [
        MenuItemData(Icons.account_balance_wallet_outlined, 'Finance summary',
            'Fees, waiver, payments and dues', () => const FinanceScreen()),
      ],
    ),
    (
      'Communication',
      [
        MenuItemData(Icons.campaign_outlined, 'Notice board', 'Announcements from the university',
            () => const NoticeBoardScreen()),
        MenuItemData(Icons.smart_toy_outlined, 'FAQ chatbot', 'Ask about advising, fees, exams',
            () => const FaqChatbotScreen()),
      ],
    ),
    (
      'Reference',
      [
        MenuItemData(Icons.account_tree_outlined, 'Prerequisite checker',
            'What you need before a course', () => const PrereqCheckerScreen()),
        MenuItemData(Icons.groups_outlined, 'Faculty directory', 'Search by name or short form',
            () => const FacultyDirectoryScreen()),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MenuList(groups: groups);
  }
}

class MenuList extends StatelessWidget {
  const MenuList({super.key, required this.groups});

  final List<(String, List<MenuItemData>)> groups;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final (title, items) in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
            child: Text(title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted)),
          ),
          Material(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(indent: 60),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.tint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(items[i].icon, color: AppColors.primary, size: 22),
                    ),
                    title: Text(items[i].title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(items[i].subtitle, style: const TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                    onTap: () => openPage(context, items[i].page()),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
