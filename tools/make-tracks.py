"""Writes the ten tracks beyond the oval and the Serpentine, in three
families (SPEC.md §5), each an original layout:

  Arena mazes: a walled floor with fences inside; the fences are the track.
    Comb        fingers from both sides, snaking up and down between them
    Slalom      a long box split down the middle, short fences to weave round
    Hexagon     a six-sided ring round an island, fences poking in from both sides
  Flowing circuits: a road with walls down both edges.
    Kidney      a bean, one long sweep and a tight bay
    Snake       a long loop whose sides wriggle
    Hook        a loop with a hairpin folded inside it
    Twister     corners of every kind, one after another
  Crossings: a road that crosses itself (the game leaves its walls open there).
    Hourglass   a figure of eight
    Pretzel     a big loop with a small loop inside it, crossing once
    Trefoil     three lobes, crossing three times

Each is described by a few numbers and simple shapes (straights, arcs,
curves); the game smooths the centreline and works out the rest.

Usage: python3 tools/make-tracks.py
"""

import json
import math
from pathlib import Path

TRACKS = Path(__file__).resolve().parent.parent / "tracks"
ROAD_WIDTH = 14.0       # a circuit's road, wall to wall: three cars wide
LONGEST_ROAD = 185.0    # a circuit is shrunk until its centreline fits this many metres across (about the oval's size):
                        # the camera fits the whole track on screen, so a bigger track means tinier cars (Tom, 1 Nov)
ARENA_WIDTH = 18.0      # how wide an arena's course counts as, for the AI and recovery


# ---- Shapes ----

def rounded(corners, radius, steps=4):
    """A closed path through corner points, each corner rounded off with an arc
    (no tighter than half of either side next to it allows)."""
    path = []
    count = len(corners)
    for index in range(count):
        before, here, after = corners[index - 1], corners[index], corners[(index + 1) % count]
        path += arc_round(before, here, after, radius, steps)
    return path


def arc_round(before, here, after, radius, steps):
    """Points round the corner at `here`, from the way in to the way out."""
    into, out = unit(sub(here, before)), unit(sub(after, here))
    room = min(length(sub(here, before)), length(sub(after, here))) / 2
    turn = math.acos(max(-1.0, min(1.0, dot(into, out))))
    if turn < 1e-3:
        return [here]
    cut = min(radius * math.tan(turn / 2), room)
    start, end = sub(here, scale(into, cut)), add(here, scale(out, cut))
    return [bezier(start, here, end, i / steps) for i in range(steps + 1)]


def bezier(start, control, end, share):
    """A point part way along a smooth curve from start to end, bent towards control."""
    a = add(scale(start, (1 - share) ** 2), scale(control, 2 * share * (1 - share)))
    return add(a, scale(end, share ** 2))


def curve(point_at, count):
    """A closed curve, from a function of a share (0 to 1) round it."""
    return [point_at(i / count) for i in range(count)]


def polygon(sides, radius, turned=0.0):
    """The corners of a regular polygon round the origin."""
    return [(radius * math.cos(turned + 2 * math.pi * i / sides), radius * math.sin(turned + 2 * math.pi * i / sides))
            for i in range(sides)]


def sub(a, b): return (a[0] - b[0], a[1] - b[1])
def add(a, b): return (a[0] + b[0], a[1] + b[1])
def scale(a, s): return (a[0] * s, a[1] * s)
def dot(a, b): return a[0] * b[0] + a[1] * b[1]
def length(a): return math.hypot(a[0], a[1])
def unit(a): return scale(a, 1 / length(a))


def without_repeats(spots):
    """The same points, with any too close to the one before taken out (the curve can't pass through one place twice)."""
    kept = []
    for spot in spots:
        if not kept or length(sub(spot, kept[-1])) > 0.5:
            kept.append(spot)
    if length(sub(kept[0], kept[-1])) <= 0.5:
        kept.pop()
    return kept


def evenly(spots, most_apart=8.0):
    """The same closed path with points added along any long stretch, so no two are
    more than `most_apart` metres apart. The game's smoothing needs points spaced
    fairly evenly: bunched corners beside long empty straights make it loop."""
    filled = []
    for here, after in zip(spots, spots[1:] + spots[:1]):
        pieces = max(1, math.ceil(length(sub(after, here)) / most_apart))
        filled += [add(here, scale(sub(after, here), i / pieces)) for i in range(pieces)]
    return filled


def starting_at(spots, index):
    """The same closed path, starting from another of its points."""
    return spots[index:] + spots[:index]


# ---- Arena mazes ----

def comb():
    """Six lanes side by side, fingers alternately rising from a fence near the
    bottom and hanging from the top wall; the race snakes up and down the lanes,
    and a lane along the bottom brings it back."""
    lane, lanes, top, fence_y, gap = 28.0, 6, 125.0, 26.0, 24.0
    wide = lane * lanes
    middles = [lane * (i + 0.5) for i in range(lanes)]
    bottom, high, low = fence_y / 2, top - gap / 2, fence_y + gap / 2
    corners = [(wide * 0.55, bottom), (middles[0], bottom)]
    for i, x in enumerate(middles):
        going_up = i % 2 == 0
        enter = bottom if i == 0 else (low if going_up else high)
        leave = bottom if i == lanes - 1 else (high if going_up else low)
        corners += [(x, enter), (x, leave)]
    fences = [[(lane, fence_y), (wide - lane, fence_y)]]
    for i in range(1, lanes):
        x = lane * i
        fences.append([(x, fence_y), (x, top - gap)] if i % 2 == 1 else [(x, top), (x, fence_y + gap)])
    path = without_repeats(rounded(clean_corners(corners), lane / 2))
    return arena("Comb", path, [(0, 0), (wide, 0), (wide, top), (0, top)], fences, laps=3)


def clean_corners(corners):
    """Corner points with any repeats, and any that lie straight between their neighbours, taken out (except the first: the start)."""
    kept = []
    for c in corners:
        if not kept or c != kept[-1]:
            kept.append(c)
    return [c for i, c in enumerate(kept) if i == 0 or not is_straight_through(kept[i - 1], c, kept[(i + 1) % len(kept)])]


def is_straight_through(before, here, after):
    into, out = sub(here, before), sub(after, here)
    return abs(into[0] * out[1] - into[1] * out[0]) < 1e-6 and dot(into, out) > 0


def slalom():
    """A long box split down the middle by a fence; east along one half and back
    west along the other, weaving round short fences from the walls and from the
    middle fence. A clear straight at the start leaves room for the grid."""
    long, deep, gap_end, fence_long, every, clear = 240.0, 72.0, 26.0, 21.0, 34.0, 75.0
    middle = deep / 2
    xs = [clear + every * i for i in range(int((long - gap_end - clear) / every))]
    fences = [[(gap_end, middle), (long - gap_end, middle)]]
    east, west = [], []
    for i, x in enumerate(xs):
        from_wall = i % 2 == 0
        fences.append([(x, 0.0), (x, fence_long)] if from_wall else [(x, middle), (x, middle - fence_long)])
        east.append((x, (fence_long + middle) / 2 if from_wall else (middle - fence_long) / 2))
        fences.append([(x, deep), (x, deep - fence_long)] if not from_wall else [(x, middle), (x, middle + fence_long)])
        west.append((x, (deep - fence_long + middle) / 2 if not from_wall else (middle + fence_long + deep) / 2))
    quarter, three_quarters = deep * 0.25, deep * 0.75
    path = ([(clear - 18, quarter)] + east + [(long - gap_end / 2, quarter), (long - gap_end / 2, three_quarters)]
            + west[::-1] + [(gap_end / 2, three_quarters), (gap_end / 2, quarter)])
    return arena("Slalom", without_repeats(rounded(path, 15, steps=6)), [(0, 0), (long, 0), (long, deep), (0, deep)], fences, laps=3)


def hexagon():
    """A six-sided ring round a six-sided island; fences reach in from the outer
    wall and out from the island in turn, so the race weaves in and out."""
    outer, island, poke = 88.0, 34.0, 30.0
    outer_flat, island_flat = outer * math.cos(math.radians(30)), island * math.cos(math.radians(30))
    fences, path = [], []
    for k in range(6):
        angle = math.radians(30 + 60 * k)
        direction = (math.cos(angle), math.sin(angle))
        from_outside = k % 2 == 0
        tip = outer_flat - poke if from_outside else island_flat + poke
        fences.append([scale(direction, outer_flat if from_outside else island_flat), scale(direction, tip)])
        path.append(scale(direction, (island_flat + tip) / 2 if from_outside else (tip + outer_flat) / 2))
        between = math.radians(60 + 60 * k)
        path.append(scale((math.cos(between), math.sin(between)), (island + outer) / 2))
    smooth = without_repeats(rounded(starting_at(path, 1), 30, steps=6))
    return arena("Hexagon", smooth, polygon(6, outer), fences, laps=4, more_loops=[polygon(6, island)])


def arena(name, path, outline, fences, laps, more_loops=()):
    return {
        "name": name,
        "laps": laps,
        "edgeWalls": False,
        "centreline": as_points(evenly(path), width=ARENA_WIDTH),
        "loops": [as_points(outline)] + [as_points(loop) for loop in more_loops],
        "barriers": [as_points(fence) for fence in fences],
    }


# ---- Flowing circuits ----

def kidney():
    """A bean: a long sweeping outside, and a bay pushed in on one side."""
    def at(share):
        t = 2 * math.pi * share
        bay = 0.42 * math.exp(-((math.atan2(math.sin(t - math.pi / 2), math.cos(t - math.pi / 2))) ** 2) / 0.35)
        radius = 1 - bay
        return (100 * radius * math.cos(t), 62 * radius * math.sin(t))
    return road("Kidney", curve(at, 48), laps=4)


def snake():
    """A long loop whose top and bottom both wriggle, in step, so the road
    swings left and right all the way along."""
    def at(share):
        t = 2 * math.pi * share
        x = 130 * math.cos(t)
        y = 48 * math.sin(t) + 10 * math.sin(3 * (x / 130) * math.pi)
        return (x, y)
    return road("Snake", curve(at, 64), laps=4)


def hook():
    """A loop with a hairpin folded into it: in along one leg, round, and back out."""
    corners = [(-90, -50), (90, -50), (90, 50), (20, 50), (20, -5), (-20, -5), (-20, 50), (-90, 50)]
    return road("Hook", starting_at(without_repeats(rounded(corners, 18, steps=5)), 2), laps=4)


def twister():
    """Corners of every kind: a fast sweeper, a hairpin, a chicane and a long hook."""
    corners = [(-110, -40), (40, -40), (70, -10), (110, -40), (130, 20), (60, 55), (20, 20), (-20, 55), (-80, 50), (-120, 10)]
    return road("Twister", without_repeats(rounded(corners, 22, steps=5)), laps=4)


def road(name, path, laps):
    return {"name": name, "laps": laps, "centreline": as_points(evenly(shrunk_to_fit(path)), width=ROAD_WIDTH), "barriers": []}


def shrunk_to_fit(path):
    """The path made smaller about its middle, if it is wider or taller than `LONGEST_ROAD`."""
    xs, ys = [x for x, _ in path], [y for _, y in path]
    longest = max(max(xs) - min(xs), max(ys) - min(ys))
    if longest <= LONGEST_ROAD:
        return path
    middle = ((max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2)
    return [add(middle, scale(sub(spot, middle), LONGEST_ROAD / longest)) for spot in path]


# ---- Crossings ----

def hourglass():
    """A figure of eight: two loops, crossing in the middle at a wide angle."""
    def at(share):
        t = 2 * math.pi * share
        return (120 * math.sin(t), 70 * math.sin(t) * math.cos(t) * 1.6)
    return road("Hourglass", curve(at, 56), laps=4)


def pretzel():
    """A big loop with a small one inside it, the road crossing itself once (a limaçon)."""
    def at(share):
        t = 2 * math.pi * share
        radius = 45 + 85 * math.cos(t)
        return (radius * math.cos(t), radius * math.sin(t) * 1.15)
    return road("Pretzel", starting_at(curve(at, 64), 32), laps=4)


def trefoil():
    """Three lobes round a middle, the road crossing itself three times."""
    def at(share):
        t = 2 * math.pi * share
        return (42 * (math.sin(t) + 2 * math.sin(2 * t)), 42 * (math.cos(t) - 2 * math.cos(2 * t)))
    return road("Trefoil", curve(at, 72), laps=3)


# ---- Writing them ----

def as_points(spots, **extra):
    return [{"x": round(x, 3), "y": round(y, 3), **extra} for x, y in spots]


EVERY_NEW_TRACK = [comb, slalom, hexagon, kidney, snake, hook, twister, hourglass, pretzel, trefoil]


def main():
    names = []
    for make in EVERY_NEW_TRACK:
        track = make()
        file = track["name"].lower() + ".json"
        (TRACKS / file).write_text(json.dumps(track, indent=1) + "\n", encoding="utf8")
        names.append(file)
        print(f"{file}: {len(track['centreline'])} centreline points")
    index = ["oval.json", "serpentine.json"] + names
    (TRACKS / "index.json").write_text(json.dumps(index, indent=1) + "\n", encoding="utf8")


if __name__ == "__main__":
    main()
