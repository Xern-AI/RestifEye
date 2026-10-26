// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

#ifndef RUNNER_STORE_SERVICES_H_
#define RUNNER_STORE_SERVICES_H_

#include <windows.h>

#include <cstdint>
#include <functional>
#include <string>

// Microsoft Store licensing and the package's start-at-login task, through
// C++/WinRT. Kept out of the rest of the runner so only this file needs
// WinRT headers and exceptions. Every callback may run on any thread.
namespace store_services {

// Whether this process runs from an MSIX package (the Store build).
bool IsPackaged();

struct AppLicence {
  bool active = false;
  bool trial = false;
  // False for a copy that was not acquired from the Store (sideloaded test
  // packages), which has no Store SKU and nothing to enforce.
  bool from_store = false;
  // When a trial ends, in milliseconds since 1970; 0 when not a trial.
  int64_t trial_ends_ms = 0;
};

struct AppOffer {
  std::string store_id;    // what a purchase is requested with
  std::string price;       // formatted in the buyer's currency
  std::string full_price;  // the usual price while on sale, else empty
};

void Licence(HWND owner,
             std::function<void(bool ok, AppLicence licence,
                                std::string error)> done);

void CurrentOffer(HWND owner,
                  std::function<void(bool ok, AppOffer offer,
                                     std::string error)> done);

// Must be called on the window's thread: the Store shows its purchase
// dialog over [owner].
void Purchase(HWND owner, const std::string& store_id,
              std::function<void(std::string status, std::string error)> done);

// States: enabled, disabled, disabledByUser, disabledByPolicy,
// enabledByPolicy, or error.
void StartupState(std::function<void(std::string state)> done);
void StartupEnable(std::function<void(std::string state)> done);
void StartupDisable(std::function<void(std::string state)> done);

}  // namespace store_services

#endif  // RUNNER_STORE_SERVICES_H_
