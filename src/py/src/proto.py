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


holes = [Hole(25, max(min(e.pitch - 51, 15), 1)) for e in note_events]

with open("../../../songs/mary.mbx", 'w') as file:
    for hole in holes:
        file.write("%s\n" % hole)

print min([x.pin for x in holes])

print holes
