#ifndef RUNNER_STARTUP_LOG_H_
#define RUNNER_STARTUP_LOG_H_

// Appends one line to %LOCALAPPDATA%\ecuisine_mess\logs\app.log.
// The Dart AppLog class writes the same file after the engine starts.
// [level] is a short word such as "info" or "error".
// Failures are ignored so logging cannot block process startup.
void WriteStartupLog(const wchar_t* level, const wchar_t* message);

// Records unhandled native exceptions in that log file.
// Safe to call again after Flutter replaces the process filter.
void InstallStartupCrashLog();

#endif  // RUNNER_STARTUP_LOG_H_
