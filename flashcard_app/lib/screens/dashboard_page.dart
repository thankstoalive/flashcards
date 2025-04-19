import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart';
// Conditional import for NotificationService: IO implementation or stub on web
import '../services/notification_service_io.dart'
    if (dart.library.html) '../services/notification_service_stub.dart';
import '../main.dart';

import '../models/deck.dart';
import '../models/flashcard.dart';

/// 통계·대시보드 화면
class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final deckBox = Hive.box<Deck>('decks');
    return ValueListenableBuilder<Box<Flashcard>>(
      valueListenable: Hive.box<Flashcard>('flashcards').listenable(),
      builder: (context, cardBox, _) {
        final totalDecks = deckBox.length;
        final totalCards = cardBox.length;
        final now = DateTime.now();
        final dueCards = cardBox.values.where((c) => !c.due.isAfter(now)).length;
        // Grade distribution
        final gradeCounts = <int, int>{1: 0, 2: 0, 3: 0};
        double sumEase = 0;
        int sumInterval = 0;
        for (var c in cardBox.values) {
          gradeCounts[c.lastGrade] = (gradeCounts[c.lastGrade] ?? 0) + 1;
          sumEase += c.easeFactor;
          sumInterval += c.interval;
        }
        final avgEase = totalCards > 0 ? sumEase / totalCards : 0.0;
        final avgInterval = totalCards > 0 ? sumInterval / totalCards : 0.0;
        return Scaffold(
          appBar: AppBar(
            title: const Text('통계·대시보드'),
            actions: [
              // 알림 테스트 버튼
              IconButton(
                icon: const Icon(Icons.notifications_active),
                tooltip: '알림 테스트',
                onPressed: () async {
                  await NotificationService().showTestNotification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('테스트 알림을 실행했습니다. 지원 플랫폼에서 확인하세요.'),
                    ),
                  );
                },
              ),
              // 테마 전환 버튼
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeNotifier,
                builder: (_, mode, __) {
                  return IconButton(
                    icon: Icon(
                      mode == ThemeMode.light
                          ? Icons.dark_mode
                          : Icons.light_mode,
                    ),
                    tooltip: '테마 전환',
                    onPressed: () {
                      themeNotifier.value = mode == ThemeMode.light
                          ? ThemeMode.dark
                          : ThemeMode.light;
                    },
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('총 덱 수: $totalDecks', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('총 카드 수: $totalCards', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('복습 대상 카드 수: $dueCards', style: Theme.of(context).textTheme.titleMedium),
                const Divider(height: 32),
                Text('평균 Interval: ${avgInterval.toStringAsFixed(1)} 일', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('평균 EaseFactor: ${avgEase.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium),
                const Divider(height: 32),
                Text('최근 학습 난이도 분포', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Hard (1): ${gradeCounts[1]}', style: Theme.of(context).textTheme.bodyMedium),
                Text('Normal (2): ${gradeCounts[2]}', style: Theme.of(context).textTheme.bodyMedium),
                Text('Easy (3): ${gradeCounts[3]}', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        );
      },
    );
  }
}