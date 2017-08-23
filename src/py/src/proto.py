#!/usr/bin/python

import midi

pattern = midi.read_midifile("../resources/mary.mid")

note_events = None

for track in pattern:
    note_events = filter(lambda event: type(event) == midi.events.NoteOnEvent and event.channel == 0, track)
    if len(note_events) > 0:
        break

print pattern.__dict__
print pattern


class Hole(object):
    def __init__(self, pos, pin):
        self.pos = pos
        self.pin = pin

    def __repr__(self):
        return "%d:%d" % (self.pos, self.pin)

BPM = 120
PPQ = pattern.resolution
# tick duration in milliseconds
tick_duration = float(60) * 1000 / BPM / PPQ

# units per tick
units_per_tick = tick_duration / 10.0

holes = [Hole(float(e.tick) * units_per_tick, max(min(e.pitch - 52, 14), 0)) for e in note_events]

with open("../../../songs/mary.mbx", 'w') as file:
    for hole in holes:
        file.write("%s\n" % hole)

print min([x.pin for x in holes])

print holes

print units_per_tick
print tick_duration
