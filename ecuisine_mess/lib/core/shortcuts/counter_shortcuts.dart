import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Counter kiosk shortcuts (docs/05 §4).
///
/// - F10 → Save & print token
/// - F8 → Supervisor override
/// - Esc → Clear invoice
/// - Ctrl+Shift+L → Exit counter (navigate to `/members`; not logout)
class SavePrintIntent extends Intent {
  const SavePrintIntent();
}

class SupervisorOverrideIntent extends Intent {
  const SupervisorOverrideIntent();
}

class ClearCounterIntent extends Intent {
  const ClearCounterIntent();
}

class ExitCounterIntent extends Intent {
  const ExitCounterIntent();
}

/// Shared key bindings for [Shortcuts] / [Actions] or [CallbackShortcuts].
final Map<ShortcutActivator, Intent> kCounterShortcutIntents = {
  const SingleActivator(LogicalKeyboardKey.f10): const SavePrintIntent(),
  const SingleActivator(LogicalKeyboardKey.f8): const SupervisorOverrideIntent(),
  const SingleActivator(LogicalKeyboardKey.escape): const ClearCounterIntent(),
  const SingleActivator(
    LogicalKeyboardKey.keyL,
    control: true,
    shift: true,
  ): const ExitCounterIntent(),
};

/// Convenience [CallbackShortcuts] bindings when Intent/Action wiring is overkill.
Map<ShortcutActivator, VoidCallback> counterCallbackBindings({
  required VoidCallback onSavePrint,
  required VoidCallback onSupervisorOverride,
  required VoidCallback onClear,
  required VoidCallback onExit,
}) {
  return {
    const SingleActivator(LogicalKeyboardKey.f10): onSavePrint,
    const SingleActivator(LogicalKeyboardKey.f8): onSupervisorOverride,
    const SingleActivator(LogicalKeyboardKey.escape): onClear,
    const SingleActivator(
      LogicalKeyboardKey.keyL,
      control: true,
      shift: true,
    ): onExit,
  };
}
