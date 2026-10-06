part of 'cuisine_list_bloc.dart';

sealed class CuisineListEvent extends Equatable {
  const CuisineListEvent();

  @override
  List<Object?> get props => [];
}

final class CuisineListStarted extends CuisineListEvent {
  const CuisineListStarted();
}

final class CuisineListRefreshed extends CuisineListEvent {
  const CuisineListRefreshed();
}

final class CuisineSearchChanged extends CuisineListEvent {
  const CuisineSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class CuisineFilterInactiveToggled extends CuisineListEvent {
  const CuisineFilterInactiveToggled(this.showInactive);

  final bool showInactive;

  @override
  List<Object?> get props => [showInactive];
}

final class CuisineDeleteRequested extends CuisineListEvent {
  const CuisineDeleteRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class CuisineNoticeConsumed extends CuisineListEvent {
  const CuisineNoticeConsumed();
}
