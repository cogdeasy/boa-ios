# Bank of America Mobile Banking — iOS

Retail mobile banking app for Bank of America customers. Customers sign in with their Online ID,
see their deposit accounts, search transaction history, move money between their own accounts, pay bills
and send money to other people.

| | |
|---|---|
| Bundle ID | `com.bofa.mobile` (`.dev` for Debug, `.mock` for Mock) |
| Minimum iOS | 15.0 |
| Language | Swift 5 (UIKit, with SwiftUI for newer screens) |
| Dependencies | Swift Package Manager: SnapKit 5.0.1, `BoAFoundation` (local package) |
| Backends | core-banking `:8080/api/v1`, payments hub `:8081/api/v1/payments` |
| CI | Jenkins (`Jenkinsfile`) → `scripts/ci-build.sh` |
| Owner | Mobile Platform — iOS (mobile-ios@bofa.com) |

## Features

| Screen | Tech | Backend calls |
|---|---|---|
| Sign in | UIKit (`LoginViewController`) | `GET /customers/me` (HTTP Basic) |
| Accounts overview | UIKit (`AccountsViewController`) | `GET /customers/{cif}/accounts` |
| Account activity + search | UIKit (`TransactionsViewController`, `UISearchController`) | `GET /accounts/{n}`, `GET /accounts/{n}/transactions`, `GET /transactions/search` |
| Transfer between own accounts | SwiftUI (`TransferView`) | `POST /transfers` |
| Pay & Send hub | SwiftUI (`PaymentsHubView`, `BillPayView`, `SendMoneyView`) | `GET /payees`, `POST /bill`, `POST /p2p`, `GET /history` |
| More (profile, sign out) | UIKit (`MoreViewController`) | – |

## Getting started

Requirements: macOS with Xcode 15 or later and an iOS Simulator runtime.

```sh
git clone https://github.com/cogdeasy/boa-ios.git
cd boa-ios
open BofAMobile.xcodeproj
```

Pick a scheme and press Run:

| Scheme | Configuration | Talks to |
|---|---|---|
| `BofAMobile-Mock` | Mock | In-process mock backend — no services needed. Use this for UI work. |
| `BofAMobile` | Debug | core-banking on `localhost:8080`, payments hub on `localhost:8081`. Set `BOA_ENV=UAT` in the scheme to point at UAT. |
| (archive) | Release | Production gateway |

From the command line:

```sh
scripts/run-simulator.sh        # builds the Mock scheme, boots an iPhone 17 simulator, installs and launches
scripts/ci-build.sh             # what Jenkins runs: build + unit tests (Mock scheme) + BoAFoundation tests
```

Seed sign-ins (local profile and Mock):

| Online ID | Passcode | Accounts |
|---|---|---|
| `dana.whitfield` | `Welcome1!` | Advantage Checking `********3455`, Advantage Savings `********3463` |
| `marcus.oyelaran` | `Welcome1!` | Checking `********8218`, Savings `********8226` |

### Running against the real services

Start the BofA Core Platform locally (core-banking on `:8080`, payments hub on `:8081`) with its
`local` profile, then run the `BofAMobile` scheme. The Simulator shares the Mac's network, so
`localhost` reaches the services directly.

## Architecture

```
BofAMobile/
  App/            AppDelegate, SceneDelegate, AppCoordinator (login → tab bar)
  Config/         AppEnvironment (per-build base URLs), Info.plist
  Networking/     APIClient (URLSession), Endpoint, APIError, NetworkLogger
  Services/       SessionManager, AccountService + AccountsStore, TransferService, PaymentsService,
                  CredentialStore
  Models/         Codable models matching the platform API contract
  Features/       Login, Accounts, Transactions (UIKit) · Transfer, Payments (SwiftUI) · More
  Routing/        DeepLinkRouter (bofa:// links)
  Mock/           MockURLProtocol + MockBackend + seed data (Mock configuration only)
  Common/         Theme, shared UI helpers
Packages/BoAFoundation/   Money, AccountNumbers, BankDates — Swift ports of boa-common
BofAMobileTests/  XCTest unit tests
```

- **Navigation**: `AppCoordinator` owns the window. It shows the login screen, then a `UITabBarController`
  with Accounts, Transfer, Pay & Send and More. SwiftUI screens are hosted in `UIHostingController`.
- **State**: `SessionManager.shared` holds the signed-in customer; `AccountsStore.shared` caches accounts
  as an `ObservableObject` for SwiftUI and posts `.accountsDidChange` for UIKit screens.
- **Networking**: `APIClient.shared` builds requests from `Endpoint` values, adds HTTP Basic credentials and
  a correlation ID, decodes JSON with `Codable` and maps HTTP errors (401/403/404/409/422) to `APIError`.
  Completion handlers are delivered on the main queue.
- **Money and dates**: amounts are decimal strings on the wire (`"125.40"`) and `Money` (Decimal) in the app;
  account numbers are always shown masked (`********3455`); dates are `yyyy-MM-dd` in America/New_York.

## How the app talks to core-banking

All calls follow the BofA Core Platform API contract (`docs/API.md` in the core platform repo).

1. **Sign in.** core-banking authenticates with HTTP Basic against its user store. The app verifies the
   credentials and resolves the customer's CIF by calling `GET /customers/me` (CUSTOMER role only; teller
   and ops users get `403`). A `401` means bad credentials. Every later request carries the same Basic header.
2. **Accounts.** `GET /customers/{cif}/accounts` returns `Account` objects with ledger, available and hold
   balances. The `CUSTOMER` role only sees its own accounts (`403` otherwise).
3. **Activity.** `GET /accounts/{n}/transactions?page=0&size=50` for the list; search uses
   `GET /transactions/search?q=…&accountNumber=…` (free-text over the description, debounced 300 ms).
4. **Transfers.** `POST /transfers` with `fromAccount`, `toAccount`, `amount`, `memo` and an
   `idempotencyKey` (one per form, reused on retry). `422 NSF` / `422 LIMIT_EXCEEDED` / `409 DUPLICATE`
   are shown as inline errors.
5. **Payments hub.** Bill pay and send-money go to the payments hub (`:8081/api/v1/payments`), which posts
   the money movement through core-banking `POST /transfers` to the suspense GL. Requests also carry the
   mobile channel's `X-BOA-Client-Id` / `X-BOA-Client-Secret` headers.

The Mock configuration swaps in `MockURLProtocol`, which answers the same endpoints from `MockBackend`
(seed customers, accounts, ~40 transactions, payees and payment history). Balances change as you transfer
and pay, for the life of the app process.

## Testing

```sh
xcodebuild test -project BofAMobile.xcodeproj -scheme BofAMobile-Mock \
  -destination 'platform=iOS Simulator,name=iPhone 17'
(cd Packages/BoAFoundation && xcodebuild test -scheme BoAFoundation -destination 'platform=iOS Simulator,name=iPhone 17')
```

Unit tests cover model decoding, endpoint construction, `Money`/`AccountNumbers` and the mock backend's
transfer rules. View controllers, view models, `SessionManager` and the payments flows have no tests yet.

## Project file

`BofAMobile.xcodeproj` is generated from `project.yml` with [XcodeGen](https://github.com/yonaskolb/XcodeGen).
After adding or moving files run `xcodegen generate` and commit both.
