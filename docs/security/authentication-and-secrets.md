# Authentication and Secrets

## Authentication decision

The primary onboarding method is **Sign in with ChatGPT**. Official OpenAI documentation distinguishes subscription access through ChatGPT sign-in from usage-based access through a Platform API key. The App Server method `account/rateLimits/read` returns ChatGPT rate limits.

An OpenAI Platform API key must not be accepted in v1 because it would create a second product with different billing and rate-limit semantics. A later API-usage mode requires a separate design and visibly separate account type.

## Login flow

- Start `account/login/start` with type `chatgpt` and open the returned `authUrl` in the user's default browser.
- Let App Server own the localhost callback and token refresh lifecycle.
- Poll `account/read` after opening the browser and accept the profile only when it reports a ChatGPT identity.
- Time out an abandoned login attempt after five minutes; the user can retry from Settings.
- Reauthentication repeats the flow for only the affected account.

## Credential storage

- Configure Codex with `cli_auth_credentials_store = "keyring"`.
- Treat inability to use Keychain as a blocking account error.
- Never select `auto`, because it may fall back to plaintext file storage.
- Never read, display, log, export, synchronize, or back up token material.
- Never store API keys or token material in UserDefaults, SwiftData, the JSON cache, source files, process arguments, crash reports, or analytics.
- Keep account profile directories user-only and exclude them from cloud backup where supported.

Use standard Keychain protection provided by the Codex credential store. The app should not add biometric prompts to background polling because that would prevent unattended refresh. Access remains constrained to the logged-in macOS user and unlocked login Keychain.

## Threat boundaries

A ChatGPT/Codex session is broader than a read-only usage token. The app enforces read-only behavior by allowing only initialization, account identity, login/logout, and rate-limit read methods in its protocol adapter. It does not expose a generic App Server request interface.

Redact secrets at the logging boundary. Release builds log method names, durations, status categories, and account UUID prefixes only. Raw JSON-RPC bodies are forbidden.

Removing an account stops its process, invokes account logout when possible, removes local metadata, and deletes its isolated `CODEX_HOME`. If logout cannot be confirmed, the local profile is still removed and the app reports that condition. Quitting the app does not log accounts out or clear Keychain sessions.

## Official references

- [Codex authentication](https://developers.openai.com/codex/auth)
- [Codex App Server](https://learn.chatgpt.com/docs/app-server)
- [OpenAI API production practices](https://developers.openai.com/api/docs/guides/production-best-practices)
