// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

// unknwn.h before any C++/WinRT header enables classic COM interop, which
// IInitializeWithWindow needs.
#include <unknwn.h>

#include "store_services.h"

#include <appmodel.h>
#include <shobjidl.h>
#include <winrt/Windows.ApplicationModel.h>
#include <winrt/Windows.Foundation.Collections.h>
#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Services.Store.h>

namespace store_services {
namespace {

using winrt::Windows::ApplicationModel::StartupTask;
using winrt::Windows::ApplicationModel::StartupTaskState;
using winrt::Windows::Foundation::AsyncStatus;
using winrt::Windows::Services::Store::StoreAppLicense;
using winrt::Windows::Services::Store::StoreContext;
using winrt::Windows::Services::Store::StoreProductQueryResult;
using winrt::Windows::Services::Store::StorePurchaseResult;
using winrt::Windows::Services::Store::StorePurchaseStatus;

constexpr wchar_t kStartupTaskId[] = L"RestifEyeStartup";

// A desktop app's StoreContext must be told which window owns the Store's
// dialogs, or purchases fail.
StoreContext ContextFor(HWND owner) {
  StoreContext context = StoreContext::GetDefault();
  context.as<::IInitializeWithWindow>()->Initialize(owner);
  return context;
}

std::string Message(const winrt::hresult_error& error) {
  return winrt::to_string(error.message());
}

std::string StateName(StartupTaskState state) {
  switch (state) {
    case StartupTaskState::Enabled:
      return "enabled";
    case StartupTaskState::Disabled:
      return "disabled";
    case StartupTaskState::DisabledByUser:
      return "disabledByUser";
    case StartupTaskState::DisabledByPolicy:
      return "disabledByPolicy";
    case StartupTaskState::EnabledByPolicy:
      return "enabledByPolicy";
  }
  return "error";
}

std::string PurchaseStatusName(StorePurchaseStatus status) {
  switch (status) {
    case StorePurchaseStatus::Succeeded:
      return "purchased";
    case StorePurchaseStatus::AlreadyPurchased:
      return "alreadyOwned";
    case StorePurchaseStatus::NotPurchased:
      return "cancelled";
    default:
      return "failed";
  }
}

void WithStartupTask(std::function<void(StartupTask)> use,
                     std::function<void(std::string)> done) {
  try {
    StartupTask::GetAsync(kStartupTaskId)
        .Completed([use, done](const auto& op, AsyncStatus status) {
          try {
            if (status != AsyncStatus::Completed) return done("error");
            use(op.GetResults());
          } catch (const winrt::hresult_error&) {
            done("error");
          }
        });
  } catch (const winrt::hresult_error&) {
    done("error");
  }
}

}  // namespace

bool IsPackaged() {
  UINT32 length = 0;
  return ::GetCurrentPackageFullName(&length, nullptr) !=
         APPMODEL_ERROR_NO_PACKAGE;
}

void OwnedTokens(
    HWND owner,
    std::function<void(bool, std::vector<std::string>, std::string)> done) {
  try {
    ContextFor(owner).GetAppLicenseAsync().Completed(
        [done](const auto& op, AsyncStatus status) {
          try {
            if (status != AsyncStatus::Completed) {
              return done(false, {}, "licence query did not complete");
            }
            StoreAppLicense license = op.GetResults();
            std::vector<std::string> tokens;
            for (const auto& entry : license.AddOnLicenses()) {
              const auto add_on = entry.Value();
              if (add_on.IsActive()) {
                tokens.push_back(winrt::to_string(add_on.InAppOfferToken()));
              }
            }
            done(true, tokens, "");
          } catch (const winrt::hresult_error& error) {
            done(false, {}, Message(error));
          }
        });
  } catch (const winrt::hresult_error& error) {
    done(false, {}, Message(error));
  }
}

void Offers(HWND owner,
            std::function<void(bool, std::vector<Offer>, std::string)> done) {
  try {
    auto kinds = winrt::single_threaded_vector<winrt::hstring>({L"Durable"});
    ContextFor(owner).GetAssociatedStoreProductsAsync(kinds).Completed(
        [done](const auto& op, AsyncStatus status) {
          try {
            if (status != AsyncStatus::Completed) {
              return done(false, {}, "product query did not complete");
            }
            StoreProductQueryResult result = op.GetResults();
            if (result.ExtendedError() != winrt::hresult(0)) {
              return done(false, {},
                          winrt::to_string(winrt::hresult_error(
                                               result.ExtendedError())
                                               .message()));
            }
            std::vector<Offer> offers;
            for (const auto& entry : result.Products()) {
              const auto product = entry.Value();
              const auto price = product.Price();
              Offer offer;
              offer.token = winrt::to_string(product.InAppOfferToken());
              offer.store_id = winrt::to_string(product.StoreId());
              offer.price = winrt::to_string(price.FormattedPrice());
              if (price.IsOnSale()) {
                offer.full_price = winrt::to_string(price.FormattedBasePrice());
              }
              offers.push_back(offer);
            }
            done(true, offers, "");
          } catch (const winrt::hresult_error& error) {
            done(false, {}, Message(error));
          }
        });
  } catch (const winrt::hresult_error& error) {
    done(false, {}, Message(error));
  }
}

void Purchase(HWND owner, const std::string& store_id,
              std::function<void(std::string, std::string)> done) {
  try {
    ContextFor(owner)
        .RequestPurchaseAsync(winrt::to_hstring(store_id))
        .Completed([done](const auto& op, AsyncStatus status) {
          try {
            if (status != AsyncStatus::Completed) {
              return done("failed", "purchase did not complete");
            }
            StorePurchaseResult result = op.GetResults();
            std::string error;
            if (result.ExtendedError() != winrt::hresult(0)) {
              error = winrt::to_string(
                  winrt::hresult_error(result.ExtendedError()).message());
            }
            done(PurchaseStatusName(result.Status()), error);
          } catch (const winrt::hresult_error& error) {
            done("failed", Message(error));
          }
        });
  } catch (const winrt::hresult_error& error) {
    done("failed", Message(error));
  }
}

void StartupState(std::function<void(std::string)> done) {
  WithStartupTask([done](StartupTask task) { done(StateName(task.State())); },
                  done);
}

void StartupEnable(std::function<void(std::string)> done) {
  WithStartupTask(
      [done](StartupTask task) {
        task.RequestEnableAsync().Completed(
            [done](const auto& op, AsyncStatus status) {
              try {
                if (status != AsyncStatus::Completed) return done("error");
                done(StateName(op.GetResults()));
              } catch (const winrt::hresult_error&) {
                done("error");
              }
            });
      },
      done);
}

void StartupDisable(std::function<void(std::string)> done) {
  WithStartupTask(
      [done](StartupTask task) {
        task.Disable();
        done(StateName(task.State()));
      },
      done);
}

}  // namespace store_services
