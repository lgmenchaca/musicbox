#!/usr/bin/python
import midi
pattern = midi.read_midifile("../resources/mary.mid")
print pattern[0]
print pattern.__dict__
