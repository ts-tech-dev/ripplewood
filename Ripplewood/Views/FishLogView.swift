import SwiftUI

struct FishLogView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("\(store.discoveredCount) of \(FishCatalog.all.count) discovered")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(FishCatalog.all) { species in
                            let entry = store.data.log[species.id]
                            NavigationLink {
                                FishDetailView(species: species, entry: entry)
                            } label: {
                                FishLogCell(species: species, entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Fish Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct FishLogCell: View {
    let species: FishSpecies
    let entry: LogEntry?

    var body: some View {
        VStack(spacing: 6) {
            FishIllustration(species: species, silhouette: entry == nil)
                .frame(height: 46)
            Text(entry == nil ? "???" : species.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let entry {
                Text("×\(entry.count)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text(species.hint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 130)
        .padding(10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(species.rarity.tint)
                .frame(width: 8, height: 8)
                .padding(8)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct FishDetailView: View {
    let species: FishSpecies
    let entry: LogEntry?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                FishIllustration(species: species, silhouette: entry == nil)
                    .frame(height: 140)
                    .padding(.top, 24)
                Text(entry == nil ? "Undiscovered" : species.name)
                    .font(.title2.weight(.bold))
                RarityPill(rarity: species.rarity)
                if let entry {
                    Text(species.flavor)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    VStack(spacing: 8) {
                        stat("Caught", "\(entry.count)")
                        stat("Biggest", String(format: "%.1f cm", entry.biggest))
                        stat("First caught", entry.firstCaught.formatted(date: .abbreviated, time: .omitted))
                        stat("Size range", String(format: "%.0f–%.0f cm", species.sizeRange.lowerBound, species.sizeRange.upperBound))
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                } else {
                    Label(species.hint, systemImage: "lightbulb")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func stat(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
        .font(.subheadline)
    }
}
