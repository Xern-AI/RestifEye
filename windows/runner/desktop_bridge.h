// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

#ifndef RUNNER_DESKTOP_BRIDGE_H_
#define RUNNER_DESKTOP_BRIDGE_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>
#include <shellapi.h>

#include <cstdint>
#include <memory>
#include <string>
#include <vector>

// Everything RestifEye needs a window procedure for, on a hidden helper window
// of its own: the tray icon and menu, session lock and power broadcasts,
// Explorer restarts, and the message a second launch sends. Talks to Dart over
// the "com.xernai.restifeye/windows" method channel (see windows_runner.dart).
class DesktopBridge {
 public:
  DesktopBridge(flutter::BinaryMessenger* messenger, HWND main_window);
  ~DesktopBridge();

  DesktopBridge(const DesktopBridge&) = delete;
  DesktopBridge& operator=(const DesktopBridge&) = delete;

  // Broadcast by a second launch so the running copy shows its window.
  static UINT RelaunchMessage();

 private:
  static LRESULT CALLBACK HelperProc(HWND hwnd, UINT message, WPARAM wparam,
                                     LPARAM lparam);
  LRESULT HandleHelperMessage(UINT message, WPARAM wparam, LPARAM lparam);
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  bool SetTrayIcon(int size, const std::vector<uint8_t>& bgra,
                   const std::wstring& tooltip);
  bool AddOrUpdateTray();
  void RemoveTray();
  void ShowTrayMenu(int x, int y);
  bool ForceForeground();
  void ShowMainWindow();
  void Send(const char* method, const std::string& argument);

  HWND main_window_;
  HWND helper_ = nullptr;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;

  NOTIFYICONDATAW tray_ = {};
  HICON icon_ = nullptr;
  bool tray_added_ = false;
  std::wstring menu_open_ = L"Open";
  std::wstring menu_pause_ = L"Pause breaks";
  std::wstring menu_quit_ = L"Quit";
  bool session_registered_ = false;
  UINT taskbar_created_ = 0;
};

#endif  // RUNNER_DESKTOP_BRIDGE_H_
