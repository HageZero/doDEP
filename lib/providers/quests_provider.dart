import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Quest {
  final String id;
  final String title;
  final int target;
  int progress;
  final IconData icon;
  final Color color;
  bool isCompleted;
  bool isRewardClaimed;
  final int reward;

  Quest({
    required this.id,
    required this.title,
    required this.target,
    this.progress = 0,
    required this.icon,
    required this.color,
    this.isCompleted = false,
    this.isRewardClaimed = false,
    required this.reward,
  });

  double get progressPercentage => progress / target;
}

class QuestsProvider extends ChangeNotifier {
  static final List<Quest> allQuestsPool = [
    Quest(
      id: 'spins',
      title: 'Сделать 10 прокруток',
      target: 10,
      icon: Icons.casino,
      color: Colors.blue,
      reward: 200,
    ),
    Quest(
      id: 'coins',
      title: 'Выиграть 1000 монет',
      target: 1000,
      icon: Icons.monetization_on,
      color: Colors.amber,
      reward: 500,
    ),
    Quest(
      id: 'jackpots',
      title: 'Получить 3 джекпота',
      target: 3,
      icon: Icons.stars,
      color: Colors.purple,
      reward: 300,
    ),
    Quest(
      id: 'bigwin',
      title: 'Выиграть за раз более 500 монет',
      target: 1,
      icon: Icons.emoji_events,
      color: Colors.green,
      reward: 400,
    ),
    Quest(
      id: 'freespins',
      title: 'Выбить бонуску',
      target: 1,
      icon: Icons.refresh,
      color: Colors.teal,
      reward: 250,
    ),
    Quest(
      id: 'bet',
      title: 'Поставить 500 монет за день',
      target: 500,
      icon: Icons.trending_up,
      color: Colors.orange,
      reward: 350,
    ),
    Quest(
      id: 'lucky',
      title: 'Поймать 2 одинаковых символа подряд',
      target: 2,
      icon: Icons.casino_outlined,
      color: Colors.pink,
      reward: 300,
    ),
    Quest(
      id: 'lose',
      title: 'Проиграть 5 раз подряд',
      target: 5,
      icon: Icons.sentiment_very_dissatisfied,
      color: Colors.redAccent,
      reward: 300,
    ),
  ];

  List<Quest> _quests = [];
  String? _lastQuestsDate;
  bool _bonusClaimedToday = false;
  bool get bonusClaimedToday => _bonusClaimedToday;

  List<Quest> get quests => _quests;

  bool get hasCompletedQuests => _quests.any((quest) => quest.isCompleted && !quest.isRewardClaimed);

  bool get allQuestsClaimedAndCompleted => _quests.isNotEmpty && _quests.every((q) => q.isCompleted && q.isRewardClaimed);

  QuestsProvider() {
    _loadOrGenerateDailyQuests();
  }

  Future<void> _loadOrGenerateDailyQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    _bonusClaimedToday = prefs.getBool('bonus_claimed_today') ?? false;
    final savedDate = prefs.getString('quests_date');
    if (savedDate == todayStr) {
      // Загружаем сохранённые задания
      final savedIds = prefs.getStringList('quests_ids') ?? [];
      _quests = savedIds.map((id) {
        final quest = allQuestsPool.firstWhere((q) => q.id == id, orElse: () => allQuestsPool.first);
        return Quest(
          id: quest.id,
          title: quest.title,
          target: quest.target,
          icon: quest.icon,
          color: quest.color,
          reward: quest.reward,
        );
      }).toList();
      for (var quest in _quests) {
        quest.progress = prefs.getInt('quest_${quest.id}_progress') ?? 0;
        quest.isCompleted = prefs.getBool('quest_${quest.id}_completed') ?? false;
        quest.isRewardClaimed = prefs.getBool('quest_${quest.id}_reward_claimed') ?? false;
      }
    } else {
      // Новый день — выбираем новые задания
      _quests = List<Quest>.from(allQuestsPool)..shuffle();
      _quests = _quests.take(3).map((q) => Quest(
        id: q.id,
        title: q.title,
        target: q.target,
        icon: q.icon,
        color: q.color,
        reward: q.reward,
      )).toList();
      await prefs.setString('quests_date', todayStr);
      await prefs.setStringList('quests_ids', _quests.map((q) => q.id).toList());
      for (var quest in _quests) {
        await prefs.setInt('quest_${quest.id}_progress', 0);
        await prefs.setBool('quest_${quest.id}_completed', false);
        await prefs.setBool('quest_${quest.id}_reward_claimed', false);
        quest.progress = 0;
        quest.isCompleted = false;
        quest.isRewardClaimed = false;
      }
      await prefs.setBool('bonus_claimed_today', false);
      _bonusClaimedToday = false;
    }
    notifyListeners();
  }

  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (var quest in _quests) {
        await prefs.setInt('quest_${quest.id}_progress', quest.progress);
        await prefs.setBool('quest_${quest.id}_completed', quest.isCompleted);
        await prefs.setBool('quest_${quest.id}_reward_claimed', quest.isRewardClaimed);
      }
    } catch (e) {
      debugPrint('Ошибка при сохранении прогресса заданий: $e');
    }
  }

  void updateQuestProgress(String questId, int value, {bool absolute = false}) {
    try {
      final quest = _quests.firstWhere((q) => q.id == questId);
      if (!quest.isCompleted) {
        if (absolute) {
          quest.progress = value.clamp(0, quest.target);
        } else {
          quest.progress = (quest.progress + value).clamp(0, quest.target);
        }
        if (quest.progress >= quest.target) {
          quest.isCompleted = true;
        } else {
          quest.isCompleted = false;
        }
        _saveProgress();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при обновлении прогресса задания: $e');
    }
  }

  void claimReward(String questId) {
    try {
      final quest = _quests.firstWhere((q) => q.id == questId);
      if (quest.isCompleted && !quest.isRewardClaimed) {
        quest.isRewardClaimed = true;
        _saveProgress();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Ошибка при получении награды: $e');
    }
  }

  void resetQuests() {
    try {
      for (var quest in _quests) {
        quest.progress = 0;
        quest.isCompleted = false;
        quest.isRewardClaimed = false;
      }
      _saveProgress();
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при сбросе заданий: $e');
    }
  }

  void resetQuestProgress(String questId) {
    try {
      final quest = _quests.firstWhere((q) => q.id == questId);
      quest.progress = 0;
      quest.isCompleted = false;
      quest.isRewardClaimed = false;
      _saveProgress();
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при сбросе прогресса задания $questId: $e');
    }
  }

  Future<void> setBonusClaimedToday(bool value) async {
    _bonusClaimedToday = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bonus_claimed_today', value);
    notifyListeners();
  }
} 