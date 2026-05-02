import 'package:flutter_riverpod/legacy.dart';
import 'package:purewill/core/utils/indonesia_timezone.dart';

class TimezoneState {
  final AppTimezoneOption selectedTimezone;
  final bool isSaving;
  final String? errorMessage;

  const TimezoneState({
    required this.selectedTimezone,
    this.isSaving = false,
    this.errorMessage,
  });

  TimezoneState copyWith({
    AppTimezoneOption? selectedTimezone,
    bool? isSaving,
    String? errorMessage,
  }) {
    return TimezoneState(
      selectedTimezone: selectedTimezone ?? this.selectedTimezone,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class TimezoneNotifier extends StateNotifier<TimezoneState> {
  TimezoneNotifier()
    : super(TimezoneState(selectedTimezone: AppTimezone.currentOption));

  Future<void> updateTimezone(AppTimezoneOption option) async {
    if (option == state.selectedTimezone) {
      return;
    }

    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      await setIndonesiaTimezone(option);
      state = state.copyWith(
        selectedTimezone: option,
        isSaving: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to update timezone: $e',
      );
    }
  }
}

final timezoneProvider = StateNotifierProvider<TimezoneNotifier, TimezoneState>(
  (ref) {
    return TimezoneNotifier();
  },
);
