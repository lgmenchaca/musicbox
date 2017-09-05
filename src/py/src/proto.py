#!/usr/bin/python

import midi
import sys

"""
  ** Notes taken from https://github.com/vishnubob/python-midi#Side_Note_What_is_a_MIDI_Tick **

  There are 27 different MIDI Events supported. In this example, three different MIDI events are created and added to the
  MIDI Track:

  The NoteOnEvent captures the start of note, like a piano player pushing down on a piano key. The tick is when this
  event occurred, the pitch is the note value of the key pressed, and the velocity represents how hard the key was pressed.
  The NoteOffEvent captures the end of note, just like a piano player removing her finger from a depressed piano key.

  Once again, the tick is when this event occurred, the pitch is the note that is released, and the velocity has no real
  world analogy and is usually ignored. NoteOnEvents with a velocity of zero are equivalent to NoteOffEvents.

  The EndOfTrackEvent is a special event, and is used to indicate to MIDI sequencing software when the song ends. With
  creating Patterns with multiple Tracks, you only need one EndOfTrack event for the entire song. Most MIDI software will
  refuse to load a MIDI file if it does not contain an EndOfTrack event.
"""

pattern = midi.read_midifile(sys.stdin)
note_events = []


def event_filter(event):
    return (type(event) == midi.events.NoteOnEvent and event.channel == 0) or (type(event) == midi.events.SetTempoEvent)


for track in pattern:
    note_events = filter(event_filter, track)
    if len(note_events) > 0:
        break


class Hole(object):
    def __init__(self, pos, pin):
        self.pos = pos
        self.pin = pin

    def __repr__(self):
        return "%d:%d" % (self.pos, self.pin)


def compute_units_per_tick(bpm=120):
    ppq = pattern.resolution
    # tick duration in milliseconds
    tick_duration = 60.0 * 1000 / bpm / ppq

    # units per tick
    return tick_duration / 10.0


# This site has some interesting tables with MIDI - piano keys mappings:
# http://www.sengpielaudio.com/calculator-notenames.htm
PIN_00_FREQ = 146  # 439  # Hz
PIN_14_FREQ = 500  # 1990  # Hz


def pitch_frequency(pitch):
    """ Converts MIDI pitch to frequency """
    return 440 * 2 ** ((float(pitch) - 69.0) / 12.0)


def map_pitch_to_mb(pitch):
    freq = pitch_frequency(pitch)
    pin = int(round((float(freq) - PIN_00_FREQ) / (PIN_14_FREQ - PIN_00_FREQ) * 14))
    return max(min(pin, 14), 0)


holes = []
tick = 0
units_per_tick = compute_units_per_tick()
for event in note_events:
    # events with velocity 0 are equivalent to note off events
    if type(event) == midi.events.NoteOnEvent and event.velocity > 0:
        holes.append(Hole(pos=float(tick + event.tick) * units_per_tick, pin=map_pitch_to_mb(event.pitch)))
        tick = 0
    else:
        tick += event.tick
        if type(event) == midi.events.SetTempoEvent:
            units_per_tick = compute_units_per_tick(event.get_bpm())

with open("../../../songs/mary.mbx", 'w') as file:
    for hole in holes:
        file.write("%s\n" % hole)

print pattern.__dict__
print pattern

print holes

print units_per_tick
print tick_duration
