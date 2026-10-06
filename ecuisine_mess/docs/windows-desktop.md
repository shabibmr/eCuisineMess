# Windows Desktop Concerns

Flutter targets **Windows only**. Platform folders for android/ios/web/linux/macos exist from `flutter create`; they are unsupported and may be deleted to cut build noise.

## 1. RFID reader (keyboard wedge)

The reader acts as a keyboard: digits then `Enter`. Implementation:

- `RfidInputField` is a `TextField` with `autofocus`, `obscureText: true`, `onSubmitted: (tag) => bloc.add(RfidSubmitted(tag.trim()))`, then `controller.clear()`.
- A `FocusNode` is **re-requested** after: tap result, banner dismiss, dialog close, route return, window refocus (`WidgetsBindingObserver.didChangeAppLifecycleState`), and a 2 s watchdog (`Timer.periodic`) while the counter is the active route and no dialog is open.
- Guard against **partial reads / typing**: ignore submits shorter than the configured min length (default 4) and trim `\r\n`. Optionally measure inter-key time to reject slow human typing (config `rfid.maxKeyGapMs`, default off).
- While a modal (override, slip) is open, keystrokes must **not** leak to the RFID field: dialogs take focus; on close, refocus.
- Registration: `RfidCaptureField` enters "listening" mode (15 s ring), the next submitted value fills the field; it then calls `CheckRfidAvailable`.
- Debug builds include the **RFID Tap Simulator** (scenario buttons) to test without hardware.

## 2. Keyboard shortcuts

Declared in `core/shortcuts/`:

```dart
class SaveBillIntent extends Intent { const SaveBillIntent(); }
final shortcuts = <ShortcutActivator, Intent>{
  const SingleActivator(LogicalKeyboardKey.f10): const SaveBillIntent(),
  const SingleActivator(LogicalKeyboardKey.escape): const ClearInvoiceIntent(),
  const SingleActivator(LogicalKeyboardKey.f8): const RequestOverrideIntent(),
  const SingleActivator(LogicalKeyboardKey.keyK, control: true): const OpenCommandPaletteIntent(),
  const SingleActivator(LogicalKeyboardKey.keyL, control: true, shift: true): const ExitCounterIntent(),
  for (var i = 1; i <= 9; i++) SingleActivator(LogicalKeyboardKey(0x30 + i), alt: true): GoToNavIntent(i - 1),
};
```
Full map: [05 §4](../../docs/05-screens-ux-spec.md). Page-scoped shortcuts wrap only that page (`Shortcuts` + `Actions` + `Focus`) so `F10` does nothing outside the counter. Text fields keep normal editing keys.

## 3. Window management (`window_manager`)

- Title `eCuisine Mess`, default 1366×800, **min 1100×680**, centered.
- Role `counter`: option **kiosk/full-screen** (`setFullScreen(true)`, `setPreventClose` with supervisor exit). Configurable per install.
- Prevent multiple instances on one PC (named mutex via `windows_single_instance` or equivalent) so two counters don't fight over the reader.

## 4. Printing the token slip

Phased:

| Phase | Approach |
|---|---|
| Now | On-screen `TokenSlipDialog` preview (as mock) + `SoundPlayer.print` cue |
| P6 | `PrinterService` implementation chosen by config: **Windows spooler** (render slip to PDF/bitmap via `printing` package → default printer) or **ESC/POS raw** to a thermal printer (USB via spooler raw port, or network 9100) |

Contract (`shared/services/printer_service.dart`):
```dart
abstract interface class PrinterService { Future<void> printSlip(SlipData data, {bool duplicate = false}); }
```
`SlipData` is a plain value object (company, token, meal, date/time, name, cuisine, lines, counter, user). Printer width (58/80 mm) and printer name come from settings. A print failure must **not** void the bill — show "Printed? Retry / Skip" and allow reprint from the register.

## 5. Audio

`SoundPlayer` (package `audioplayers`) preloads `assets/sounds/{success,error,print}.wav`; mute toggle persisted (`mess_audio_muted`). Errors on the counter always show visually even when muted.

## 6. Files & dialogs

CSV export: `file_selector` save dialog (`getSaveLocation`) → write bytes. Photo upload: `file_selector` open dialog (jpg/png). Remember last directory in prefs.

## 7. Networking on Windows

- API URL default `http://127.0.0.1:8000`; for LAN use `http://<server-ip>:8000`.
- Windows Defender Firewall prompts the **server** (not the client). Client needs no inbound rules.
- Proxy: Dio respects system proxy for non-localhost hosts; if a corporate proxy interferes with LAN IPs, set `NO_PROXY` or bypass in `Dio` adapter.

## 8. Packaging & updates

- `flutter build windows --release` → ship `build\windows\x64\runner\Release\` (exe + `flutter_windows.dll` + `data/` + plugin DLLs). Requires the VC++ redistributable on target PCs (or ship via MSIX/installer).
- Installer (P6): MSIX via `msix` package or Inno Setup script; installs per-machine, creates a Start-menu shortcut and optional auto-start for counter PCs.
- Versioning: `pubspec.yaml` `version: x.y.z+build`; shown on the Server Settings / About dialog and sent as `X-Client-Version` header.

## 9. Diagnostics

- `logger` package → rolling file `%LOCALAPPDATA%\ecuisine_mess\logs\app.log` (redact RFID/tokens).
- Global `FlutterError.onError` + `PlatformDispatcher.instance.onError` → log + friendly crash dialog.
- "Copy diagnostics" button in Server Settings (API URL, health result, app version).

## 10. Performance targets (counter)

Tap → banner/invoice visible **< 300 ms** on LAN; slip appears < 500 ms after F10. Avoid rebuilding the whole counter page per clock tick: the clock lives in its own `BlocSelector`/`StreamBuilder` widget.
