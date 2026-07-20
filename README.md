**Blade Ball Remake — Core Gameplay Scripts**

This repository contains a set of Lua/Luau scripts built in Roblox Studio that recreate the core mechanics of *Blade Ball*: ball spawning and dodging, parry timing, curved trajectory/targeting behavior, visual effects, and basic network performance diagnostics.

**Scripts included:**

**`BallSpawnerScript.lua`** (Server)
Handles the spawning and lifecycle of the balls used in the core dodge/parry loop — the central mechanic players interact with throughout a match.

**`parryinput.lua`** (Client)
Listens for player input and timing to detect and trigger a parry attempt. Runs on the client for responsive, low-latency input detection before the action is validated/handled elsewhere.

**`AntiShieldspawn.lua`** (Server)
A safeguard script that watches every player's character and automatically strips any `ForceField` instance that gets added to it — whether present on spawn or added later. Prevents unintended invulnerability from lingering or exploited shields.

**`starburstVFX.lua`** (Module, place in `ReplicatedStorage`)
A reusable VFX module exposing two functions:
- `PlayHit()` — spawns a billboard image "starburst" spark at a hit position, tweening it to grow and fade out. Used for parry-hit feedback.
- `PlayShield()` — spawns a translucent `ForceField`-material shield panel in front of a character that fades out over time. Used for shield/block visual feedback.

Both are color-customizable and self-cleaning (using `Debris`), so they can be called from either server or client code without leaving effects behind.

**`Pingpongserver.lua`** (Server)
Creates an `UnreliableRemoteEvent` named `PingPong` in `ReplicatedStorage` and echoes back any timestamp a client sends — the server half of a round-trip latency measurement system.

**`Pingfpsdisplay.lua`** (Client)
Builds a small on-screen HUD showing live FPS and ping. FPS is calculated from `RenderStepped` frame timing; ping is calculated by repeatedly firing timestamps to the `PingPong` remote and averaging the round-trip time over a rolling sample window.

**How it fits together:**
Together, these scripts form the foundation of a Blade Ball–style game — ball spawning and parry mechanics as the core gameplay loop, VFX for player feedback, a forcefield sanitizer for fairness/anti-exploit purposes, and a ping/FPS display for performance visibility during testing and play.

---

**Setup Guide**

**Step: Open your place**
Open the Roblox place you want to add these mechanics to in Roblox Studio.

**Step: Add the server scripts**
Go to `ServerScriptService` in the Explorer, and insert each of these as a regular **Script** (right-click `ServerScriptService` → Insert Object → Script, then paste the code and rename it to match the filename):
- `BallSpawnerScript`
- `AntiShieldspawn`
- `Pingpongserver`

These run on the server because they control gameplay state, character safety, and networking — things that must not be trusted to the client.

**Step: Add the shared VFX module**
Go to `ReplicatedStorage`, insert a **ModuleScript**, rename it `StarBurstVFX`, and paste in the contents of `starburstVFX.lua`. It's a module (not a plain Script) because both the server and client need to `require()` it and call its functions directly — a ModuleScript is the only script type that can be required like this.

**Step: Add the client scripts**
Go to `StarterPlayerScripts`, and insert each of these as a **LocalScript**:
- `parryinput`
- `Pingfpsdisplay`

These run on the client because they handle input and UI, which need to feel instant and shouldn't add server load.

**Step: Confirm the remote event exists**
You don't need to create anything manually here — `Pingpongserver.lua` automatically creates the `PingPong` `UnreliableRemoteEvent` inside `ReplicatedStorage` the first time the server starts. Just make sure `Pingpongserver` is actually running (Step 2) before testing, or the ping HUD will error trying to find it.

**Step: Hook StarBurstVFX into your gameplay code**
`starburstVFX.lua` doesn't call itself — it's a toolbox other scripts use. In your parry-handling code (wherever a successful parry or hit is detected), call:
- `StarBurstVFX.PlayHit(character, hitPosition, hitNormal)` when a hit lands
- `StarBurstVFX.PlayShield(character)` when a shield/block effect should show

Make sure to `require()` the module first: `local StarBurstVFX = require(game.ReplicatedStorage.StarBurstVFX)`.

**Step: Test it**
Use Play Solo to check that the FPS/ping HUD appears in the bottom-left corner and updates correctly. Use Studio's "Start Server + 2 Players" test mode (or publish and test with a friend) to confirm parry input, ball spawning, and the forcefield stripper all behave correctly across multiple clients.
