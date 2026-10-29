## 1.1.0

* **New Feature:** Added enterprise direct-download and silent/manual APK installation support via `EnterpriseInstaller`.
* **Flexible UI Options:** Built-in default download progress dialog supporting `forcedUpdate` and `bypassInDebug`, with a fully customisable `progressBuilder` hook.
* **Lightweight Networking:** Integrated stream-based binary downloading using the `http` package for optimal performance.
* **Security & Architecture:** Added native `FileProvider` and `Intent.ACTION_VIEW` integration via a dedicated MethodChannel pipeline.

---

## 1.0.0

* Initial release supporting native Android/iOS and custom server-driven update flows.
