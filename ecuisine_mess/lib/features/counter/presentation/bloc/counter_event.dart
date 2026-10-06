part of 'counter_bloc.dart';

sealed class CounterEvent extends Equatable {
  const CounterEvent();

  @override
  List<Object?> get props => [];
}

final class CounterStarted extends CounterEvent {
  const CounterStarted();
}

final class CounterMealWindowRequested extends CounterEvent {
  const CounterMealWindowRequested({this.cuisineId});

  final String? cuisineId;

  @override
  List<Object?> get props => [cuisineId];
}

final class CounterRfidScanned extends CounterEvent {
  const CounterRfidScanned(this.tag);

  final String tag;

  @override
  List<Object?> get props => [tag];
}

final class CounterSupervisorOverrideGranted extends CounterEvent {
  const CounterSupervisorOverrideGranted({
    required this.name,
    required this.reason,
  });

  final String name;
  final String reason;

  @override
  List<Object?> get props => [name, reason];
}

final class CounterIssueTokenRequested extends CounterEvent {
  const CounterIssueTokenRequested();
}

final class CounterCleared extends CounterEvent {
  const CounterCleared();
}

final class CounterNoticeConsumed extends CounterEvent {
  const CounterNoticeConsumed();
}
