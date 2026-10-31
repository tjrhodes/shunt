# shunt

Contact stock car racing for up to four players, in isometric low-poly 3D,
where bumping is the point. A Lab piece for [tomrhodes.it](https://tomrhodes.it),
inspired by the ZX Spectrum's *3D Stock Car Championship* (1988).

The whole race (car physics, tracks, rules, AI drivers) is one simulation
written in Haxe. It runs in the browser now, and on a Node server for online
play later, so the same code decides the race on both sides.

The plan is in [SPEC.md](SPEC.md).

## Where it's at

Phase 1: races on two tracks (an oval and an arena maze, the Serpentine)
against three AI cars, with contact, damage and oil, in low-poly 3D. The
driving is tuned, and it has skid marks, smoke, sparks and dents, sound made
live in the browser, and scenery round every track. Next: same-screen
multiplayer (phase 2).

## Playing it

```sh
cd client
haxe build.hxml                       # builds www/shunt.js and copies the tracks
python3 -m http.server -d www 8000    # then open http://localhost:8000
```

## Running the checks

Needs [Haxe 4.3](https://haxe.org/download/) and Node.

```sh
cd sim
haxe test.hxml                        # every check of the simulation (about 30 s)
cd ..
python3 tools/check-lengths.py sim client/src tools   # no function over 15 lines
```

## Licence

MIT, see [LICENSE](LICENSE).
