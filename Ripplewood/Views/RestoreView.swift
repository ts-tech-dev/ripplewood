import SwiftUI

struct RestoreView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ripplewood is \(Int((store.restoration * 100).rounded()))% restored")
                            .font(.headline)
                        ProgressView(value: store.restoration)
                            .tint(Color(hex: 0x6FAF6A))
                        if store.restoration >= 1 {
                            Text("The pond is fully restored. Something golden stirs on rainy nights…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    ForEach(UpgradeCatalog.all) { upgrade in
                        UpgradeRow(upgrade: upgrade, status: store.status(of: upgrade), discovered: store.data.log) {
                            if store.buy(upgrade) { dismiss() }
                        }
                    }
                }
            }
            .navigationTitle("Restore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CoinAmount(amount: store.coins, size: 16).font(.subheadline.weight(.semibold))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct UpgradeRow: View {
    let upgrade: Upgrade
    let status: UpgradeStatus
    let discovered: [String: LogEntry]
    let onBuy: () -> Void

    private var newFish: [FishSpecies] { FishCatalog.requiring(upgrade.id) }

    private var unlockText: String? {
        guard !newFish.isEmpty else { return nil }
        let names = newFish.map { discovered[$0.id] != nil ? $0.name : "???" }
        return "New fish: " + names.joined(separator: ", ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: upgrade.symbol)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(iconBackground, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(status == .locked ? Color.secondary : Color.white)

            VStack(alignment: .leading, spacing: 3) {
                Text(upgrade.name).font(.body.weight(.semibold))
                Text(upgrade.blurb)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(upgrade.perks, systemImage: "sparkles")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color(hex: 0x4A8F5E))
                if let unlockText {
                    Label(unlockText, systemImage: "fish.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color(hex: 0x3C7DBF))
                }
                action.padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .opacity(status == .locked ? 0.6 : 1)
    }

    private var iconBackground: Color {
        switch status {
        case .owned: Color(hex: 0x6FAF6A)
        case .available: Color(hex: 0x4A9E9E)
        case .locked: Color.gray.opacity(0.2)
        }
    }

    @ViewBuilder
    private var action: some View {
        switch status {
        case .owned:
            Label("Restored", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: 0x4A8F5E))
        case .available(let affordable):
            Button(action: onBuy) {
                HStack(spacing: 6) {
                    Text("Restore")
                    CoinAmount(amount: upgrade.cost, size: 14)
                }
                .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0x4A9E6B))
            .disabled(!affordable)
        case .locked:
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                CoinAmount(amount: upgrade.cost, size: 13)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
    }
}
