import SwiftUI

struct BucketView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private var fish: [CaughtFish] { store.bucket.reversed() }

    var body: some View {
        NavigationStack {
            Group {
                if fish.isEmpty {
                    ContentUnavailableView("Your bucket is empty",
                                           systemImage: "basket",
                                           description: Text("Cast a line to catch some fish."))
                } else {
                    List {
                        ForEach(fish) { item in
                            if let species = item.species {
                                BucketRow(fish: item, species: species) { store.sell(item) }
                                    .swipeActions {
                                        Button("Sell") { store.sell(item) }.tint(Color(hex: 0xD9A520))
                                    }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .animation(.default, value: store.bucket)
                }
            }
            .navigationTitle("Bucket")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !fish.isEmpty {
                    Button {
                        store.sellAll()
                    } label: {
                        HStack {
                            Text("Sell All")
                            CoinAmount(amount: store.bucketValue, size: 16)
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: 0x4A9E6B))
                    .padding()
                    .background(.bar)
                }
            }
        }
    }
}

private struct BucketRow: View {
    let fish: CaughtFish
    let species: FishSpecies
    let onSell: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            FishIllustration(species: species)
                .frame(width: 52, height: 34)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(species.name).font(.body.weight(.semibold))
                    if fish.perfect {
                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(.orange)
                    }
                }
                HStack(spacing: 6) {
                    RarityPill(rarity: species.rarity)
                    Text("\(fish.size, specifier: "%.1f") cm")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button(action: onSell) {
                CoinAmount(amount: fish.value, size: 14)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .accessibilityLabel("Sell \(species.name) for \(fish.value) coins")
        }
        .padding(.vertical, 2)
    }
}
