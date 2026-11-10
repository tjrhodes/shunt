"""Writes tracks/serpentine.json: an arena maze in the style of the original's
fence tracks. A walled box; fences inside make four rows that the race
zigzags up, turning round the fence tips in hairpins; a lane down the
right-hand side brings it back to the start (SPEC.md §5).

    row 4  →→→→→→→→→→→→→→→→→→→→→→→→→→→→→↘
    ╭←←←←  fence  ━━━━━━━━━━━━━━━━━━━┓      ↓  return
    row 3  ←←←←←←←←←←←←←←←←←←←←←←←←←←╮┃      ↓  lane
    ┣━━━━━━━━━━━━━━━━━━━━━━━━  fence  ┃      ↓
    row 2  →→→→→→→→→→→→→→→→→→→→→→→→→→╯┃      ↓
    ╰←←←←  fence  ━━━━━━━━━━━━━━━━━━━┛      ↓
    row 1  ←←←←←←←← start ←←←←←←←←←←←←←←←←←←←↙

Usage: python3 tools/make-serpentine.py
"""

import json
import math
from pathlib import Path

ARENA_LONG = 170.0      # metres, west to east
ARENA_DEEP = 100.0      # metres, south to north
ROW_DEEP = 25.0         # metres between fences: about a dozen car widths
RETURN_LANE = 24.0      # metres: the lane down the east side
GAP = 24.0              # metres left open at a fence's tip, to turn round it
WIDTH = 20.0            # the course's width as the AI and recovery see it
LAPS = 3                # a lap is about 600 m

ROWS_END = ARENA_LONG - RETURN_LANE           # where the rows stop and the return lane starts
ROW_MIDDLES = [ROW_DEEP * (row + 0.5) for row in range(4)]
FENCE_LINES = [ROW_DEEP * (row + 1) for row in range(3)]
TURN_RADIUS = ROW_DEEP / 2


def arena():
    """The outer wall, all the way round."""
    return [(0, 0), (ARENA_LONG, 0), (ARENA_LONG, ARENA_DEEP), (0, ARENA_DEEP)]


def fences():
    """The first and third fence lines are one fence, joined down the return lane's
    side (a C opening west); the second runs from the west wall, open at the east."""
    first, second, third = FENCE_LINES
    c_shape = [(GAP, first), (ROWS_END, first), (ROWS_END, third), (GAP, third)]
    middle = [(0, second), (ROWS_END - GAP, second)]
    return [c_shape, middle]


def hairpin(tip_x, tip_y, opens_east):
    """Points round a fence tip in a half circle, from the row below to the row above."""
    side = 1 if opens_east else -1
    steps = [-90, -45, 0, 45, 90]
    return [(tip_x + side * TURN_RADIUS * math.cos(math.radians(a)), tip_y + TURN_RADIUS * math.sin(math.radians(a)))
            for a in steps]


def corner(centre_x, centre_y, from_degrees, to_degrees):
    """Points round a quarter circle about a centre."""
    return [(centre_x + TURN_RADIUS * math.cos(math.radians(a)), centre_y + TURN_RADIUS * math.sin(math.radians(a)))
            for a in (from_degrees, (from_degrees + to_degrees) / 2, to_degrees)]


def row(y, from_x, to_x, steps=3):
    """Points along a row, not counting its far end."""
    return [(from_x + (to_x - from_x) * i / steps, y) for i in range(steps)]


def centreline():
    """The race's way round, starting on the bottom row heading west."""
    return up_the_rows() + down_the_return_lane()


def up_the_rows():
    """From the start, west along the bottom row and zigzagging up to the top row."""
    first, second, third = FENCE_LINES
    r1, r2, r3, r4 = ROW_MIDDLES
    return (row(r1, 100, GAP)
            + hairpin(GAP, first, opens_east=False)[:-1]
            + row(r2, GAP, ROWS_END - GAP)
            + hairpin(ROWS_END - GAP, second, opens_east=True)[:-1]
            + row(r3, ROWS_END - GAP, GAP)
            + hairpin(GAP, third, opens_east=False)[:-1]
            + row(r4, GAP, ROWS_END, steps=4))


def down_the_return_lane():
    """Round into the return lane, down it, and back along the bottom row to the start."""
    first, _, third = FENCE_LINES
    return (corner(ROWS_END, third, 90, 0)
            + [(ROWS_END + RETURN_LANE / 2, ARENA_DEEP / 2)]
            + corner(ROWS_END, first, 0, -90)
            + row(ROW_MIDDLES[0], ROWS_END, 100, steps=2))


def without_repeats(spots):
    """The same points, with any that repeat the one before taken out (the curve can't pass through one place twice)."""
    return [spot for i, spot in enumerate(spots) if i == 0 or spot != spots[i - 1]]


def as_points(spots, **extra):
    return [{"x": round(x, 3), "y": round(y, 3), **extra} for x, y in spots]


def main():
    track = {
        "name": "Serpentine",
        "family": "arena",
        "laps": LAPS,
        "edgeWalls": False,
        "centreline": as_points(without_repeats(centreline()), width=WIDTH),
        "loops": [as_points(arena())],
        "barriers": [as_points(fence) for fence in fences()],
    }
    path = Path(__file__).resolve().parent.parent / "tracks" / "serpentine.json"
    path.write_text(json.dumps(track, indent=1) + "\n", encoding="utf8")
    print(f"{path}: {len(track['centreline'])} centreline points")


if __name__ == "__main__":
    main()
