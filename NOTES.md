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
