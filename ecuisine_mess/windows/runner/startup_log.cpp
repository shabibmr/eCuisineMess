#include "startup_log.h"

#include <windows.h>

#include <cstdint>
#include <cstdio>
#include <string>

namespace {

constexpr unsigned long long kMaxLogBytes = 1024ull * 1024ull;
constexpr int kKeptArchives = 3;

std::wstring ReadEnv(const wchar_t* name) {
  DWORD length = ::GetEnvironmentVariableW(name, nullptr, 0);
  if (length == 0) {
    return std::wstring();
  }
  std::wstring value(length, L'\0');
  DWORD written = ::GetEnvironmentVariableW(name, &value[0], length);
  if (written == 0 || written >= length) {
    return std::wstring();
  }
  value.resize(written);
  return value;
}

std::wstring LogDirectory() {
  std::wstring root = ReadEnv(L"LOCALAPPDATA");
  if (root.empty()) {
    std::wstring profile = ReadEnv(L"USERPROFILE");
    if (!profile.empty()) {
      root = profile + L"\\AppData\\Local";
    }
  }
  if (root.empty()) {
    wchar_t temp[MAX_PATH];
    DWORD length = ::GetTempPathW(MAX_PATH, temp);
    if (length == 0 || length >= MAX_PATH) {
      return std::wstring();
    }
    root.assign(temp, length);
    while (!root.empty() && (root.back() == L'\\' || root.back() == L'/')) {
      root.pop_back();
    }
  }
  return root + L"\\ecuisine_mess\\logs";
}

void EnsureDirectory(const std::wstring& directory) {
  std::wstring current;
  current.reserve(directory.size());
  for (wchar_t character : directory) {
    current.push_back(character);
    if (character == L'\\' || character == L'/') {
      ::CreateDirectoryW(current.c_str(), nullptr);
    }
  }
  ::CreateDirectoryW(directory.c_str(), nullptr);
}

std::wstring ArchivePath(const std::wstring& active, int index) {
  return active + L"." + std::to_wstring(index);
}

void RotateIfNeeded(const std::wstring& active) {
  WIN32_FILE_ATTRIBUTE_DATA info;
  if (!::GetFileAttributesExW(active.c_str(), GetFileExInfoStandard, &info)) {
    return;
  }
  unsigned long long size =
      (static_cast<unsigned long long>(info.nFileSizeHigh) << 32) |
      info.nFileSizeLow;
  if (size < kMaxLogBytes) {
    return;
  }

  for (int index = kKeptArchives; index >= 1; --index) {
    std::wstring source = (index == 1) ? active : ArchivePath(active, index - 1);
    std::wstring target = ArchivePath(active, index);
    if (::GetFileAttributesW(source.c_str()) == INVALID_FILE_ATTRIBUTES) {
      continue;
    }
    ::DeleteFileW(target.c_str());
    ::MoveFileExW(source.c_str(), target.c_str(), MOVEFILE_REPLACE_EXISTING);
  }
}

std::string Utf8FromWide(const std::wstring& text) {
  if (text.empty()) {
    return std::string();
  }
  int size = ::WideCharToMultiByte(CP_UTF8, 0, text.data(),
                                   static_cast<int>(text.size()), nullptr, 0,
                                   nullptr, nullptr);
  if (size <= 0) {
    return std::string();
  }
  std::string utf8(size, '\0');
  int written = ::WideCharToMultiByte(CP_UTF8, 0, text.data(),
                                      static_cast<int>(text.size()),
                                      utf8.data(), size, nullptr, nullptr);
  if (written <= 0) {
    return std::string();
  }
  utf8.resize(written);
  return utf8;
}

std::wstring Timestamp() {
  SYSTEMTIME time;
  ::GetLocalTime(&time);
  wchar_t buffer[40];
  swprintf_s(buffer, L"%04u-%02u-%02uT%02u:%02u:%02u.%03u", time.wYear,
             time.wMonth, time.wDay, time.wHour, time.wMinute, time.wSecond,
             time.wMilliseconds);
  return buffer;
}

LPTOP_LEVEL_EXCEPTION_FILTER g_previous_filter = nullptr;
bool g_in_crash_log = false;

LONG WINAPI StartupUnhandledException(EXCEPTION_POINTERS* info) {
  if (g_in_crash_log) {
    return EXCEPTION_CONTINUE_SEARCH;
  }
  g_in_crash_log = true;
  unsigned long code = 0;
  unsigned long long address = 0;
  if (info != nullptr && info->ExceptionRecord != nullptr) {
    code = info->ExceptionRecord->ExceptionCode;
    address = static_cast<unsigned long long>(
        reinterpret_cast<std::uintptr_t>(info->ExceptionRecord->ExceptionAddress));
  }
  wchar_t line[160];
  swprintf_s(line, L"unhandled native exception code=0x%08lX address=0x%llX",
             code, address);
  WriteStartupLog(L"error", line);
  if (g_previous_filter != nullptr &&
      g_previous_filter != StartupUnhandledException) {
    return g_previous_filter(info);
  }
  return EXCEPTION_CONTINUE_SEARCH;
}

}  // namespace

void WriteStartupLog(const wchar_t* level, const wchar_t* message) {
  if (level == nullptr || message == nullptr || message[0] == L'\0') {
    return;
  }

  HANDLE mutex = ::CreateMutexW(nullptr, FALSE, L"Local\\eCuisineMessAppLog");
  DWORD wait = WAIT_FAILED;
  if (mutex != nullptr) {
    wait = ::WaitForSingleObject(mutex, 200);
  }

  std::wstring directory = LogDirectory();
  if (!directory.empty()) {
    EnsureDirectory(directory);
    std::wstring path = directory + L"\\app.log";
    RotateIfNeeded(path);
    HANDLE file = ::CreateFileW(
        path.c_str(), FILE_APPEND_DATA,
        FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE, nullptr,
        OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (file != INVALID_HANDLE_VALUE) {
      std::wstring line = Timestamp() + L" " + level + L" " + message + L"\r\n";
      std::string utf8 = Utf8FromWide(line);
      DWORD written = 0;
      ::WriteFile(file, utf8.data(), static_cast<DWORD>(utf8.size()), &written,
                  nullptr);
      ::FlushFileBuffers(file);
      ::CloseHandle(file);
    }
  }

  if (mutex != nullptr) {
    if (wait == WAIT_OBJECT_0 || wait == WAIT_ABANDONED) {
      ::ReleaseMutex(mutex);
    }
    ::CloseHandle(mutex);
  }
}

void InstallStartupCrashLog() {
  LPTOP_LEVEL_EXCEPTION_FILTER prior =
      ::SetUnhandledExceptionFilter(StartupUnhandledException);
  if (prior != nullptr && prior != StartupUnhandledException) {
    g_previous_filter = prior;
  }
}
