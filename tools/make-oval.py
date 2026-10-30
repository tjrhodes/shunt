"""Writes tracks/oval.json: a short oval (a "stadium": two straights joined by
two half circles), run anticlockwise, starting halfway down the bottom
straight. The track file only holds points round the centreline; the game
smooths them into a curve and works out everything else (SPEC.md §5).

Usage: python3 tools/make-oval.py
"""

import json
import math
from pathlib import Path

BEND_RADIUS = 32.0      # metres, to the centreline
STRAIGHT_LENGTH = 99.5   # metres; with the bends, about 400 m round (a quarter mile)
WIDTH = 14.0            # metres, wall to wall: three cars wide
STRAIGHT_STEP = 20.0    # metres between points on the straights
BEND_STEP = 30.0        # degrees between points round the bends


def straight(from_x, to_x, y):
    """Points along a straight, not counting its far end (the bend starts there)."""
    steps = max(1, round(abs(to_x - from_x) / STRAIGHT_STEP))
    return [(from_x + (to_x - from_x) * i / steps, y) for i in range(steps)]


def bend(centre_x, from_degrees):
    """Points round a half circle, anticlockwise, not counting its far end."""
    steps = round(180 / BEND_STEP)
    angles = [math.radians(from_degrees + 180 * i / steps) for i in range(steps)]
    return [(centre_x + BEND_RADIUS * math.cos(a), BEND_RADIUS * math.sin(a)) for a in angles]


def centreline():
    """The whole loop, from the start line halfway down the bottom straight."""
    end = STRAIGHT_LENGTH / 2
    return (straight(0, end, -BEND_RADIUS) + bend(end, -90) + straight(end, -end, BEND_RADIUS)
            + bend(-end, 90) + straight(-end, 0, -BEND_RADIUS))


def main():
    points = [{"x": round(x, 3), "y": round(y, 3), "width": WIDTH} for x, y in centreline()]
    track = {"name": "Oval", "centreline": points, "barriers": []}
    path = Path(__file__).resolve().parent.parent / "tracks" / "oval.json"
    path.write_text(json.dumps(track, indent=1) + "\n", encoding="utf8")
    print(f"{path}: {len(points)} points")


if __name__ == "__main__":
    main()
