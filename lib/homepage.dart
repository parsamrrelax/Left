import 'package:flutter/material.dart';
import 'package:Left/services/days.dart';
import 'package:Left/UI/dot_pattern.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Left/models/user_data.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late Box<UserData> userDataBox;
  UserData? userData;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    userDataBox = await Hive.openBox<UserData>('userData');
    setState(() {
      userData = userDataBox.get('user');
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final daysUntilNextYear = getDaysUntilNextYear();
    final daysPassed = dateDifference(now, DateTime(now.year, 1, 1));
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dayOfMonth = now.day;

    // Calculate age and lifespan if birthday is available
    final age = userData?.birthday != null
        ? ((now.difference(userData!.birthday!).inDays) / 365).floor()
        : 24;
    final lifespan = userData?.expectedLifespan ?? 80;
    final yearsLeft = lifespan - age;

    final List<Widget> pages = [
      if (_isScreenVisible('year'))
        _wrapPage(
          child: _buildYearView(daysUntilNextYear, daysPassed),
          title: 'Year View',
          defaultScreenId: 'year',
        ),
      if (_isScreenVisible('month'))
        _wrapPage(
          child: _buildMonthView(dayOfMonth, daysInMonth),
          title: 'Month View',
          defaultScreenId: 'month',
        ),
      if (userData?.birthday != null && _isScreenVisible('birthday'))
        _wrapPage(
          child: _buildBirthdayView(),
          title: 'Birthday View',
          defaultScreenId: 'birthday',
        ),
      if (_isScreenVisible('life_months'))
        _wrapPage(
          child: _buildLifeViewMonths(age, lifespan),
          title: 'Life View (Months)',
          defaultScreenId: 'life_months',
        ),
      if (_isScreenVisible('life_years'))
        _wrapPage(
          child: _buildLifeViewYears(yearsLeft, lifespan),
          title: 'Life View (Years)',
          defaultScreenId: 'life_years',
        ),
      ...(userData?.importantDates ?? []).map((date) {
        return _wrapPage(
          child: _buildImportantDateView(date),
          title: date.title,
          customDate: date,
        );
      }),
    ];

    return SafeArea(
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          children: pages,
        ),
      ),
    );
  }

  Widget _buildYearView(int daysUntilNextYear, int daysPassed) {
    final now = DateTime.now();
    final daysLeft = isLeapYear(now.year) ? 366 : 365 - daysPassed;
    final persentLeftTillNextYear =
        (daysLeft / (isLeapYear(now.year) ? 366 : 365)) * 100;
    final currentYear = DateFormat('yyyy').format(now);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DotPattern(
          days: isLeapYear(now.year) ? 366 : 365,
          startDay: daysPassed,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _addNewImportantDate(context),
                    icon: Icon(
                      Icons.add,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  IconButton(
                    onPressed: _showManageScreensDialog,
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              Text(
                '$currentYear: $daysUntilNextYear days / ${persentLeftTillNextYear.round()}% Left',
                style: TextStyle(
                    fontSize: 18, color: Colors.white.withOpacity(0.4)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthView(int dayOfMonth, int daysInMonth) {
    final now = DateTime.now();
    final persentLeftTillNextMonth =
        (daysInMonth - dayOfMonth) / daysInMonth * 100;
    final currentMonthName = DateFormat('MMMM').format(now);

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DotPattern(
          days: daysInMonth,
          startDay: dayOfMonth,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _addNewImportantDate(context),
                    icon: Icon(
                      Icons.add,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  IconButton(
                    onPressed: _showManageScreensDialog,
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              Text(
                'Day ${now.day} of $currentMonthName / ${persentLeftTillNextMonth.round()}% Left',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBirthdayView() {
    final now = DateTime.now();
    final nextBirthday = DateTime(
      now.year +
          (now.month > userData!.birthday!.month ||
                  (now.month == userData!.birthday!.month &&
                      now.day >= userData!.birthday!.day)
              ? 1
              : 0),
      userData!.birthday!.month,
      userData!.birthday!.day,
    );
    final daysUntilBirthday = nextBirthday.difference(now).inDays;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DotPattern(
          days: 365,
          startDay: 365 - daysUntilBirthday,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _addNewImportantDate(context),
                    icon: Icon(
                      Icons.add,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  IconButton(
                    onPressed: _showManageScreensDialog,
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              Text(
                '${userData!.birthday!.day}/${userData!.birthday!.month}: $daysUntilBirthday days Left',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImportantDateView(ImportantDate date) {
    final now = DateTime.now();
    final nextOccurrence = DateTime(
      now.year +
          (now.month > date.date.month ||
                  (now.month == date.date.month && now.day >= date.date.day)
              ? 1
              : 0),
      date.date.month,
      date.date.day,
    );
    final daysUntil = nextOccurrence.difference(now).inDays;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DotPattern(
          days: 365,
          startDay: 365 - daysUntil,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _addNewImportantDate(context),
                    icon: Icon(
                      Icons.add,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  IconButton(
                    onPressed: _showManageScreensDialog,
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              Text(
                '${date.title}: $daysUntil Left',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifeViewMonths(int age, int lifespan) {
    final currentAgeMonths = age * 12;
    final expectedLifespanMonths = lifespan * 12;
    final monthsLeft = expectedLifespanMonths - currentAgeMonths;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DotPattern(
          days: expectedLifespanMonths,
          startDay: currentAgeMonths,
          isYearView: false,
          isMonthView: true,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _addNewImportantDate(context),
                    icon: Icon(
                      Icons.add,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  IconButton(
                    onPressed: _showManageScreensDialog,
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              Text(
                'life: $monthsLeft months Left',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifeViewYears(int yearsLeft, int lifespan) {
    final age = lifespan - yearsLeft;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DotPattern(
          days: lifespan,
          startDay: age,
          isYearView: true,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _addNewImportantDate(context),
                    icon: Icon(
                      Icons.add,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  IconButton(
                    onPressed: _showManageScreensDialog,
                    icon: Icon(
                      Icons.settings_outlined,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
              Text(
                'life: $yearsLeft years Left',
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.4),
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addNewImportantDate(BuildContext context) async {
    final titleController = TextEditingController();
    DateTime? selectedDate;

    final bool? shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add important date'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g., Anniversary',
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                selectedDate != null
                    ? DateFormat('MMM d').format(selectedDate!)
                    : 'Select date',
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  selectedDate = DateTime(
                    DateTime.now().year,
                    picked.month,
                    picked.day,
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && selectedDate != null) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (shouldAdd == true && selectedDate != null) {
      final newDate = ImportantDate(
        title: titleController.text,
        date: selectedDate!,
      );

      setState(() {
        userData?.importantDates.add(newDate);
      });

      await userDataBox.put('user', userData!);
    }
  }

  bool _isScreenVisible(String screenId) {
    final hidden = userData?.hiddenScreens ?? [];
    return !hidden.contains(screenId);
  }

  Widget _wrapPage({
    required Widget child,
    required String title,
    String? defaultScreenId,
    ImportantDate? customDate,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => _showPageOptionsDialog(
        title: title,
        defaultScreenId: defaultScreenId,
        customDate: customDate,
      ),
      child: child,
    );
  }

  void _showPageOptionsDialog({
    required String title,
    String? defaultScreenId,
    ImportantDate? customDate,
  }) {
    final totalVisibleScreens = _calculateVisibleScreensCount();
    final canRemove = totalVisibleScreens > 1;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(
            canRemove
                ? 'Would you like to remove this screen?'
                : 'This is the only remaining screen. You must have at least one active screen.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (canRemove)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _removeScreen(
                    defaultScreenId: defaultScreenId,
                    customDate: customDate,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
                child: const Text('Remove'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showManageScreensDialog();
              },
              child: const Text('Manage Screens'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeScreen({
    String? defaultScreenId,
    ImportantDate? customDate,
  }) async {
    if (userData == null) return;

    if (defaultScreenId != null) {
      final hidden = List<String>.from(userData!.hiddenScreens ?? []);
      if (!hidden.contains(defaultScreenId)) {
        hidden.add(defaultScreenId);
      }
      setState(() {
        userData!.hiddenScreens = hidden;
      });
    } else if (customDate != null) {
      setState(() {
        userData!.importantDates.remove(customDate);
      });
    }

    await userDataBox.put('user', userData!);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screen removed'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showManageScreensDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasBirthday = userData?.birthday != null;

            Widget buildToggleItem({
              required String title,
              required String screenId,
              required bool isEnabled,
            }) {
              final isLastScreen = _calculateVisibleScreensCount() == 1 && isEnabled;

              return CheckboxListTile(
                title: Text(title),
                value: isEnabled,
                onChanged: isLastScreen
                    ? null
                    : (bool? checked) async {
                        if (checked == null) return;
                        final hidden = List<String>.from(userData!.hiddenScreens ?? []);
                        if (checked) {
                          hidden.remove(screenId);
                        } else {
                          hidden.add(screenId);
                        }

                        setState(() {
                          userData!.hiddenScreens = hidden;
                        });

                        setDialogState(() {});

                        await userDataBox.put('user', userData!);
                      },
              );
            }

            return AlertDialog(
              title: const Text('Manage Screens'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildToggleItem(
                    title: 'Year View',
                    screenId: 'year',
                    isEnabled: _isScreenVisible('year'),
                  ),
                  buildToggleItem(
                    title: 'Month View',
                    screenId: 'month',
                    isEnabled: _isScreenVisible('month'),
                  ),
                  if (hasBirthday)
                    buildToggleItem(
                      title: 'Birthday View',
                      screenId: 'birthday',
                      isEnabled: _isScreenVisible('birthday'),
                    ),
                  buildToggleItem(
                    title: 'Life View (Months)',
                    screenId: 'life_months',
                    isEnabled: _isScreenVisible('life_months'),
                  ),
                  buildToggleItem(
                    title: 'Life View (Years)',
                    screenId: 'life_years',
                    isEnabled: _isScreenVisible('life_years'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  int _calculateVisibleScreensCount() {
    int count = 0;
    if (_isScreenVisible('year')) count++;
    if (_isScreenVisible('month')) count++;
    if (userData?.birthday != null && _isScreenVisible('birthday')) count++;
    if (_isScreenVisible('life_months')) count++;
    if (_isScreenVisible('life_years')) count++;
    count += userData?.importantDates.length ?? 0;
    return count;
  }
}
