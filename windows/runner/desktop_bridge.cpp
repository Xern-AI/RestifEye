// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

#include "desktop_bridge.h"

#include <flutter/standard_method_codec.h>
#include <windowsx.h>
#include <wtsapi32.h>

#include <cstring>

namespace {

constexpr wchar_t kHelperClass[] = L"RestifEyeDesktopBridge";
constexpr UINT kTrayMessage = WM_APP + 1;
constexpr UINT kTrayId = 1;
constexpr UINT kMenuOpen = 1;
constexpr UINT kMenuPause = 2;
constexpr UINT kMenuQuit = 3;

std::wstring Utf16FromUtf8(const std::string& utf8) {
  if (utf8.empty()) return std::wstring();
  const int length = ::MultiByteToWideChar(
      CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()), nullptr, 0);
  if (length <= 0) return std::wstring();
  std::wstring utf16(static_cast<size_t>(length), L'\0');
  ::MultiByteToWideChar(CP_UTF8, 0, utf8.data(), static_cast<int>(utf8.size()),
                        utf16.data(), length);
  return utf16;
}

const flutter::EncodableValue* Field(const flutter::EncodableMap& map,
                                     const char* key) {
  auto it = map.find(flutter::EncodableValue(key));
  return it == map.end() ? nullptr : &it->second;
}

std::wstring StringField(const flutter::EncodableMap& map, const char* key) {
  const auto* value = Field(map, key);
  const auto* text = value ? std::get_if<std::string>(value) : nullptr;
  return text ? Utf16FromUtf8(*text) : std::wstring();
}

// A straight-alpha BGRA bitmap turned into an icon. The monochrome mask is
// required by CreateIconIndirect but ignored when the colour bitmap carries
// alpha, so it is left all zero.
HICON IconFromBgra(int size, const std::vector<uint8_t>& bgra) {
  BITMAPV5HEADER header = {};
  header.bV5Size = sizeof(header);
  header.bV5Width = size;
  header.bV5Height = -size;  // top-down rows, as Dart sends them
  header.bV5Planes = 1;
  header.bV5BitCount = 32;
  header.bV5Compression = BI_BITFIELDS;
  header.bV5RedMask = 0x00FF0000;
  header.bV5GreenMask = 0x0000FF00;
  header.bV5BlueMask = 0x000000FF;
  header.bV5AlphaMask = 0xFF000000;

  void* bits = nullptr;
  HDC screen = ::GetDC(nullptr);
  HBITMAP color =
      ::CreateDIBSection(screen, reinterpret_cast<BITMAPINFO*>(&header),
                         DIB_RGB_COLORS, &bits, nullptr, 0);
  ::ReleaseDC(nullptr, screen);
  if (!color || !bits) return nullptr;
  std::memcpy(bits, bgra.data(), bgra.size());

  const size_t mask_stride = static_cast<size_t>(((size + 15) / 16) * 2);
  std::vector<uint8_t> mask_bits(mask_stride * static_cast<size_t>(size), 0);
  HBITMAP mask = ::CreateBitmap(size, size, 1, 1, mask_bits.data());

  ICONINFO info = {};
  info.fIcon = TRUE;
  info.hbmColor = color;
  info.hbmMask = mask;
  HICON icon = ::CreateIconIndirect(&info);
  ::DeleteObject(color);
  ::DeleteObject(mask);
  return icon;
}

}  // namespace

UINT DesktopBridge::RelaunchMessage() {
  static const UINT message =
      ::RegisterWindowMessageW(L"com.xernai.restifeye.relaunch");
  return message;
}

DesktopBridge::DesktopBridge(flutter::BinaryMessenger* messenger,
                             HWND main_window)
    : main_window_(main_window) {
  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "com.xernai.restifeye/windows",
      &flutter::StandardMethodCodec::GetInstance());
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    HandleMethodCall(call, std::move(result));
  });

  HINSTANCE instance = ::GetModuleHandleW(nullptr);
  WNDCLASSW window_class = {};
  window_class.lpfnWndProc = HelperProc;
  window_class.hInstance = instance;
  window_class.lpszClassName = kHelperClass;
  ::RegisterClassW(&window_class);

  // A hidden top-level window rather than a message-only one: only top-level
  // windows receive WM_POWERBROADCAST, TaskbarCreated and HWND_BROADCAST.
  helper_ = ::CreateWindowExW(WS_EX_TOOLWINDOW, kHelperClass, L"RestifEye",
                              WS_POPUP, 0, 0, 0, 0, nullptr, nullptr, instance,
                              this);
  taskbar_created_ = ::RegisterWindowMessageW(L"TaskbarCreated");
  RelaunchMessage();
}

DesktopBridge::~DesktopBridge() {
  RemoveTray();
  if (session_registered_) ::WTSUnRegisterSessionNotification(helper_);
  if (helper_) ::DestroyWindow(helper_);
  ::UnregisterClassW(kHelperClass, ::GetModuleHandleW(nullptr));
  if (channel_) channel_->SetMethodCallHandler(nullptr);
}

LRESULT CALLBACK DesktopBridge::HelperProc(HWND hwnd, UINT message,
                                           WPARAM wparam, LPARAM lparam) {
  if (message == WM_NCCREATE) {
    auto* create = reinterpret_cast<CREATESTRUCTW*>(lparam);
    ::SetWindowLongPtrW(hwnd, GWLP_USERDATA,
                        reinterpret_cast<LONG_PTR>(create->lpCreateParams));
  }
  auto* bridge = reinterpret_cast<DesktopBridge*>(
      ::GetWindowLongPtrW(hwnd, GWLP_USERDATA));
  if (bridge && bridge->helper_ == hwnd) {
    return bridge->HandleHelperMessage(message, wparam, lparam);
  }
  return ::DefWindowProcW(hwnd, message, wparam, lparam);
}

LRESULT DesktopBridge::HandleHelperMessage(UINT message, WPARAM wparam,
                                           LPARAM lparam) {
  if (message == kTrayMessage) {
    switch (LOWORD(lparam)) {
      case NIN_SELECT:
      case NIN_KEYSELECT:
        Send("tray", "open");
        break;
      case WM_CONTEXTMENU:
        ShowTrayMenu(GET_X_LPARAM(wparam), GET_Y_LPARAM(wparam));
        break;
    }
    return 0;
  }
  if (message == WM_WTSSESSION_CHANGE) {
    if (wparam == WTS_SESSION_LOCK) Send("session", "lock");
    if (wparam == WTS_SESSION_UNLOCK) Send("session", "unlock");
    return 0;
  }
  if (message == WM_POWERBROADCAST) {
    if (wparam == PBT_APMSUSPEND) Send("session", "suspend");
    if (wparam == PBT_APMRESUMEAUTOMATIC || wparam == PBT_APMRESUMESUSPEND) {
      Send("session", "resume");
    }
    return TRUE;
  }
  if (message == taskbar_created_ && taskbar_created_ != 0) {
    // Explorer restarted and forgot every tray icon; put ours back.
    if (tray_added_) {
      tray_added_ = false;
      AddOrUpdateTray();
    }
    return 0;
  }
  if (message == RelaunchMessage()) {
    ShowMainWindow();
    Send("relaunch", "");
    return 0;
  }
  return ::DefWindowProcW(helper_, message, wparam, lparam);
}

void DesktopBridge::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = call.method_name();
  const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());

  if (method == "ping") {
    result->Success(flutter::EncodableValue("pong"));
  } else if (method == "startSessionEvents") {
    if (!session_registered_) {
      session_registered_ = ::WTSRegisterSessionNotification(
                                helper_, NOTIFY_FOR_THIS_SESSION) != FALSE;
    }
    result->Success(flutter::EncodableValue(session_registered_));
  } else if (method == "trayIconSize") {
    const UINT dpi = ::GetDpiForWindow(main_window_);
    result->Success(flutter::EncodableValue(static_cast<int32_t>(
        ::GetSystemMetricsForDpi(SM_CXSMICON, dpi ? dpi : 96))));
  } else if (method == "traySetIcon" && args) {
    const auto* size = Field(*args, "size");
    const auto* bgra = Field(*args, "bgra");
    const auto* edge = size ? std::get_if<int32_t>(size) : nullptr;
    const auto* pixels = bgra ? std::get_if<std::vector<uint8_t>>(bgra) : nullptr;
    const bool ok = edge && pixels &&
                    SetTrayIcon(*edge, *pixels, StringField(*args, "tooltip"));
    result->Success(flutter::EncodableValue(ok));
  } else if (method == "traySetMenu" && args) {
    menu_open_ = StringField(*args, "open");
    menu_pause_ = StringField(*args, "pause");
    menu_quit_ = StringField(*args, "quit");
    result->Success();
  } else if (method == "trayRemove") {
    RemoveTray();
    result->Success();
  } else if (method == "forceForeground") {
    result->Success(flutter::EncodableValue(ForceForeground()));
  } else if (method == "showWindow") {
    result->Success(flutter::EncodableValue(ShowSynchronously()));
  } else if (method == "setFullScreen" && args) {
    const auto* on = Field(*args, "on");
    const auto* flag = on ? std::get_if<bool>(on) : nullptr;
    result->Success(flutter::EncodableValue(flag && SetFullScreen(*flag)));
  } else if (method == "coversScreen") {
    result->Success(flutter::EncodableValue(CoversScreen()));
  } else {
    result->NotImplemented();
  }
}

bool DesktopBridge::SetTrayIcon(int size, const std::vector<uint8_t>& bgra,
                                const std::wstring& tooltip) {
  if (size <= 0 ||
      bgra.size() != static_cast<size_t>(size) * static_cast<size_t>(size) * 4) {
    return false;
  }
  HICON icon = IconFromBgra(size, bgra);
  if (!icon) return false;

  tray_.cbSize = sizeof(tray_);
  tray_.hWnd = helper_;
  tray_.uID = kTrayId;
  tray_.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP | NIF_SHOWTIP;
  tray_.uCallbackMessage = kTrayMessage;
  tray_.hIcon = icon;
  wcsncpy_s(tray_.szTip, tooltip.c_str(), _TRUNCATE);

  const bool ok = AddOrUpdateTray();
  // The shell copies the icon, so the previous one can go now.
  HICON previous = icon_;
  icon_ = icon;
  if (previous) ::DestroyIcon(previous);
  return ok;
}

bool DesktopBridge::AddOrUpdateTray() {
  if (tray_added_) return ::Shell_NotifyIconW(NIM_MODIFY, &tray_) != FALSE;
  if (!::Shell_NotifyIconW(NIM_ADD, &tray_)) return false;
  tray_.uVersion = NOTIFYICON_VERSION_4;
  ::Shell_NotifyIconW(NIM_SETVERSION, &tray_);
  tray_added_ = true;
  return true;
}

void DesktopBridge::RemoveTray() {
  if (tray_added_) ::Shell_NotifyIconW(NIM_DELETE, &tray_);
  tray_added_ = false;
  if (icon_) ::DestroyIcon(icon_);
  icon_ = nullptr;
}

void DesktopBridge::ShowTrayMenu(int x, int y) {
  HMENU menu = ::CreatePopupMenu();
  if (!menu) return;
  ::AppendMenuW(menu, MF_STRING, kMenuOpen, menu_open_.c_str());
  ::AppendMenuW(menu, MF_STRING, kMenuPause, menu_pause_.c_str());
  ::AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
  ::AppendMenuW(menu, MF_STRING, kMenuQuit, menu_quit_.c_str());

  // Without the helper owning the foreground, the menu would not close when
  // the user clicks elsewhere (documented TrackPopupMenu behaviour).
  ::SetForegroundWindow(helper_);
  const UINT choice = static_cast<UINT>(::TrackPopupMenu(
      menu, TPM_RETURNCMD | TPM_NONOTIFY | TPM_RIGHTBUTTON, x, y, 0, helper_,
      nullptr));
  ::PostMessageW(helper_, WM_NULL, 0, 0);
  ::DestroyMenu(menu);

  if (choice == kMenuOpen) Send("tray", "open");
  if (choice == kMenuPause) Send("tray", "togglePause");
  if (choice == kMenuQuit) Send("tray", "quit");
}

// Windows lets only the foreground owner hand the foreground over. Joining the
// foreground thread's input queue for the moment of the switch is the
// documented way for a background app to take it when the user expects it.
bool DesktopBridge::ForceForeground() {
  if (::IsIconic(main_window_)) ::ShowWindow(main_window_, SW_RESTORE);
  HWND foreground = ::GetForegroundWindow();
  if (foreground == main_window_) return true;

  const DWORD ours = ::GetCurrentThreadId();
  const DWORD theirs =
      foreground ? ::GetWindowThreadProcessId(foreground, nullptr) : 0;
  const bool attached =
      theirs != 0 && theirs != ours &&
      ::AttachThreadInput(theirs, ours, TRUE) != FALSE;
  ::BringWindowToTop(main_window_);
  ::SetForegroundWindow(main_window_);
  if (attached) ::AttachThreadInput(theirs, ours, FALSE);
  return ::GetForegroundWindow() == main_window_;
}

// window_manager shows with ShowWindowAsync, which returns before the window
// is visible; sizing or focusing it in that gap left a break window at the
// wrong size and without focus. This returns only once Windows has shown it.
bool DesktopBridge::ShowSynchronously() {
  ::ShowWindow(main_window_, ::IsIconic(main_window_) ? SW_RESTORE : SW_SHOW);
  ::UpdateWindow(main_window_);
  return ::IsWindowVisible(main_window_) != FALSE;
}

// Borderless and exactly the size of the window's monitor, covering the
// taskbar. The previous style and frame are kept so leaving restores them.
bool DesktopBridge::SetFullScreen(bool on) {
  if (on == fullscreen_) return true;
  constexpr UINT kFrame = SWP_NOOWNERZORDER | SWP_FRAMECHANGED;
  if (on) {
    MONITORINFO monitor = {};
    monitor.cbSize = sizeof(monitor);
    if (!::GetMonitorInfoW(
            ::MonitorFromWindow(main_window_, MONITOR_DEFAULTTONEAREST),
            &monitor)) {
      return false;
    }
    saved_style_ = ::GetWindowLongPtrW(main_window_, GWL_STYLE);
    saved_zoomed_ = ::IsZoomed(main_window_) != FALSE;
    ::GetWindowRect(main_window_, &saved_rect_);
    const LONG_PTR frameless =
        (saved_style_ & ~static_cast<LONG_PTR>(WS_OVERLAPPEDWINDOW)) |
        static_cast<LONG_PTR>(WS_POPUP);
    ::SetWindowLongPtrW(main_window_, GWL_STYLE, frameless);
    const RECT& area = monitor.rcMonitor;
    ::SetWindowPos(main_window_, HWND_TOP, area.left, area.top,
                   area.right - area.left, area.bottom - area.top,
                   kFrame | SWP_SHOWWINDOW);
    fullscreen_ = true;
    return true;
  }
  ::SetWindowLongPtrW(main_window_, GWL_STYLE, saved_style_);
  ::SetWindowPos(main_window_, nullptr, saved_rect_.left, saved_rect_.top,
                 saved_rect_.right - saved_rect_.left,
                 saved_rect_.bottom - saved_rect_.top,
                 kFrame | SWP_NOZORDER | SWP_NOACTIVATE);
  if (saved_zoomed_) ::ShowWindow(main_window_, SW_MAXIMIZE);
  fullscreen_ = false;
  return true;
}

// Whether the full-screen break is what the user is looking at, whichever app
// holds the keyboard: our window is the one at the centre of its monitor.
// Alt+Tab leaves a topmost break on top (true); Win+D, minimising or Task View
// uncover the screen (false).
bool DesktopBridge::CoversScreen() {
  if (!fullscreen_ || !::IsWindowVisible(main_window_) ||
      ::IsIconic(main_window_)) {
    return false;
  }
  MONITORINFO monitor = {};
  monitor.cbSize = sizeof(monitor);
  if (!::GetMonitorInfoW(
          ::MonitorFromWindow(main_window_, MONITOR_DEFAULTTONEAREST),
          &monitor)) {
    return false;
  }
  const RECT& area = monitor.rcMonitor;
  const POINT centre = {(area.left + area.right) / 2,
                        (area.top + area.bottom) / 2};
  HWND hit = ::WindowFromPoint(centre);
  return hit && ::GetAncestor(hit, GA_ROOT) == main_window_;
}

void DesktopBridge::ShowMainWindow() {
  ::ShowWindow(main_window_, ::IsIconic(main_window_) ? SW_RESTORE : SW_SHOW);
  ForceForeground();
}

void DesktopBridge::Send(const char* method, const std::string& argument) {
  if (!channel_) return;
  channel_->InvokeMethod(
      method, std::make_unique<flutter::EncodableValue>(argument));
}
