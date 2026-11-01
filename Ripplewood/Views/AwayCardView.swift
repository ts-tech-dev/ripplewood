import SwiftUI

struct AwayCardView: View {
    let report: AwayReport
    let onDismiss: () -> Void

    private var durationText: String {
        Duration.seconds(report.duration)
            .formatted(.units(allowed: [.hours, .minutes], width: .wide))
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "leaf.fill")
                .font(.largeTitle)
                .foregroundStyle(Color(hex: 0x6FAF6A))
            Text("While you were away…")
                .font(.title3.weight(.bold))
            Text("You were gone for \(durationText). Ripplewood kept itself busy.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if report.coins > 0 {
                HStack(spacing: 6) {
                    Text("+")
                    CoinAmount(amount: report.coins, size: 20)
                }
                .font(.title2.weight(.bold))
            }

            if !report.fish.isEmpty {
                VStack(spacing: 6) {
                    Text("\(report.fish.count) fish swam into your bucket")
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 6) {
                        ForEach(report.fish) { fish in
                            if let species = fish.species {
                                FishIllustration(species: species).frame(width: 40, height: 26)
                            }
                        }
                    }
                }
            }

            Button(action: onDismiss) {
                Text("Lovely!")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0x4A9E6B))
            .padding(.top, 4)
        }
        .padding(24)
        .frame(maxWidth: 340)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
    }
}
