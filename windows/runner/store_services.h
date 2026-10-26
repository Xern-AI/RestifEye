// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

#ifndef RUNNER_STORE_SERVICES_H_
#define RUNNER_STORE_SERVICES_H_

#include <windows.h>

#include <functional>
#include <string>
#include <vector>

// Microsoft Store licensing and the package's start-at-login task, through
// C++/WinRT. Kept out of the rest of the runner so only this file needs
// WinRT headers and exceptions. Every callback may run on any thread.
namespace store_services {

// Whether this process runs from an MSIX package (the Store build).
bool IsPackaged();

struct Offer {
  std::string token;       // the add-on's product ID, e.g. restifeye.yearly
  std::string store_id;    // what a purchase is requested with
  std::string price;       // formatted in the buyer's currency
  std::string full_price;  // the usual price while on sale, else empty
};

void OwnedTokens(
    HWND owner,
    std::function<void(bool ok, std::vector<std::string> tokens,
                       std::string error)> done);

void Offers(HWND owner,
            std::function<void(bool ok, std::vector<Offer> offers,
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
