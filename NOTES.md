# Notes

What fought back, what was learned, and who wrote what (SPEC.md §11).

## 30 Oct 2026: the bones and one car

Written by Claude (AI) from the spec, for Tom to review.

- **Set up:** Haxe 4.3.7 straight from the Haxe Foundation's release (as in
  bümbap's CI); the 15-line checker copied from bümbap; a sync version of
  bümbap's tiny test runner.
- **Car physics:** a bicycle model (one tyre per axle). Car state is plain
  data (`Car`); what it does lives in `CarFrame`, `Controls`, `Tyres`,
  `Engine` and `CarMotion`, used as static extensions, so it reads
  `car.followTheDriver(input)` but still copies and serialises as a plain
  object. Arrows (`Vector`) never change once made, so a shallow copy of a
  car is a true copy.
- **Measured** on an empty plane: 0–100 km/h in 4.3 s, top speed 39.8 m/s
  (143 km/h), 85 m to stop from flat out.
- **What fought back:**
  - The spec had the front tyres gripping more than the rear. The first
    probe showed that spins the car at half lock and full throttle, even at
    55 km/h, every time: once both ends slide, the front's push wins. Swapped
    (front 1.15 g, rear 1.3 g, less grip lost to throttle) and the car now
    runs wide and settles. Spec updated.
  - The test helper counted time in floating-point seconds, so a drive
    starting at 5 s ran one tick more than one starting at 0. It now counts
    whole ticks. The same rule will hold in the race: time is ticks.
- **For the feel test:** at speed, full steering asks for far more grip than
  the tyres have (at 90 km/h, a third of the way already slides). That may
  be right for a slidey stock car, or the steering at speed may want
  narrowing. To decide at the wheel.

## 30 Oct 2026, evening: the oval to a drivable race (steps 3 to 6)

Written by Claude (AI) from the spec, for Tom to review.

- **Built:** tracks from JSON (smoothed centreline, edge walls, barriers),
  contact (corners, wall ends, impulses with spin), race rules (lights,
  checkpoints, laps, finish, standings, putting cars back), damage and oil,
  AI drivers with a racing line worked out from any track, and a Haxe
  three.js client with keyboard, gamepad and touch. 82 checks.
- **What fought back:**
  - AI drivers whose favourite lane hugged the outside wall drifted into it
    in every bend, wrecked themselves and were put back up to 12 times a
    race. Favourite lanes now stay within 40 % of the room each side.
  - Oil that only cut grip barely turned a car (6° at most): at speed both
    axles cross a patch almost together and the car just slides on. Now the
    back end also steps out while the rear wheels are on oil, the way the
    car is already turning; patches are 2 m across the middle, not 1.5.
    Spec updated.
  - The "every AI car finishes" check can't hold with the 10 s rule, and a
    wreck falling back is damage working. The check is now: every car not
    badly damaged reaches its last lap; none put back more than 3 times.
  - On a phone, the four 45° camera angles all laid the oval diagonally and
    small. The camera now tries every 15° and picks the best fill.
  - In this cloud workspace the browser renders in software (7 frames a
    second at desktop size), so the game ran in slow motion there, as it is
    built to (at most 8 ticks a frame). A real GPU should hold 60.
- **For the feel test:** lap times (about 20 s, tight bends), how slidey the
  steering is at speed, how hard hits feel, how often AI bump, how much oil
  spins. All in the tuning classes.
- **Not yet (phase 1 still to do):** sound, sparks, smoke and skid marks,
  dents, the damage outline in the HUD, the whacky track, the design pass.

## 30 Oct 2026, night: tuning after Tom's first drive

Tom drove it. What he found, what it was, and what changed:

- **Heavy steering, then a sudden spin; a small correction at top speed
  spun the car into the wall.** Measured: a 0.3 s tap at top speed turned
  the car 93° with a 33° slide. Nothing stopped the car rotating once it
  started. Now: a steadying hand draws the car's turning towards what its
  front wheels ask for (an arcade assist, `CarTuning.steadying`); steering
  turns faster (7 rad/s) and less at top speed (6°). The same tap turns it
  20° and settles.
- **Couldn't get round the bends, even lifting off on full lock.** Lifting
  off slowed the car from top speed to 70 km/h in 48 s and 1.3 km: there
  was no engine braking. Now 5,000 N of engine braking: 6 s and 190 m.
  Grip is up (front 1.45 g, rear 1.55 g) and the oval's bends are wider
  (32 m radius, not 25).
- **The back should drift round so you can hold a slide on the power.**
  Tyres now grip less once really sliding (80 % at twice the best slip
  angle), and full throttle takes 20 % of the rear's grip. Full lock on the
  power at 90 km/h: a 17° drift that countersteering straightens.
- **Grazing walls broke the steering and started oil.** Walls did as much
  harm as cars (a graze about 40 points), and a hit near a corner counted
  as the front. Now walls are kinder (harmless below 6 m/s, 1.5 points per
  m/s after: a top-speed graze about 10), damage goes on the side the hit
  came from, steering pull starts at 50 front damage and oil at 80 overall.
- **Oil spun the car regardless.** The tail-swing is gone; oil only takes
  grip away. Straight over it: nothing. In a bend: the car slides wide.
- **Top speed a bit quicker:** 46 m/s (165 km/h), from 42.
- Checks added for each of these, so they can't quietly come back: 94 now.
  The AI check allows 1 car in 100 caught in a racing incident.

## 30 Oct 2026, late: second tuning round

Tom: much better; a bit more turning and engine braking, and steering that
builds the longer a key is held.

- **Key build:** `client/src/input/SteeringRamp.hx`: a third of the steering
  when a key goes down, full after 0.6 s held; letting go or switching sides
  starts again. Touch steering uses it too. It goes by the clock, so asking
  twice in a frame changes nothing. In the client, not the car: it is about
  keys, and a gamepad stick is already gradual.
- **More turning:** steering at top speed 9° (from 6°), grip front 1.6 g and
  rear 1.7 g (from 1.45 and 1.55). Full lock from top speed now turns 73° in
  3 s (was 61°); a held half-lock bend at 72 km/h turns about 40 % quicker.
  Taps at top speed unchanged: 20°, settling.
- **Tried and dropped:** letting the steadying ask for up to 30 % more turning
  than the grip can hold. Quick taps were fine, but a held half-lock bend
  scrubbed round into a doughnut (35° slides, down to 25 km/h). 10 % did the
  same, more slowly.
- **Engine braking:** 7,500 N (from 5,000): top speed to 70 km/h in 4.2 s,
  132 m (was 6 s, 188 m).

## 31 Oct 2026: third tuning round

Tom: better again; steering a little more pronounced when held, engine
braking a little more, and the walls: the front corner catches and the car
spears in, stops and turns, instead of sliding along.

- **Walls: found the real cause.** Driving into the oval's wall at 15° and
  20° stopped the car dead (2 m/s and 1 m/s), pointing 62° and 90° into the
  wall. Lowering friction didn't fix it, even near zero. The cause: the edge
  walls are pieces joined every 2 m, and every joint was tested as a wall
  end poking into the car; at the car's nose that end pushed it straight
  back along its length. Only ends that stick out (a barrier's free tip, or
  a corner sharper than 30°) count now. Every angle from 5° to 20° now
  slides along, pointing down the track. Wall friction 0.3 (from 0.6): a
  top-speed graze keeps about three quarters of the speed, not 60 %.
  Rounding the car's corners turned out not to be needed.
- **Steering held:** near full lock at speed, the steadying lets the car turn
  up to a quarter more than its grip holds, so it rotates into a slight
  drift. Faded in with speed: at 72 km/h it made a held full lock scrub
  into a doughnut (49° slide, down to 4 m/s). Full lock from top speed turns
  84° in 3 s (from 73°); taps unchanged.
- **Engine braking:** 10,000 N with the foot right off (from 7,500), going
  with the square of the lift: part throttle is barely held back. Top speed
  to 70 km/h in 3.3 s (from 4.2).
- Checks added: glancing off the wall at 5° to 20°; smooth joints don't
  stick out. 104 now.

## 31 Oct 2026: the rest of phase 1

Tom: driving signed off, go for the rest of phase 1. His screenshots of the
original's tracks fell into three families (arena mazes, flowing circuits,
crossings), so the second track is an arena maze.

- **Arenas.** A track file can now be an arena: its own wall loops and
  fences, with the centreline only guiding laps, recovery and the AI. The
  Serpentine is generated by `tools/make-serpentine.py`; its centreline
  first dropped a point at each hairpin entry, which made the AI cut the
  fence tips. 100 AI races on each track: no car ever left the arena.
- **Camera.** A box arena came out straight-on (it fills a wide screen
  best), which loses the isometric look; a diagonal view now wins unless
  another fills the screen a quarter better. It still chooses straight-on
  for the Serpentine on a very wide window.
- **Effects** are instanced particle pools; dents push the body's corners
  in near the hit. Software rendering in the sandbox is slow, so most of
  this was checked by racing in a small window and enlarging it for the
  screenshot.
- **Sound** is made live (no files), so nothing to download or license.
  Browsers allow sound only after a press, so it wakes on Start.
- **Design.** Scenery comes from the walls' bounding rectangle, so every
  track gets it with no extra data. Long fences are cut into 3 m blocks,
  concrete and red in turn, which makes arena fences read at a glance.
- **Found on the way:** the start panel couldn't be reached on a short
  screen (a phone held sideways); the panels now scroll.

## 31 Oct 2026, afternoon: phase 2, same screen

Tom chose phase 2 before the design tweaks, so the panels and HUD get
designed once, for several players.

- **No simulation changes at all.** The race only ever took one
  `CarInput` per seat, so phase 2 was all in the client: controllers, who
  sits where, and showing several people.
- **The solo game stays as it was** until someone presses go on a
  controller. That avoided a "how many players?" question before every
  race: one person never sees the seat picker do anything.
- **Joining rebuilds the race on the grid**, so the AI drivers match the
  seats. Nothing has happened yet at that point, so nothing is lost.
- **Checked in the browser:** two people on one keyboard (WASD and the
  arrows) each drive their own car; with only one pressing go, the other
  stays on the grid and drops to last. The lineup's rules (joining,
  leaving, the solo fallback) have their own Node checks, the client's
  first.
- **Not tested with real gamepads** here; the pad code reads each pad by
  its slot, as the browser numbers them.
- Keyboards often can't read more than a few keys at once, so two people
  on one keyboard can block each other now and then. Gamepads don't have
  this.
- **Gamepads on Linux (found with Tom's Switch Pro Controller):** the
  game was fine; the machine wasn't. Chrome-based browsers need
  `/dev/input/js*` (the `joydev` module, in Ubuntu's
  `linux-modules-extra` package), and for Nintendo pads they read
  `/dev/hidraw` directly, which a Snap browser can't reach even with
  `joystick` connected. Firefox and unsandboxed browsers read it fine. The
  game now carries on with no pads if the browser refuses them.

## 31 Oct 2026, evening: phase 3, online

Tom chose quick match plus room links, its own subdomain
(shunt.tomrhodes.it, nginx), and keeping seats per controller online.

- **Colyseus moved on to 0.18** since the spec was written: a new client
  package (`@colyseus/sdk`) and its own prediction helpers. Neither was
  needed: the room is driven by our own Haxe (`RaceRoom`), and the
  browser's prediction is our own too (`Prediction`), so the same code is
  checked on Node with a pretend network.
- **No schema.** The spec said to write the state schema in TypeScript and
  generate it for Haxe. The race is already plain data that copies as
  JSON, so snapshots send it as it is; a schema would have been every
  field written a second time.
- **The pretend network** (`OnlineHarness`) turns every message into JSON
  and back, so nothing is shared between "server" and "browser" by
  accident. The first measurements were tiny: the person in each browser
  is an AI driver, which drives smoothly; real people will make bigger
  corrections. Worth measuring again on the real server.
- **Colyseus answers its own HTTP requests** (finding and joining rooms):
  the page server first answered everything with 404, so the matchmaking
  failed. It is now an Express middleware that passes on anything that
  isn't one of the game's files.
- **Checked in two browsers** against the server here: a link room, the
  second browser joining by the link, the host starting, both driving,
  AI in the other seats.
- **Deploying from here wasn't possible** (no route to the VPS), so
  `deploy/deploy.sh` does it from Tom's computer.
- Colyseus needs Node 22 or newer; the script checks.
- **First real test (Tom, desktop and phone):** opened from the link, the
  phone showed the offline "Start the race" first and the join button
  second, so it was easy to start a race alone by mistake; that is what
  looked like both devices driving the yellow car. An invitation link now
  leads with "Join the race" (racing alone is a quiet second choice, and
  the offline start, track picker and seat cards are hidden). Panels were
  also slightly wider than a phone screen (no `box-sizing`), now fixed.

## 1 Nov 2026: first races with other people

- **Through Player 2's car:** your car is drawn ahead (predicted), and
  other people's were drawn 0.1 s in the past, so over a phone network
  the two were a few metres apart on screen from where the server had
  them, and you could drive through a car without touching it. Everyone's
  car is now drawn where the browser predicts it, with corrections eased.
- **Walls slow you a little more** (Tom): wall friction 0.5 (from 0.3).
  Measured flat out at 40 m/s into the oval's wall: the slowest a graze
  leaves you is 25 to 30 m/s, from 28 to 33.
- **"Couldn't reach the race" on Tom's son's phone**, twice, while Tom's
  own phone and computer joined fine. Cause not known yet: the panel now
  shows the reason the join failed, small, under the message.
- The no-delay online check is now "all but exactly": the other person's
  latest input is always a tick away, so a bump can differ by millimetres.
- Rounding in `FixedSteps` could hold a due tick for a frame and run two
  together; it now allows a millionth of a second of slack.
- **Cars passing through each other, offline too** (Tom): the hit test
  looked only for a corner of one car inside the other. Two cars lying
  across each other like a plus sign, or one nose-first into the other's
  side, have no corner inside, so nothing happened. Now a proper box
  overlap test (the separating-axis test): checked with a plus sign and a
  nose into a side, and 1,000 random hits (flat out into parked cars at
  any angle, and side by side at speed steering into each other): the
  deepest two cars ever sink into each other is 7 cm.
- **The flick** (Tom: "turn right slightly then hard left and it drifts,
  as I've chucked the weight over"): the car now carries where its weight
  leans (`sidewaysLoad`, rolling over in about 0.35 s). While the weight is
  still over one side and the wheels ask hard for the other, once the car
  has started turning the new way, the rear loses up to 45 % of its grip
  and the steadying hand most of its hold. At 30 m/s: hard left off a
  straight slides 10°; after a little right first, 27°, without spinning.
  The first version also weakened the rear when countersteering a slide
  (which also asks against the weight), so catching a power slide got
  harder; the "turning the new way" condition keeps countersteering a catch.
- **Smaller cars, and a car of our own** (Tom wanted a simplified 60s
  small car). The models he found were ripped from games (Forza Horizon,
  Colin McRae Rally 2005), and a copy of a real car design isn't ours to
  use, so the car is our own little 1960s rally saloon: chunky boxes, a
  sloping bonnet and boot, a narrowing glasshouse under a white roof,
  round wheels out at the corners, chrome bumpers, round lamps, two
  spotlights, and the number on the roof and both doors. The race's cars
  shrank to match: 3.6 by 1.6 m (from 4.8 by 1.9), axles 1.05 m from the
  middle. A short car spins up faster, so a quick correction at top speed
  turned 44° instead of under 35°: the steadying hand went from 4 to 5,
  and every check passes again (the gentle-bend check now uses a lighter
  touch, 0.075 of lock, as the shorter wheelbase turns tighter).
- **Cars looking inside each other, side by side (offline):** the race
  kept them apart (pressed side by side at up to 40 m/s, steering into
  each other, they never sank more than 2 cm), but the drawn car stuck out
  of its own box: the wheels by about 15 cm each side, the bumpers and
  spotlights at the ends. Everything drawn now sits inside the race's box.
- **Bigger cars:** 4.2 by 1.75 m (axles 1.25 m from the middle), between
  the stock car and a true small car, with a taller cabin, a thicker roof
  and bigger wheels so they read on screen. Every check passes unchanged.
- **The flick on keys:** holding a key builds steering up from a third,
  and switching sides started that again, so the left turn came in weak
  while the weight settled. Going straight from one side to the other
  (even with a gap of up to 0.15 s between keys) now keeps what has built
  up. The keyboard's build-up is now checked too (`client/test/FlickTests`,
  driven through the very same `SteeringRamp`): at 30 m/s, left off a
  straight slides 10°; a tap right first, 21°.

## 1 Nov 2026, late: a dozen tracks

Tom asked for a dozen tracks in the spirit of his screenshots, and higher
walls. Ten new ones, all from `tools/make-tracks.py` (see SPEC.md §5).

- **Crossings** worked with one change to `Track`: edge walls lying on a
  far-off part of the road are left out, so the road is open where it
  crosses. Laps, recovery and the AI already only ever look at the part of
  the track a car is near, so nothing else needed to know.
- **The first Hook and Twister had walls in knots** at their corners: the
  rounded corners were a cluster of points, and the straights between them
  had none, and the game's smoothing (Catmull-Rom, evenly spaced along the
  points) looped back on itself there. The generator now fills long
  stretches with points no more than 8 m apart.
- **All twelve pass first time**: 100 AI races on each, every car that
  isn't wrecked finishing, none put back more than three times, no car
  ever outside an arena. The whole set of checks now takes about 7
  minutes, most of it those 1,200 races.
- The camera still picks a straight-on view for some box arenas (the
  Comb); that's for the design pass.

## 2 Nov 2026: smaller tracks, sharper AI, the portfolio's look

- **Tracks too big** (Tom: cars tiny on the Trefoil, Hourglass, Snake):
  the camera fits the whole track, so size is everything. Every road
  circuit is now shrunk to fit 185 m across (about the oval's 177 m), the
  road staying 14 m wide: Trefoil 244 → 199 m, Snake 274 → 199, Twister
  258 → 199, Hourglass 254 → 199. The Snake's wiggles were softened, as
  they pinched at the smaller size.
- **AI drivers have characters** (Tom: faster, and one aggressive): an
  Ace (pace 1.08 of the racing line, clean), a Bruiser (1.04, bumps rather
  than passes) and a Steady (0.97, clean); three AI cars are always one of
  each, in seats that change from race to race. They were 0.88 to 0.98 at
  random. Over 20 races on each track, the Ace won most, the Bruiser the
  rest bar a few; none was put back more than twice; all checks pass.
- **The portfolio's palette and type**: Paint.hx and the page's colours
  are now the rock-and-lichen palette from tomrhodes.it (night-blue rock,
  pale stone, lichen yellow, ochre, rust, ember); fonts Fira Sans and Fira
  Sans Condensed (900 for titles and numbers), also for the car numbers and
  billboards (`view/Lettering.hx`).
- The online room no longer has its own track picker (2 Nov): it shows
  its track as one line with a small map, and the host's "Change track"
  opens the same ring of cards as on this computer ("Use this track" goes
  back). Every card chosen there is the room's track at once.
- Results lead with the winner ("Ace wins", "You win!") and the track;
  the winner's row stands out. AI drivers are named by their kind (Ace,
  Bruiser, Steady) on the results, offline and online, instead of "No. N".
- A quick match's countdown now ticks down on the room panel each frame,
  from the last time the room said how long was left.
- The camera now prefers a diagonal view unless a straight one fills the
  screen 1.45 times better (was 1.25): the Comb came out straight-on.
- **Starting a race in stages** (Tom: "a carousel of tracks on cards, then
  a new screen to pick the drivers... nice clutter-free layouts for each
  stage"). First the track cards (`hud/TrackCards.hx`): a sliding row, one
  card per track, each with a map drawn from the track's own walls, its
  name, its family (a new `family` in each track file), and laps and
  length; the chosen card sits in the middle and the 3D track behind
  changes with it. Left and right on keys, stick or touch move through
  them. Then the drivers: the four seats, the AI ones named for their kind
  (Ace, Bruiser, Steady, from the race's seed), Back and Start, and racing
  online. A friend's link opens on its own small panel. The HUD fades away
  while starting.
- **Found on the way:** on a phone the track panel came out 1,024 px wide
  and off the side of the screen. The panels' grid sized its one column to
  fit everything inside it, here the whole row of cards; it now has one
  column that is never wider than the screen.
- **The track cards as a 3D ring** (Tom: "cards in a circle, the current
  one comes out and turns to show its content"): `view/CardRing.hx`, its
  own small three.js view in the track panel. Cards stand in a circle with
  their backs out; the chosen one slides towards you, rises, grows and
  turns half round to face you; choosing another turns the ring the short
  way round while the old card swings back. Everything eases (exponential,
  7 per second), so running through the cards flows; with reduced motion it
  jumps. The faces are painted on canvases (`view/CardFaces.hx`), the map
  from the same path data as before (`view/TrackMap.hx`, used by both).
  The plain buttons stay underneath, out of sight, for screen readers.
- 3 Nov (Tom): the card ring takes swipes (sideways only; up and down
  still scroll the panel). A swipe to the left brings the next card, and a
  longer swipe moves on more than one. The click that ends a swipe is
  ignored, so a swipe never picks a card by accident.
- The card backs now show the track's map in a quiet blue with its name, so
  the cards in the ring aren't a mystery; only the chosen card's map is yellow.
- Touch braking is a bar right across the bottom of the screen instead of a
  round pad in the corner, so the left thumb can brake while the right one
  steers right. The HUD's bottom plates and the start lights sit above it,
  and the touch buttons hide while a panel shows.
