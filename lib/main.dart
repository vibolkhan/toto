import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToTo Capital',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1D5DEB),
          secondary: Color(0xFF506287),
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF131722),
            height: 1.05,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF131722),
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3B4C78),
            letterSpacing: 0.8,
          ),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF506287)),
        ),
      ),
      home: const MyHomePage(title: 'ToTo Capital'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedTab = 0;

  static const List<_ActivityItem> _activities = [
    _ActivityItem(
      title: 'Clocked Out',
      subtitle: 'Friday, Oct 21 • HQ Office',
      trailing: '17:05',
      icon: Icons.logout_rounded,
      iconColor: Color(0xFF1D5DEB),
      iconBackground: Color(0xFFE8EEFF),
    ),
    _ActivityItem(
      title: 'Clocked In',
      subtitle: 'Friday, Oct 21 • Remote',
      trailing: '09:12',
      icon: Icons.login_rounded,
      iconColor: Color(0xFF1D5DEB),
      iconBackground: Color(0xFFE8EEFF),
    ),
  ];

  static const List<_HistoryEntry> _historyEntries = [
    _HistoryEntry(
      dayLabel: 'TODAY',
      dateLabel: 'Monday, Oct 24',
      hours: '8h 12m',
      sessions: [
        _HistorySession(
          title: 'Clocked In',
          detail: '08:47 • HQ Office',
          status: 'On time',
          icon: Icons.login_rounded,
          iconColor: Color(0xFF1D5DEB),
          iconBackground: Color(0xFFE8EEFF),
        ),
        _HistorySession(
          title: 'Break Start',
          detail: '12:02 • Cafeteria',
          status: '32 min',
          icon: Icons.coffee_rounded,
          iconColor: Color(0xFFB9551E),
          iconBackground: Color(0xFFFFEFE4),
        ),
        _HistorySession(
          title: 'Clocked Out',
          detail: '17:18 • HQ Office',
          status: 'Overtime',
          icon: Icons.logout_rounded,
          iconColor: Color(0xFF16A34A),
          iconBackground: Color(0xFFEAF8EF),
        ),
      ],
    ),
    _HistoryEntry(
      dayLabel: 'FRIDAY',
      dateLabel: 'Friday, Oct 21',
      hours: '7h 53m',
      sessions: [
        _HistorySession(
          title: 'Clocked In',
          detail: '09:12 • Remote',
          status: 'Late',
          icon: Icons.login_rounded,
          iconColor: Color(0xFF1D5DEB),
          iconBackground: Color(0xFFE8EEFF),
        ),
        _HistorySession(
          title: 'Clocked Out',
          detail: '17:05 • HQ Office',
          status: 'Complete',
          icon: Icons.logout_rounded,
          iconColor: Color(0xFF16A34A),
          iconBackground: Color(0xFFEAF8EF),
        ),
      ],
    ),
    _HistoryEntry(
      dayLabel: 'THURSDAY',
      dateLabel: 'Thursday, Oct 20',
      hours: '8h 31m',
      sessions: [
        _HistorySession(
          title: 'Clocked In',
          detail: '08:31 • HQ Office',
          status: 'On time',
          icon: Icons.login_rounded,
          iconColor: Color(0xFF1D5DEB),
          iconBackground: Color(0xFFE8EEFF),
        ),
        _HistorySession(
          title: 'Clocked Out',
          detail: '17:14 • HQ Office',
          status: 'Complete',
          icon: Icons.logout_rounded,
          iconColor: Color(0xFF16A34A),
          iconBackground: Color(0xFFEAF8EF),
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      initialData: DateTime.now(),
      stream: Stream<DateTime>.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final page = switch (_selectedTab) {
          0 => _buildScanPage(context, now),
          1 => _buildHistoryPage(context, now),
          _ => _buildProfilePage(context, now),
        };

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: page),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                  child: _BottomNavBar(
                    selectedIndex: _selectedTab,
                    onSelected: (index) {
                      setState(() {
                        _selectedTab = index;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScanPage(BuildContext context, DateTime now) {
    final liveLocation = _formatLocation(now);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopHeader(title: widget.title),
          const SizedBox(height: 28),
          Text(
            _formatDate(now),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          _GreetingRow(name: 'Vibol', statusLabel: 'Not In'),
          const SizedBox(height: 12),
          _LocationRow(locationLabel: liveLocation),
          const SizedBox(height: 24),
          _ScanCard(now: now),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.timelapse_rounded,
                  iconColor: Color(0xFFB9551E),
                  label: 'OVERTIME',
                  value: '2.4h',
                  highlighted: false,
                ),
              ),
              SizedBox(width: 18),
              Expanded(
                child: _StatTile(
                  icon: Icons.event_note_rounded,
                  iconColor: Colors.white,
                  label: 'REMAINING PTO',
                  value: '12 Days',
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 34),
          _SectionHeader(
            title: 'Recent Activity',
            actionLabel: 'VIEW ALL',
            onTap: () {
              setState(() {
                _selectedTab = 1;
              });
            },
          ),
          const SizedBox(height: 14),
          ..._activities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ActivityTile(activity: activity),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryPage(BuildContext context, DateTime now) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopHeader(title: widget.title),
          const SizedBox(height: 28),
          Text('WORK HISTORY', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Text(
            'Track your attendance\nwith confidence',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Review clock-ins, breaks, and weekly totals in one place.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _HistorySummaryCard(
            weekRange: _formatWeekRange(now),
            totalHours: '38.5h',
            averageHours: '7.7h',
            attendanceRate: '96%',
          ),
          const SizedBox(height: 22),
          Row(
            children: const [
              Expanded(
                child: _StatTile(
                  icon: Icons.calendar_month_rounded,
                  iconColor: Color(0xFF1D5DEB),
                  label: 'THIS MONTH',
                  value: '17 Days',
                  highlighted: false,
                ),
              ),
              SizedBox(width: 18),
              Expanded(
                child: _StatTile(
                  icon: Icons.bolt_rounded,
                  iconColor: Colors.white,
                  label: 'BEST STREAK',
                  value: '6 Days',
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _SectionHeader(
            title: 'Attendance Log',
            actionLabel: 'EXPORT',
            onTap: () {},
          ),
          const SizedBox(height: 14),
          ..._historyEntries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _HistoryDayCard(entry: entry),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage(BuildContext context, DateTime now) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopHeader(title: widget.title),
          const SizedBox(height: 28),
          Text('PROFILE', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          Text(
            'Your workspace\nat a glance',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 22),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF163559), Color(0xFF2E608C)],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'V',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Vibol Khan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF131722),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Current timezone: ${_formatLocation(now)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dateTime) {
  const weekdays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  return '${weekdays[dateTime.weekday - 1]}, ${months[dateTime.month - 1]} ${dateTime.day}';
}

String _formatTime(DateTime dateTime) {
  final hours = dateTime.hour.toString().padLeft(2, '0');
  final minutes = dateTime.minute.toString().padLeft(2, '0');
  final seconds = dateTime.second.toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}

String _formatLocation(DateTime dateTime) {
  final zoneName = dateTime.timeZoneName.trim();
  if (zoneName.isNotEmpty) {
    return zoneName.toUpperCase();
  }

  final offset = dateTime.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.inHours.abs().toString().padLeft(2, '0');
  final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
  return 'UTC$sign$hours:$minutes';
}

String _formatWeekRange(DateTime dateTime) {
  final monday = dateTime.subtract(Duration(days: dateTime.weekday - 1));
  final sunday = monday.add(const Duration(days: 6));
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final start = '${months[monday.month - 1]} ${monday.day}';
  final end = '${months[sunday.month - 1]} ${sunday.day}';
  return '$start - $end';
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF163559), Color(0xFF2E608C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            'B',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF131722),
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.notifications_rounded,
            color: Color(0xFF506287),
            size: 28,
          ),
        ),
      ],
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({required this.name, required this.statusLabel});

  final String name;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Hello, $name',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE9EEFF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            statusLabel,
            style: const TextStyle(
              color: Color(0xFF1D5DEB),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.locationLabel});

  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 11, color: Color(0xFF1D5DEB)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'LIVE LOCATION: $locationLabel',
            style: const TextStyle(
              color: Color(0xFF1D5DEB),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanCard extends StatelessWidget {
  const _ScanCard({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(38),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Ready to start?',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF44557E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatTime(now),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF131722),
            ),
          ),
          const SizedBox(height: 24),
          const _QrPanel(),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(
                child: _MiniTimeStat(label: 'TODAY', value: '0.0h'),
              ),
              SizedBox(
                height: 42,
                child: VerticalDivider(color: Color(0xFFE4E7F0), thickness: 1),
              ),
              Expanded(
                child: _MiniTimeStat(label: 'THIS WEEK', value: '38.5h'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QrPanel extends StatelessWidget {
  const _QrPanel();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            colors: [Color(0xFFE4E4E4), Color(0xFFD4D4D4)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(34)),
                  gradient: RadialGradient(
                    colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                    radius: 0.55,
                    center: Alignment(0, -0.2),
                  ),
                ),
              ),
            ),
            const Positioned(
              top: 84,
              left: 0,
              right: 0,
              child: Divider(color: Color(0xFF1D5DEB), thickness: 2, height: 2),
            ),
            const Positioned(
              top: 20,
              left: 20,
              child: _CornerMark(top: true, left: true),
            ),
            const Positioned(
              top: 20,
              right: 20,
              child: _CornerMark(top: true, left: false),
            ),
            const Positioned(
              bottom: 20,
              left: 20,
              child: _CornerMark(top: false, left: true),
            ),
            const Positioned(
              bottom: 20,
              right: 20,
              child: _CornerMark(top: false, left: false),
            ),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 68,
                    color: Color(0xFF89A6DE),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'ALIGN QR CODE',
                    style: TextStyle(
                      color: Color(0xFF495E90),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'SAFE WORKING',
                  style: TextStyle(
                    color: Color(0xAAFFFFFF),
                    fontSize: 11,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerMark extends StatelessWidget {
  const _CornerMark({required this.top, required this.left});

  final bool top;
  final bool left;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: CustomPaint(
        painter: _CornerPainter(
          color: const Color(0xFF1D5DEB),
          top: top,
          left: left,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  const _CornerPainter({
    required this.color,
    required this.top,
    required this.left,
  });

  final Color color;
  final bool top;
  final bool left;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (top && left) {
      path
        ..moveTo(size.width, 0)
        ..lineTo(12, 0)
        ..quadraticBezierTo(0, 0, 0, 12)
        ..lineTo(0, size.height);
    } else if (top && !left) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width - 12, 0)
        ..quadraticBezierTo(size.width, 0, size.width, 12)
        ..lineTo(size.width, size.height);
    } else if (!top && left) {
      path
        ..moveTo(0, 0)
        ..lineTo(0, size.height - 12)
        ..quadraticBezierTo(0, size.height, 12, size.height)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height - 12)
        ..quadraticBezierTo(
          size.width,
          size.height,
          size.width - 12,
          size.height,
        )
        ..lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.top != top ||
        oldDelegate.left != left;
  }
}

class _MiniTimeStat extends StatelessWidget {
  const _MiniTimeStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF3B4C78),
            fontSize: 13,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF131722),
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HistorySummaryCard extends StatelessWidget {
  const _HistorySummaryCard({
    required this.weekRange,
    required this.totalHours,
    required this.averageHours,
    required this.attendanceRate,
  });

  final String weekRange;
  final String totalHours;
  final String averageHours;
  final String attendanceRate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Summary', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(weekRange, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(label: 'TOTAL HOURS', value: totalHours),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SummaryMetric(label: 'AVG / DAY', value: averageHours),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SummaryMetric(label: 'RATE', value: attendanceRate),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF506287),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              color: Color(0xFF131722),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.highlighted,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = highlighted
        ? const Color(0xFF3C6FE8)
        : const Color(0xFFF4F5FA);
    final labelColor = highlighted
        ? const Color(0xFFDDE6FF)
        : const Color(0xFF3B4C78);
    final valueColor = highlighted ? Colors.white : const Color(0xFF131722);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 22),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF131722),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: Color(0xFF1D5DEB),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});

  final _ActivityItem activity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: activity.iconBackground,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(activity.icon, color: activity.iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    color: Color(0xFF131722),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF506287),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.trailing,
            style: const TextStyle(
              color: Color(0xFF131722),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDayCard extends StatelessWidget {
  const _HistoryDayCard({required this.entry});

  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.dayLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3B4C78),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.dateLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF131722),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  entry.hours,
                  style: const TextStyle(
                    color: Color(0xFF1D5DEB),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...entry.sessions.asMap().entries.map((item) {
            final index = item.key;
            final session = item.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == entry.sessions.length - 1 ? 0 : 14,
              ),
              child: _HistorySessionTile(session: session),
            );
          }),
        ],
      ),
    );
  }
}

class _HistorySessionTile extends StatelessWidget {
  const _HistorySessionTile({required this.session});

  final _HistorySession session;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: session.iconBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(session.icon, color: session.iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.title,
                style: const TextStyle(
                  color: Color(0xFF131722),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                session.detail,
                style: const TextStyle(color: Color(0xFF506287), fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            session.status,
            style: const TextStyle(
              color: Color(0xFF3B4C78),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FB),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.qr_code_scanner_rounded,
            label: 'SCAN',
            selected: selectedIndex == 0,
            onTap: () => onSelected(0),
          ),
          _NavItem(
            icon: Icons.history_rounded,
            label: 'HISTORY',
            selected: selectedIndex == 1,
            onTap: () => onSelected(1),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'PROFILE',
            selected: selectedIndex == 2,
            onTap: () => onSelected(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF1D5DEB) : const Color(0xFF4D6189);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFD8E4FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityItem {
  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.dayLabel,
    required this.dateLabel,
    required this.hours,
    required this.sessions,
  });

  final String dayLabel;
  final String dateLabel;
  final String hours;
  final List<_HistorySession> sessions;
}

class _HistorySession {
  const _HistorySession({
    required this.title,
    required this.detail,
    required this.status,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String title;
  final String detail;
  final String status;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
}
