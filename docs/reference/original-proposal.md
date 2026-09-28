# Original Proposal and Superseded Assumptions

**Source:** `/Users/barrowkwan/Downloads/codex-usage-mobile-dashboard-design.md`
**Source date:** September 28, 2026
**Status:** Superseded reference

The original proposal described an iPhone dashboard backed by a headless Linux collector, HAProxy, and one local Codex App Server process per account. It established the core requirement: show when each independently billed ChatGPT/Codex account can be used again, while preserving every reported quota window and clearly identifying stale data.

The following ideas remain valid:

- Keep account authentication isolated.
- Read account identity and rate limits through Codex App Server without starting a model turn.
- Treat `usedPercent` as usage consumed and derive remaining percentage as `max(0, 100 - usedPercent)`.
- Use the server-provided `resetsAt` timestamp; never infer it from window duration.
- Keep subscription quota, workspace credit balance, and earned reset credits separate.
- Keep the last successful result during transient failures and mark it stale.
- Never expose controls that purchase credits, consume resets, or start Codex work.

The following architecture is superseded:

- iPhone as the initial client.
- Linux collector host.
- HAProxy, VPN, and collector HTTP API.
- Remote onboarding and phone authentication.
- systemd deployment.

The current design replaces those components with one native macOS menu bar app that owns the local UI, process supervision, cache, and polling.
