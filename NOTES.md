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
