import SwiftUI

struct SettingsView: View {
  @ObservedObject var store: AccountStore

  var body: some View {
    TabView {
      accountsTab
        .tabItem { Label("Accounts", systemImage: "person.2") }
      generalTab
        .tabItem { Label("General", systemImage: "gearshape") }
    }
    .frame(minWidth: 560, minHeight: 390)
  }

  private var accountsTab: some View {
    VStack(spacing: 0) {
      if store.accounts.isEmpty {
        ContentUnavailableView(
          "No Accounts",
          systemImage: "person.crop.circle.badge.plus",
          description: Text("Add a ChatGPT account to monitor Codex limits.")
        )
      } else {
        List {
          ForEach(store.accounts) { account in
            accountEditor(account)
          }
        }
      }

      Divider()
      HStack {
        Button {
          Task { await store.addAccount() }
        } label: {
          Label("Add Account", systemImage: "plus")
        }
        .disabled(!store.pendingLoginAccounts.isEmpty)

        if !store.pendingLoginAccounts.isEmpty {
          ProgressView("Waiting for browser sign-in")
            .controlSize(.small)
        }
        Spacer()
      }
      .padding(12)
    }
  }

  private func accountEditor(_ account: AccountProfile) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        TextField(
          "Account label",
          text: Binding(
            get: { account.label },
            set: { store.updateLabel(id: account.id, label: $0) }
          )
        )
        .textFieldStyle(.roundedBorder)

        Toggle(
          "Enabled",
          isOn: Binding(
            get: { account.enabled },
            set: { store.setEnabled(id: account.id, enabled: $0) }
          )
        )
        .toggleStyle(.switch)
        .labelsHidden()
      }

      HStack {
        Text(identityText(for: account))
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        Button("Sign In Again") {
          Task { await store.authenticate(id: account.id) }
        }
        .disabled(store.pendingLoginAccounts.contains(account.id))

        Button(role: .destructive) {
          Task { await store.removeAccount(id: account.id) }
        } label: {
          Image(systemName: "trash")
        }
        .help("Remove account")
      }
    }
    .padding(.vertical, 6)
  }

  private var generalTab: some View {
    Form {
      Toggle("Start at login", isOn: $store.launchAtLogin)

      Picker("Refresh every", selection: $store.refreshInterval) {
        ForEach(RefreshInterval.allCases) { interval in
          Text(interval.label).tag(interval)
        }
      }
      .pickerStyle(.menu)

      LabeledContent("Codex executable") {
        HStack {
          TextField("/path/to/codex", text: $store.codexExecutablePath)
            .textFieldStyle(.roundedBorder)
          Button("Verify") { store.validateRuntimePath() }
        }
      }

      Text(
        "Credentials are stored by Codex in the macOS Keychain. Quitting preserves sign-ins; removing an account signs it out and deletes its local profile. This app does not accept or retain API keys."
      )
      .font(.caption)
      .foregroundStyle(.secondary)
    }
    .formStyle(.grouped)
    .padding()
  }

  private func identityText(for account: AccountProfile) -> String {
    if let identity = account.verifiedIdentityHint {
      let plan = account.planType.map { " · \($0.capitalized)" } ?? ""
      return "\(identity)\(plan)"
    }
    return "Not signed in"
  }
}
