import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/features/user/services/me_api_service.dart';
import 'package:purewill/features/habit/services/motivation_service.dart';
import 'package:purewill/features/nofap/services/nofap_session_api_service.dart';
import 'package:purewill/features/nofap/models/motivation_model.dart';
import 'package:purewill/features/nofap/models/nofap_session_model.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';

enum NofapStatus { initial, loading, success, failure }

class NofapState {
  final NofapStatus status;
  final String? errorMessage;
  final NofapSessionModel? currentSession;
  final List<NofapSessionModel> meSessions;
  final int? apiCurrentStreak;
  final int? apiBestStreak;
  final int? apiTotalRelapseCount;
  final MotivationModel? motivation;
  final List<String> benefits;

  const NofapState({
    this.status = NofapStatus.initial,
    this.errorMessage,
    this.currentSession,
    this.meSessions = const [],
    this.apiCurrentStreak,
    this.apiBestStreak,
    this.apiTotalRelapseCount,
    this.motivation,
    this.benefits = const [
      'Increased energy and motivation',
      'Better focus and concentration',
      'Improved self-confidence',
      'Better sleep quality',
      'Enhanced social interactions',
    ],
  });

  bool get isHabitStarted => currentSession?.isActive == true;

  int get currentStreak {
    final apiValue = apiCurrentStreak;
    if (apiValue != null) return apiValue;

    final session = currentSession;
    if (session == null || !session.isActive) return 0;

    return _dateOnly(
      nowInIndonesia(),
    ).difference(_dateOnly(session.startDate)).inDays;
  }

  int get longestStreak {
    final apiValue = apiBestStreak;
    if (apiValue != null) return apiValue;

    final sessions = meSessions;
    if (sessions.isEmpty) return 0;

    var longest = 0;
    for (final session in sessions) {
      final endDate = session.endDate ?? nowInIndonesia();
      final days = _dateOnly(
        endDate,
      ).difference(_dateOnly(session.startDate)).inDays;
      if (days > longest) {
        longest = days;
      }
    }

    return longest;
  }

  int get totalRelapses {
    final apiValue = apiTotalRelapseCount;
    if (apiValue != null) return apiValue;

    if (meSessions.isEmpty) return 0;
    return meSessions.where((session) => session.endDate != null).length;
  }

  List<DateTime> get successDays {
    final session = currentSession;
    if (session == null || !session.isActive) return const [];

    final now = _dateOnly(nowInIndonesia());
    var cursor = _dateOnly(session.startDate);
    final days = <DateTime>[];

    while (!cursor.isAfter(now)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    return days;
  }

  NofapState copyWith({
    NofapStatus? status,
    String? errorMessage,
    NofapSessionModel? currentSession,
    List<NofapSessionModel>? meSessions,
    int? apiCurrentStreak,
    int? apiBestStreak,
    int? apiTotalRelapseCount,
    MotivationModel? motivation,
    bool clearCurrentSession = false,
  }) {
    return NofapState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      currentSession: clearCurrentSession
          ? null
          : currentSession ?? this.currentSession,
      meSessions: meSessions ?? this.meSessions,
      apiCurrentStreak: apiCurrentStreak ?? this.apiCurrentStreak,
      apiBestStreak: apiBestStreak ?? this.apiBestStreak,
      apiTotalRelapseCount: apiTotalRelapseCount ?? this.apiTotalRelapseCount,
      motivation: motivation ?? this.motivation,
      benefits: benefits,
    );
  }

  static DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

class NofapViewModel extends StateNotifier<NofapState> {
  final NofapSessionApiService _apiService;
  final MeApiService _meApiService;
  final MotivationService _motivationService;

  NofapViewModel(this._apiService, this._meApiService, this._motivationService)
    : super(const NofapState());

  Future<void> loadCurrentSession() async {
    state = state.copyWith(status: NofapStatus.loading, errorMessage: null);

    try {
      final currentResponse = _apiService.getCurrentSession();
      final streakResponse = _apiService.getStreakSummary();
      final relapseResponse = _apiService.getRelapseCount();
      final meSessionsFuture = _loadMeSessions();
      final motivationFuture = _motivationService.getRandomMotivation();

      final results = await Future.wait([
        currentResponse,
        streakResponse,
        relapseResponse,
        meSessionsFuture,
        motivationFuture,
      ]);

      final currentResponseData = results[0] as Map<String, dynamic>;
      final streakResponseData = results[1] as Map<String, dynamic>;
      final relapseResponseData = results[2] as Map<String, dynamic>;
      final currentData = currentResponseData['data'];
      final streakData = streakResponseData['data'];
      final relapseData = relapseResponseData['data'];
      final meSessions = results[3] as List<NofapSessionModel>;
      final motivation = results[4] as MotivationModel?;

      state = state.copyWith(
        status: NofapStatus.success,
        currentSession: currentData is Map<String, dynamic>
            ? NofapSessionModel.fromJson(currentData)
            : null,
        meSessions: meSessions,
        motivation: motivation,
        apiCurrentStreak: _readOptionalInt(streakData, 'currentStreak'),
        apiBestStreak: _readOptionalInt(streakData, 'bestStreak'),
        apiTotalRelapseCount: _readOptionalInt(relapseData, 'totalRelapse'),
        clearCurrentSession: currentData == null,
      );
    } catch (e) {
      print(e);
      state = state.copyWith(
        status: NofapStatus.failure,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> startSession() async {
    state = state.copyWith(status: NofapStatus.loading, errorMessage: null);

    try {
      final response = await _apiService.createSession();
      final data = response['data'];
      final session = data is Map<String, dynamic>
          ? NofapSessionModel.fromJson(data)
          : null;
      final streakResponse = await _apiService.getStreakSummary();
      final relapseResponse = await _apiService.getRelapseCount();
      final meSessions = await _loadMeSessions();

      state = state.copyWith(
        status: NofapStatus.success,
        currentSession: session,
        meSessions: meSessions,
        apiCurrentStreak: _readOptionalInt(
          streakResponse['data'],
          'currentStreak',
        ),
        apiBestStreak: _readOptionalInt(streakResponse['data'], 'bestStreak'),
        apiTotalRelapseCount: _readOptionalInt(
          relapseResponse['data'],
          'totalRelapse',
        ),
        clearCurrentSession: session == null,
      );
    } catch (e) {
      state = state.copyWith(
        status: NofapStatus.failure,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> stopCurrentSession({String? relapseNotes}) async {
    state = state.copyWith(status: NofapStatus.loading, errorMessage: null);

    try {
      final response = await _apiService.updateCurrentSession(
        endDate: nowInIndonesia(),
        relapseNotes: relapseNotes,
      );
      final data = response['data'];
      final stoppedSession = data is Map<String, dynamic>
          ? NofapSessionModel.fromJson(data)
          : null;
      final streakResponse = await _apiService.getStreakSummary();
      final relapseResponse = await _apiService.getRelapseCount();
      final meSessions = await _loadMeSessions();

      state = state.copyWith(
        status: NofapStatus.success,
        meSessions: meSessions.isNotEmpty
            ? meSessions
            : [if (stoppedSession != null) stoppedSession],
        apiCurrentStreak: _readOptionalInt(
          streakResponse['data'],
          'currentStreak',
        ),
        apiBestStreak: _readOptionalInt(streakResponse['data'], 'bestStreak'),
        apiTotalRelapseCount: _readOptionalInt(
          relapseResponse['data'],
          'totalRelapse',
        ),
        clearCurrentSession: true,
      );
    } catch (e) {
      state = state.copyWith(
        status: NofapStatus.failure,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  int? _readOptionalInt(dynamic source, String key) {
    if (source is! Map) return null;

    final value = source[key];
    if (value == null) return null;
    if (value is int) return value;

    return int.tryParse(value.toString());
  }

  Future<List<NofapSessionModel>> _loadMeSessions() async {
    final response = await _meApiService.getMeNofapSessions();
    final data = response['data'];

    if (data is List) {
      return data
          .whereType<Map>()
          .map(
            (json) =>
                NofapSessionModel.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    }

    if (data is Map<String, dynamic>) {
      final sessionsData = data['sessions'];
      if (sessionsData is List) {
        return sessionsData
            .whereType<Map>()
            .map(
              (json) =>
                  NofapSessionModel.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();
      }

      if (data['startDate'] != null || data['id'] != null) {
        return [NofapSessionModel.fromJson(data)];
      }
    }

    return const [];
  }
}
