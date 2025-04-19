import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/flashcard.dart';
import '../widgets/flashcard_view.dart';

/// 퀴즈 모드: 자동/수동으로 플래시카드를 랜덤 순서로 보여주는 화면
class QuizSessionPage extends StatefulWidget {
  /// 선택된 덱 ID 리스트
  final List<String> deckIds;
  /// 카드 전환 간격 (초)
  final int intervalSeconds;
  const QuizSessionPage({
    Key? key,
    required this.deckIds,
    required this.intervalSeconds,
  }) : super(key: key);

  @override
  State<QuizSessionPage> createState() => _QuizSessionPageState();
}

class _QuizSessionPageState extends State<QuizSessionPage> {
  late Box<Flashcard> _cardBox;
  late List<Flashcard> _cards;
  int _currentIndex = 0;
  Timer? _timer;
  bool _isPlaying = true;
  bool _isFinished = false;
  bool _showFront = true;

  /// 탭 시 바로 다음 카드로 이동 (타이머 취소 및 재설정)
  void _onTap() {
    if (_cards.isEmpty || _isFinished) return;
    _timer?.cancel();
    _advanceCard();
  }

  @override
  void initState() {
    super.initState();
    _cardBox = Hive.box<Flashcard>('flashcards');
    // 선택된 덱의 모든 카드 로드
    _cards = _cardBox.values
        .where((c) => widget.deckIds.contains(c.deckId))
        .toList();
    _cards.shuffle();
    // 첫 카드에 front부터 시작
    _showFront = true;
    // 자동 재생 시작
    _startTimer();
  }

  /// 자동 재생용 3초 타이머를 설정하고, 만료 시 카드 진행
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(Duration(seconds: widget.intervalSeconds), _handleTimerTick);
    setState(() => _isPlaying = true);
  }

  /// 자동 재생 일시정지
  void _pauseTimer() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
  }

  /// 재생/일시정지 토글
  void _togglePlayPause() {
    if (_isPlaying) {
      _pauseTimer();
    } else {
      // 세션이 끝나지 않았다면 재생 재개
      if (!_isFinished) _startTimer();
    }
  }

  /// 타이머 만료 시 호출: 자동 진행 (front/back 분리)
  void _handleTimerTick() {
    if (_isPlaying && !_isFinished) {
      if (_showFront) {
        // front를 보여준 후, back 표시
        setState(() => _showFront = false);
        _startTimer();
      } else {
        // back을 보여준 후, 다음 카드로
        _advanceCard();
      }
    }
  }

  /// 모든 카드를 본 후 세션 종료 처리
  void _finishSession() {
    _timer?.cancel();
    setState(() {
      _isFinished = true;
    });
  }

  /// 사용자가 탭하거나 타이머 만료 시 호출: 다음 카드 또는 세션 종료
  void _advanceCard() {
    if (_cards.isEmpty) return;
    if (_currentIndex < _cards.length - 1) {
      setState(() {
        _currentIndex += 1;
        _showFront = true;
      });
      // 다음 타이머 재설정
      if (_isPlaying) _startTimer();
    } else {
      _finishSession();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 카드가 아예 없는 경우
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('퀴즈 모드')),
        body: const Center(child: Text('선택된 덱에 카드가 없습니다.')),
      );
    }
    // 세션 완료된 경우
    if (_isFinished) {
      return Scaffold(
        appBar: AppBar(title: const Text('퀴즈 모드')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('훌륭해요! 총 ${_cards.length}개의 카드를 보았습니다.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('완료'),
              ),
            ],
          ),
        ),
      );
    }
    // 퀴즈 진행 중인 경우: front 또는 back 단일 뷰 + 인덱스 표시
    final card = _cards[_currentIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('퀴즈 모드'),
        actions: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            tooltip: _isPlaying ? '일시정지' : '재생',
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: '종료',
            onPressed: () {
              _pauseTimer();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_currentIndex + 1}/${_cards.length} - ${_showFront ? 'Front' : 'Back'}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FlashcardView(
                  text: _showFront ? card.front : card.back,
                  imageBytes: _showFront ? card.frontImageBytes : card.backImageBytes,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}