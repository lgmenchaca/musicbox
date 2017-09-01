#!/usr/bin/python

import midi
import sys

# pattern = midi.read_midifile("../resources/mary.mid")
pattern = midi.read_midifile(sys.stdin)

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
tick_duration = 60.0 * 1000 / BPM / PPQ

# units per tick
units_per_tick = tick_duration / 10.0

# This site has some interesting tables with MIDI - piano keys mappings:
# http://www.sengpielaudio.com/calculator-notenames.htm
PIN_00_FREQ = 146  # 439  # Hz
PIN_14_FREQ = 1990  # Hz


def pitch_frequency(pitch):
    """ Converts MIDI pitch to frequency """
    return 440 * 2 ** ((float(pitch) - 69.0) / 12.0)


def map_pitch_to_mb(pitch):
    freq = pitch_frequency(pitch)
    pin = int(round((float(freq) - PIN_00_FREQ) / (PIN_14_FREQ - PIN_00_FREQ) * 14))
    return max(min(pin, 14), 0)


holes = [Hole(float(e.tick) * units_per_tick, map_pitch_to_mb(e.pitch)) for e in note_events]

with open("../../../songs/mary.mbx", 'w') as file:
    for hole in holes:
        file.write("%s\n" % hole)

print min([x.pin for x in holes])

print holes

print units_per_tick
print tick_duration
