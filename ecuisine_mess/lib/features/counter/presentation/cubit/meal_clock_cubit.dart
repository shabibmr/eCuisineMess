import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Cosmetic live clock for the counter banner. Server decides the meal window.
class MealClockCubit extends Cubit<String> {
  MealClockCubit() : super(_format(DateTime.now())) {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      emit(_format(DateTime.now()));
    });
  }

  Timer? _timer;
  static final _fmt = DateFormat('HH:mm:ss');

  static String _format(DateTime dt) => _fmt.format(dt);

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
