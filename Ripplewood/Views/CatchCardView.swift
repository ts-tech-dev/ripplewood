import SwiftUI

struct CatchCardView: View {
    let event: CatchEvent
    var showTip = false

    var body: some View {
        HStack(spacing: 14) {
            FishIllustration(species: event.species)
                .frame(width: 84, height: 56)
                .padding(8)
                .background(Color(hex: event.species.color).opacity(0.2), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(event.species.name)
                        .font(.headline)
                    if event.isNew {
                        Text("NEW!")
                            .font(.caption2.weight(.heavy))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: 0xE86A8E), in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                HStack(spacing: 6) {
                    RarityPill(rarity: event.species.rarity)
                    if event.fish.perfect {
                        Label("Perfect", systemImage: "star.fill")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                    }
                }
                HStack(spacing: 6) {
                    Text("\(event.fish.size, specifier: "%.1f") cm ·")
                    CoinAmount(amount: event.fish.value, size: 13)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                if showTip {
                    Text("Fish go to your bucket — sell them for coins.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            if event.species.rarity >= .rare {
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(event.species.rarity.tint.opacity(0.7), lineWidth: 2)
            }
        }
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
    }
}
