# Ripplewood

A cozy one-tap fishing game for iPhone. Cast, wait for the bite, tap at the right moment,
sell your catch, and restore an overgrown pond into a garden. No timers, no fail state.

## Running

1. Open `Ripplewood.xcodeproj` in **Xcode 16 or newer** (the project uses folder-synchronized
   groups, so any file you add under `Ripplewood/` is picked up automatically).
2. Pick an iPhone simulator and press **Run**. To run on a device, choose your team under
   *Signing & Capabilities* (and change the bundle id `cc.tstech.ripplewood` if needed).

Requirements: iOS 17+, portrait iPhone only, no third-party dependencies.

## How to play

- **Tap anywhere** to cast. The bobber lands and bobs.
- Small **nibbles** tease you. Tapping on a nibble (or too early) spooks the fish. No penalty.
- **The bite**: the bobber dips with a splash, a strong haptic and a "!". Tap now!
  - **Perfect** (first ~0.28 s): bonus rarity roll, bigger fish, +25% coins
  - **Good** (up to ~0.65 s): normal catch
  - Too late: the fish escapes with a playful splash
- Rarer fish have tighter windows.
- Open the **bucket** (top bar) to sell fish, then **Restore** the pond with your coins.

## Project layout

```
Ripplewood/
  App/RipplewoodApp.swift        App entry, owns the GameStore
  Model/
    FishCatalog.swift            ← all 15 fish (add new fish here)
    Upgrade.swift                ← the 10 restoration upgrades, costs and effects
    Balance.swift                ← every tuning knob (timing windows, weights, idle rates)
    Conditions.swift             Time of day (device clock) + seeded weather
    Fish.swift, SaveData.swift   Data types, tolerant JSON save format
  Game/
    GameStore.swift              Single source of truth: coins, bucket, log, upgrades, idle rewards
    FishPicker.swift             Rarity-weighted, condition-aware fish selection
  Scene/
    PondScene.swift              SpriteKit scene + cast → wait → bite → hook state machine
    PondScene+World.swift        Sky, pond, weather, effects, palette transitions
    PondScene+Decor.swift        Overgrowth and the 10 upgrade decorations + bloom animations
    PondPalette.swift            Colors per time of day / weather
    SceneSupport.swift           Z-order, procedural textures, optional-art loader, fish sprite
  Services/
    AudioManager.swift           AVAudioEngine ambience + SFX (mixes with other audio)
    Synth.swift                  All sounds are synthesised in code; no audio files
    Haptics.swift
  Views/                         SwiftUI: top bar, catch card, Bucket, Restore, Fish Log, Settings, away card
```

## Art and sound

Everything is drawn with placeholder shapes so the game is fully playable without assets.
To swap in real art, add images to `Assets.xcassets/Art` with these names; the code picks
them up automatically and falls back to shapes when they're missing:

| Image name | Replaces |
| --- | --- |
| `fish_<id>` (e.g. `fish_goldenKoi`) | Fish in the catch leap, catch card, bucket and Fish Log |
| `bobber` | The bobber |
| `decor_dock`, `decor_boathouse`, `decor_cherryTree` | Those upgrade decorations |

All sounds (ambient water/birds/crickets/rain, plop, splash, chime, coins, upgrade sparkle)
are generated at launch in `Synth.swift`, so there are no licensing concerns.

## Balancing

Costs total 29,440 coins. A Monte-Carlo simulation of the catalog (85% catch rate, 30%
perfects, a realistic time-of-day/weather mix) gives:

- first upgrade (60 coins): about 1–2 minutes
- full restoration: about 4 hours of active play, before idle rewards

The Golden Koi needs night + rain + all 10 upgrades, then has a ~1% chance per bite.
All knobs live in `Model/Balance.swift` and `Model/Upgrade.swift`.

## Debug tools

Debug builds add a **Debug** section to Settings: force the time of day and weather, add
coins, simulate 8 hours away (to test idle rewards), and unlock every upgrade.

## Out of scope for v1

Multiplayer, leaderboards, iPad, Android, push notifications, ads and purchases. Purchases
go through `GameStore`'s private wallet (`earn` / `spend`) and the `Purchasable` protocol, so
a shop can be added later without restructuring.
