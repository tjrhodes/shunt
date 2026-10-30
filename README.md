# shunt

Contact stock car racing for up to four players, in isometric low-poly 3D,
where bumping is the point. A Lab piece for [tomrhodes.it](https://tomrhodes.it),
inspired by the ZX Spectrum's *3D Stock Car Championship* (1988).

The whole race (car physics, tracks, rules, AI drivers) is one simulation
written in Haxe. It runs in the browser now, and on a Node server for online
play later, so the same code decides the race on both sides.

The plan is in [SPEC.md](SPEC.md).

## Where it's at

Phase 1, step 2 of 6: one car drives on an empty plane (tyres, engine,
brakes, steering), with checks that it drives like a car. No track or
graphics yet.

## Running the checks

Needs [Haxe 4.3](https://haxe.org/download/) and Node.

```sh
cd sim
haxe test.hxml                        # every check of the simulation
cd ..
python3 tools/check-lengths.py sim tools   # no function over 15 lines
```

## Licence

MIT, see [LICENSE](LICENSE).
