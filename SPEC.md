# shunt: contact stock car racing, one simulation everywhere

"shunt" is British for a knock between cars. Lowercase wordmark, as with
bümbap.

shunt is an isometric, low-poly stock car racer for up to four players, where
bumping is the point. It is inspired by *3D Stock Car Championship* (Firebird,
1988, ZX Spectrum) but has its own name, look and tracks. It is a Lab piece
for tomrhodes.it, and it shows what bümbap doesn't: animation, real-time
input, game feel, visual polish and, later, a server.

The core of the build is one **simulation** written in Haxe: car physics,
track, race rules and AI drivers. It compiles to JavaScript for the browser
now, and for a Node server in phase 3, so the same classes decide the race on
both sides.

## 0. Phases

| Phase | What it adds | Done when |
|---|---|---|
| **1. Alone** (this spec) | Car physics, two tracks (an oval and a whacky one), three AI cars, keyboard and gamepad, HUD, sound | A 5-lap race against three AI cars is fun, on a phone and a desktop |
| 2. Same screen | 2–4 human players on one screen (keyboard halves and gamepads); AI fills the empty seats | Four people on one sofa can race |
| 3. Online | Colyseus rooms on the VPS; bots fill empty seats; netcode (section 9) | Two browsers on different networks race and bump with no snapping |

Phase 1 is built so that phases 2 and 3 are additions, not rewrites: the
simulation only knows about **inputs**, never about keys, gamepads or sockets.

Out of scope for now: repairs and pit stops, car setup, more than two
tracks, a track editor, championships, accounts.
One small, finished, fun race beats a big unfinished season.

## 1. What the player can do (phase 1)

| Feature | Detail |
|---|---|
| Race | Four cars on the chosen track: the player and three AI drivers. Grid start, 3-2-1 lights, 5 laps. Finishing order by laps done, then distance round the lap. |
| Drive | Throttle, brake (becomes reverse when nearly stopped), steer. Keyboard: arrows or WASD. Gamepad (standard mapping): right trigger throttle, left trigger brake, left stick steer. Touch: left and right thumbs steer, throttle on by default, a brake pad bottom right. |
| Contact | Cars bump, push and spin each other. A tap on a rear quarter turns the car hit; a hit square from behind shoves it. Walls take speed off and send sparks. |
| Damage | Hard hits dent the car and cost it speed; heavy damage pulls the steering to one side; a badly damaged car now and then drops oil, which takes away the grip of whoever drives over it. Walls are kinder than cars. Damage lasts the whole race (section 4b). |
| Recover | A car stuck or facing the wrong way for 3 s is put back on the centreline at the nearest point, facing the right way, at walking pace. Also on a key (R / gamepad Y). |
| HUD | Position (2nd / 4), lap (3 / 5), current and best lap time, a 3-2-1 start, a results table at the end with a Race again button. |
| Camera | Fixed isometric view; the whole track fits on screen at any aspect ratio (so phase 2 needs no split screen). |
| Sound | Each car's engine (pitch from speed, louder for the player's), tyre squeal from slip, a thump on contact scaled by impulse, a scrape on walls. |
| Pause | Esc / Start / a button: Resume, Restart, Mute. |

## 2. The shared parts

1. **Simulation** (`sim/`, Haxe): physics, track, race rules, AI drivers,
   seeded random numbers. No rendering, no DOM, no clock, no `Math.random`.
   Compiles to the browser build and, in phase 3, to an ES module with
   TypeScript definitions for the Colyseus room (as bümbap's engine does).
2. **Track data** (`tracks/oval.json`): centreline, width, walls, grid,
   start line, checkpoints, racing line. Read by the simulation, the
   renderer and the AI alike.
3. **Client** (`client/`, Haxe): rendering, input devices, sound, HUD.
   Reads the simulation's state; never changes it except through inputs.
4. **Checks** (`sim/test/`): headless checks of the simulation, run in CI
   (section 8).

## 3. Simulation API

```haxe
var race = new Race(Track.load(ovalJson), { cars: 4, laps: 5, seed: 1234 });

race.step(inputs);        // advance one fixed tick (1/120 s); inputs: one CarInput per car
race.state;               // RaceState: everything needed to draw and to resume
race.events;              // RaceEvent[] from the last step: contact, wall, lap, finish, lights
race.copyState();         // a deep copy (for prediction and replay in phase 3)
race.restoreState(state); // carry on from a copy

// CarInput: { throttle: 0..1, brake: 0..1, steer: -1..1, recover: Bool }
```

`RaceState` is `{ tick, phase (grid | lights | racing | finished), cars[],
order[], lightsLeft, oilPatches[], random }`, each car `{ x, y, heading, vx,
vy, spin, lap, progress, lapTimes[], finished, recoverTimer, damage,
nextOilTimer }`, `damage` being `{ front, rear, left, right }`, each 0–100,
and each oil patch `{ x, y, radius, timeLeft }`. The random generator's state
is part of the race state, so a copy carries on exactly as the original. Everything is plain data,
so it can be copied, compared, serialised and sent.

**Inputs from anywhere.** `Keyboard`, `Gamepad`, `TouchPads` and `AiDriver`
all produce a `CarInput`; in phase 3 so does the network. The race cannot
tell them apart. That one rule is what keeps phases 2 and 3 small.

**Fixed step.** The simulation always steps 1/120 s. The client runs as many
steps as real time demands (at most 8 per frame, so a stalled tab doesn't
spiral) and draws the cars between the last two states, so motion is smooth
at 60, 90, 120 or 144 Hz. Same inputs plus same seed give the same race, on
the same JavaScript engine.

## 4. Car physics

A flat-ground, top-down model (the track has no height in phase 1), drawn in
3D. It aims for arcade fun with believable weight: grip that lets go
progressively, sliding you can catch, and contact that transfers momentum.
Units are metres, seconds, kilograms. All numbers live in one `CarTuning`
class and are **starting values to tune by feel**.

| Quantity | Start value |
|---|---|
| Car body | 4.8 × 1.9 m, mass 1,400 kg, yaw inertia from the box |
| Axles | 1.4 m in front of and 1.4 m behind the centre of mass |
| Top speed | about 46 m/s (165 km/h); with drag it tops out near 44 m/s |
| 0–100 km/h | about 4 s |
| Lifting off | engine braking (5,000 N with the accelerator up): from top speed to 70 km/h in a few seconds |
| Steering | ±30° when slow, narrowing to ±6° at top speed; the wheel turns at most 7 rad/s, so keys feel smooth but quick |
| Grip | front 1.45 g, rear 1.55 g: off the power a car pushed too far runs wide and settles. Full throttle takes 20 % of the rear's grip, so on the power the tail drifts round |
| Sliding | a tyre past its best slip angle grips less, down to 80 % at twice that angle: what lets a drift happen and makes it something to hold |
| Steadying | a helping hand, as arcade racers have: the car's turning is drawn towards what its front wheels ask for (at 4 per second). A small correction stays small; countersteering catches a slide |

*Tuned 30 Oct after Tom's first drive:* steering felt heavy and then the car
spun with no warning; a 0.3 s tap at top speed turned it 93° into a spin
(now 20°, settling); lifting off took 1.3 km to slow from top speed to
70 km/h (now about 200 m). Earlier grip had the front at 1.15 g and the rear
at 1.3 g, with no sliding falloff and no steadying.

**Per tick, for each car:**

1. **Smooth the inputs**: steer and throttle move towards the input at a
   set rate (keys are on/off, cars shouldn't be).
2. **Velocity in the car's frame**: forward speed and sideways speed.
3. **Tyre forces** (a bicycle model): the slip angle at each axle from its
   sideways speed (including the spin) against the forward speed; sideways
   force grows with slip up to the axle's grip limit, then falls away to
   its sliding grip (the car slides). Below 2 m/s the model blends into
   simple kinematic steering, where the slip maths would be unstable.
4. **Steadying**: a twist drawing the car's spin towards what its front
   wheels ask for, never more than the grip allows at this speed.
5. **Drive and drag**: engine force tapering to zero at top speed; brakes
   and engine braking; rolling resistance; air drag growing with speed
   squared.
6. **Integrate** (semi-implicit Euler): speed, then position; spin, then
   heading.

**Contact.** Each car is an oriented box.
- *Car against car*: separating-axis test for overlap, giving the push-out
  direction, depth and a contact point. An impulse at the contact point,
  with restitution 0.3 and friction 0.4, changes both cars' speed and spin,
  so off-centre hits turn cars (the rear-quarter spin emerges from this
  rather than being scripted). The cars are pushed apart by 80 % of the
  overlap so they never sink into each other.
- *Car against wall*: each box corner against the wall segments, and each
  wall's end points against the box (so a car's side hitting the end of a
  barrier is caught too); restitution 0.2, sliding friction 0.6, the same
  push-out.
- Each contact adds a `RaceEvent` with its point and strength, for sparks,
  sound and screen shake.

At 120 ticks a second a car at top speed moves 0.35 m per tick, well under
its width, so nothing tunnels through walls or other cars.

## 4b. Damage

Bumping is the game, so ordinary bumping is free; only hard hits do harm.
Damage is part of the simulation (not just looks), so it is identical for
every player and on the server. All numbers live in a `DamageTuning` class
and are starting values to tune by feel.

**Taking damage.** Each car has four zones: front, rear, left, right, each
0–100. A contact's impulse is turned into a change of speed for the car hit
(impulse ÷ mass). From another car: below 3 m/s nothing happens, so nudges
and trading paint cost nothing; above it, 4 points per m/s over. Walls are
kinder, since scraping one is part of short-track racing: below 6 m/s
nothing, then 1.5 points per m/s (a 15° graze at top speed is about
13 m/s, so about 10 points). The damage goes on the side the hit came from,
the opposite way to the shove: a graze shoves a car sideways, so it marks
the side, not the front. A zone stops at 100. Damage lasts the whole race;
recovering (section 1) doesn't repair.

*Tuned 30 Oct after Tom's first drive:* a few grazes broke the steering and
started oil. Walls counted the same as cars (a graze did about 40 points),
and a hit near a corner counted as the front.

The car's **overall damage** is the average of the zones, weighted towards
the worst one (half the worst zone plus half the average), so one smashed
corner matters.

**What damage does**, growing smoothly with it rather than in steps:

| Effect | From | Start value |
|---|---|---|
| Less speed | overall damage | top speed and engine force fall by up to 25 % at 100; never lower, so a wreck can always finish |
| Steering pull | front damage above 50, towards the more damaged side | up to 4° of steering at 100, which the driver has to hold against; feels like a bent track rod |
| Less steering | front damage above 70 | the most steering falls by up to 30 % at 100 |
| Oil | overall damage above 80 ("badly damaged") | see below |

**Oil.** A badly damaged car drops an oil patch every now and again, not all
the time: the gap between drops is random, 4–10 s (from the race's seeded
random numbers, so it replays the same), shorter as damage rises. A patch is
a circle of about 2 m radius on the track under the car's rear, lasting
20 s and fading over its last 5 s. A car whose wheels are on oil has their
grip cut to 30 % (axle by axle). Oil only takes grip away: going straight
over it, nothing happens; in a bend, the car slides wide, and with the power
on the tail can come round. (For a few hours it also swung the tail round
by itself, which spun cars regardless; Tom found that too much.) At most 6 patches on the track at once; the
oldest goes first. The car that dropped it is caught by its own oil too.

**AI and damage.** AI drivers see oil patches ahead and steer round them,
with a chance of missing them that falls with skill. A damaged AI drives to
its car's lower top speed and holds against the pull, as a player does.

**Showing it** (section 10): dents at the contact point, steam from the bonnet
over 50 front damage, smoke above 80 overall, a dark sheen on oil patches, and
a small car outline in the HUD with each zone shaded by its damage.

## 5. Tracks

The fun of the original was its whacky tracks: little walls making S-bends
and odd shapes, not just ovals. So the track format takes **any layout**,
and phase 1 ships two tracks:

1. **Oval**: a short oval about 400 m round (a quarter mile, the classic
   short track): two 100 m straights and two bends of 32 m radius (25 m at
   first, too tight for the speed), about 165 × 78 m, three cars wide (14 m). Built first, to
   tune the physics on.
2. **A whacky one**: short free-standing walls dropped onto a wide arena to
   make S-bends, a chicane and a hairpin, with a narrow gap where cars have
   to queue and bump. Designed once the oval drives well.

A figure-of-eight with a crossing comes after phase 1 (the same format
handles it: the crossing is just two stretches of centreline that meet).

Each track is one JSON file (`tracks/oval.json`, …). It holds only a name,
a few points round the centreline (each with the track's width there) and
the barriers; the rest below is worked out from those when the track loads,
so nothing is written twice:
- **centreline**: a closed list of points, smoothed into a curve when loaded,
  with a distance along it, used for progress, recovery and the AI;
- **width** at each centreline point (tracks can pinch and widen), and the
  **edge walls** made from it;
- **barriers**: any number of free-standing walls, each a short list of
  points (a straight wall, an L, a curve), placed anywhere, inside the track
  or across it. These make the S-bends and chicanes. The physics sees edge
  walls and barriers alike, as segments;
- **start line** (where the centreline starts) and **grid**: four slots behind it, one car per row, alternating sides;
- **checkpoints**: a car's lap only counts once it has passed them in order
  (no cutting across the infield or round the wrong side of a barrier, no
  reversing over the line);
- **racing line**: the fastest safe speed at each point, from how sharply
  the centreline bends there and the braking needed before each bend
  (`RacingLine`), so the AI copes with any layout. The AI follows the
  centreline, each driver in its own lane, going round cars and oil.

Track geometry, barriers, the infield and the surroundings are all drawn
from the same file, so a new track is a new JSON file plus scenery. Barriers
are drawn as low walls (concrete blocks or stacked tyres). A track picker
before the race chooses which. A visual track editor would be a good later
Lab feature, but isn't needed: the JSON is written by hand.

## 6. Race rules

- **Lights**: cars held on the grid; three red lights a second apart, then
  green. Throttle before green revs the engine but the car stays put.
- **Progress**: laps done plus distance along the centreline. Order is by
  progress; ties by who got there first.
- **Lap**: counted crossing the start line forwards after every checkpoint.
- **Finish**: the race ends 10 s after the leader finishes, or when all cars
  have. Unfinished cars are placed by progress.
- **Recover**: see section 1. A recovered car is a ghost (no contact) for
  1.5 s, so it isn't put straight into another car.

## 7. AI drivers

Each AI is an `AiDriver` that reads the race state and returns a `CarInput`,
exactly as a player's device does.

- **Steering**: aim at a point on the racing line a lookahead ahead (longer
  at speed), steer by the angle to it, smoothed.
- **Speed**: brake when faster than the racing line's target at the
  lookahead point.
- **Traffic**: move off the line to pass a slower car ahead; if close behind
  and its **aggression** is high enough, aim at the car's rear quarter
  instead.
- **Character**: each AI has its own skill (how close to target speed it
  drives, how far it looks ahead) and aggression, from the seed, so races
  differ but replay the same.
- No rubber-banding in phase 1; if races feel one-sided, revisit.

## 8. Checks and measures

The simulation is checked headlessly (Node, no browser), as bümbap's engine is:

| Check | Pass |
|---|---|
| Straight line | Full throttle from rest reaches 100 km/h in 3.5–4.5 s and tops out just under top speed |
| Braking | From top speed, stops in a set distance; never goes backwards on brake alone until stopped |
| Corner | At the racing line's target speed, a car on the line stays within 1 m of it |
| Contact | A head-on and a side hit conserve momentum within 1 %; no overlap remains after the push-out |
| Walls | 10,000 random fast approaches: no car ends up outside the walls |
| Laps | Laps counted only in order; cutting the infield or reversing over the line counts nothing |
| AI | On each track, four AI cars race 100 seeded 5-lap races: every car not badly damaged reaches the last lap (the 10 s after the leader can stop the last finishing), but for at most 1 in 100 caught in a racing incident; none put back more than three times in a race |
| Barriers | 10,000 random fast approaches to each barrier, end-on and side-on: no car passes through |
| Damage threshold | A nudge under the harmless limit adds no damage; a 10 m/s hit from a car adds 28 to the side hit, and only that side; a graze marks the side, not the front; a top-speed graze along a wall does under a third of what a car would, and under a third of what bends the steering |
| Damage effects | At 100 overall the top speed is 75 % of new; the steering pull is to the damaged side; a car never stops being drivable |
| Oil | No oil below 80 overall; drops 4–10 s apart above it; going straight over oil doesn't turn a car; in a bend, the oily car turns less and slides more than a clean one |
| Repeatable | The same seed and inputs give a byte-identical final state |
| Copy | `copyState`, step, `restoreState`, step again: identical states |

In the browser (Playwright, as for bümbap): the page loads, a race starts,
keyboard input moves the car, the results table appears. Measured and
recorded: frame time on a phone-sized window with the CPU slowed 4×
(target: holds 60 fps), simulation cost per tick, bundle size.

## 9. Later phases, in short

**Phase 2: same screen.** A seat picker: each seat is Keyboard (left: WASD;
right: arrows), Gamepad 1–4, Touch, or AI. Car colours and names per seat.
The whole-track camera means no split screen. No changes to the simulation.

**Phase 3: online.**
- **Server**: a thin TypeScript Colyseus room on Tom's OVH VPS that runs the
  shared Haxe simulation at 120 Hz and sends state at 30 Hz. The state schema
  is written in TypeScript and generated for Haxe (colyseus-haxe).
- **Seats**: up to four; bots (the same `AiDriver`) fill empty ones and hand
  over when a player joins between races.
- **Your car**: predicted. Your inputs are applied at once locally and sent
  numbered; when the server's state arrives, restore it and replay your
  unconfirmed inputs (`copyState` / `restoreState` exist for this).
- **Other cars**: drawn about 100 ms in the past, interpolated between
  server states.
- **Contact under latency** (the hard part): when the server's answer
  disagrees with the prediction, the difference is eased in over about
  150 ms rather than snapped. Measured: how far corrections move a car, how
  often, at 50, 100 and 200 ms of added latency.
- **Floats**: the server corrects any drift, so exact determinism between
  Node and browsers isn't required, only that the drift is small. Measured,
  not assumed.

## 10. Rendering and game feel

- **three.js through Haxe externs** (decided 30 Oct: employers recognise it,
  its docs and examples are vast, and it keeps the "Haxe with the JS
  ecosystem" story). Only the externs the game uses are written, in
  `client/src/three/`. For now the page loads three.js r128, its last build
  with a global `THREE`, from cdnjs; moving to a current version as an ES
  module is a later step. An orthographic camera at the isometric angle
  (35.26° down), looking from whichever way round (in 15° steps) fills the
  screen best, so the oval lies across a wide screen and stands up on a
  phone.
- **Dents**: the car body is a low-poly mesh; a contact pushes in the
  vertices near its point, scaled by the damage it did. Drawn only, never fed
  back into the physics (the simulation's damage zones are the truth).
- **Low-poly** flat-shaded cars, walls, infield, stands and lights; cars built
  in Blender and loaded as glTF, simple boxes until then. Big readable
  numbers on the car roofs (the player's car marked clearly).
- **Feel**: body roll and pitch from the forces (drawn only, not simulated);
  tyre smoke and skid marks from slip; sparks and a short screen shake from
  contact strength; lights that actually count down.
- **Look**: its own palette and style, decided in a design pass before
  polish; flat placeholder colours until then.
- **Sound**: Web Audio (no Tone.js needed): a looped engine sample per car
  with playback rate from speed, plus one-shot hits and scrapes.

## 11. Code rules

**DRY above everything.** No repetition anywhere: every fact, number, rule
and piece of logic has exactly one source of truth.
- A number is written once (in `CarTuning`, `DamageTuning`, a track file) and
  read from there everywhere: by the simulation, the client, the tests and,
  later, the server. Tests take their expected values from the same tuning,
  not copies of them.
- A rule is written once, in the simulation. The client, the AI and the
  server ask the simulation; none of them re-works a rule out for itself.
- Words shown to the player live in one place, as bümbap's `PanelText` does.
- The network schema in phase 3 is generated from one definition, never
  written twice by hand.
- If the same two lines appear twice, they become one well-named function.

**Code that reads like plain language**, as far as code can: someone
reading it aloud to a child should be able to tell what is happening.
- Names say what things are and what they do, in full words:
  `if (car.isOnOil()) car.loseGrip()`, not `if (c.oil) c.g *= k`.
- Each function tells one small step of the story, in at most 15 lines, and
  its name is that step: `slideIfTyresLetGo`, `shoveBothCarsApart`.
- Higher-level functions read as a list of those steps, so the story can be
  followed from the top down without reading the maths.
- **Lots of comments**: every class and function says what it is for and
  why, in plain words; the tricky lines say what is going on, as you would
  explain it out loud. Physics formulas name what each term is and what it
  means for the car ("the faster the tyre slides sideways, the harder it
  pushes back, until it can't grip any more").

As for bümbap otherwise:
- A `NOTES.md` records time spent, what fought back, and what was
  AI-assisted versus written or reviewed by hand.

## 12. Folder layout

```
shunt/
  SPEC.md          this file
  sim/             shared Haxe simulation (src/, test/)
  tracks/          oval.json, the whacky track (and later more)
  tools/           make-oval.py (writes tracks/oval.json), check-lengths.py
  client/          Haxe browser client: render, input, HUD (src/), the page (www/)
  assets/          glTF models, sounds
  server/          phase 3: the TypeScript Colyseus room
  tests/           Playwright browser checks
```

## 13. Decided and open

Decided 30 Oct: the name is **shunt**; rendering is **three.js** through Haxe
externs; **damage** costs speed, heavy damage pulls the steering, and badly
damaged cars now and then drop oil (section 4b); **tracks** take any layout,
with free-standing barriers for S-bends and chicanes, and phase 1 has an oval
plus one whacky track (section 5).

Open: the whacky track's actual layout, sketched once the oval drives well.
