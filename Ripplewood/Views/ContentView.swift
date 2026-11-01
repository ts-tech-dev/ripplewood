import Combine
import SpriteKit
import SwiftUI

enum SheetKind: String, Identifiable {
    case bucket, restore, log, settings
    var id: String { rawValue }

    var detents: Set<PresentationDetent> {
        switch self {
        case .log: [.large]
        default: [.medium, .large]
        }
    }
}

struct ContentView: View {
    @Environment(GameStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var scene = PondScene.make()
    @State private var sheet: SheetKind?

    private let clock = Timer.publish(every: 20, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            SpriteView(scene: scene, preferredFramesPerSecond: 60)
                .ignoresSafeArea()
                .accessibilityLabel("Pond. Tap anywhere to cast, then tap again when a fish bites.")
                .accessibilityAddTraits(.allowsDirectInteraction)

            VStack(spacing: 8) {
                TopBar(onBucket: { sheet = .bucket })
                Spacer()
                if let event = store.presentedCatch {
                    CatchCardView(event: event, showTip: store.data.totalCaught <= 2)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onTapGesture { store.presentedCatch = nil }
                }
                BottomBar(sheet: $sheet)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
            .animation(.spring(response: 0.4, dampingFraction: 0.82), value: store.presentedCatch)

            if let report = store.awayReport {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .onTapGesture { store.awayReport = nil }
                    .transition(.opacity)
                AwayCardView(report: report) { store.awayReport = nil }
                    .padding(24)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.25), value: store.awayReport)
        .sheet(item: $sheet) { kind in
            Group {
                switch kind {
                case .bucket: BucketView()
                case .restore: RestoreView()
                case .log: FishLogView()
                case .settings: SettingsView()
                }
            }
            .environment(store)
            .fontDesign(.rounded)
            .presentationDetents(kind.detents)
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            scene.attach(store: store)
            AudioManager.shared.start()
            AudioManager.shared.setAmbience(store.conditions.time, raining: store.conditions.weather == .rain)
            Haptics.prepare()
            store.appBecameActive()
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                store.appBecameActive()
                AudioManager.shared.resume()
            case .background:
                store.appWentToBackground()
            default:
                break
            }
        }
        .onChange(of: store.owned) { old, new in
            scene.applyUpgrades(new, animating: new.subtracting(old))
        }
        .onChange(of: store.conditions) { _, new in
            scene.applyConditions(new, animated: true)
            AudioManager.shared.setAmbience(new.time, raining: new.weather == .rain)
        }
        .onReceive(clock) { _ in
            store.refreshConditions()
        }
    }
}

struct TopBar: View {
    @Environment(GameStore.self) private var store
    let onBucket: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                CoinAmount(amount: store.coins, size: 18)
                    .font(.headline)
                    .pill()
                    .animation(.snappy, value: store.coins)

                Button(action: onBucket) {
                    HStack(spacing: 6) {
                        Image(systemName: "basket.fill")
                        Text("\(store.bucket.count)")
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    .font(.headline)
                    .pill()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Bucket, \(store.bucket.count) fish")

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: store.conditions.time.symbol)
                    Image(systemName: store.conditions.weather.symbol)
                }
                .font(.subheadline)
                .symbolRenderingMode(.multicolor)
                .pill()
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(store.conditions.time.label), \(store.conditions.weather.label)")
            }

            HStack(spacing: 8) {
                Text("Ripplewood is \(Int((store.restoration * 100).rounded()))% restored")
                    .font(.caption.weight(.semibold))
                ProgressView(value: store.restoration)
                    .tint(Color(hex: 0x6FAF6A))
                    .frame(width: 70)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.top, 4)
    }
}

struct BottomBar: View {
    @Environment(GameStore.self) private var store
    @Binding var sheet: SheetKind?

    var body: some View {
        HStack(spacing: 22) {
            RoundButton(symbol: "leaf.fill", label: "Restore", badge: store.canAffordNextUpgrade) { sheet = .restore }
            RoundButton(symbol: "book.fill", label: "Fish Log") { sheet = .log }
            RoundButton(symbol: "gearshape.fill", label: "Settings") { sheet = .settings }
        }
        .frame(maxWidth: .infinity)
    }
}

struct RoundButton: View {
    let symbol: String
    let label: String
    var badge = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.title3.weight(.semibold))
                    .frame(width: 54, height: 54)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(alignment: .topTrailing) {
                        if badge {
                            Circle()
                                .fill(Color(hex: 0xF4C64E))
                                .frame(width: 14, height: 14)
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .offset(x: 2, y: -2)
                        }
                    }
                Text(label)
                    .font(.caption2.weight(.semibold))
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            }
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(badge ? "\(label), upgrade available" : label)
    }
}

extension View {
    func pill() -> some View {
        padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }
}
