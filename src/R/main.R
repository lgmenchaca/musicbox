# Title     : TODO
# Objective : TODO
# Created by: Oscar.Borrego
# Created on: 9/29/2017

rm(list = ls())

library(tuneR);

PINS = 15
CLUSTERS = PINS
CUTREE_FREQUENCY_HEIGHT = 20
CUTREE_PERIOD_HEIGHT = 5
SILENCE_FREQ = 0
MIN_NOTE_PERIODS = 10
PERIODOGRAM_WINDOW = 1024 # number of samples in a periodogram window (i.o.w a period)
PIN_DURATION_PERIODS = 24000 / PERIODOGRAM_WINDOW # in periods
MB_DELAY_MILLIS = 10
NOTE_DURATION_MILLIS = 400
# SAMPLE_RATE = 44100
MIN_PEAK_SEP_PERIODS = 4

wave = readMP3('../../resources/mp3/twinkle.mp3');
# wave = mono(readMP3('../../resources/mp3/mary.mp3'));
SAMPLE_RATE = wave@samp.rate
NOTE_DURATION_SAMPLES = round(NOTE_DURATION_MILLIS / 1000 * SAMPLE_RATE)
SAMPLES = length(wave@left)

period = (periodogram(wave, width = PERIODOGRAM_WINDOW));
PERIODS = length(period@energy)

deltas = diff(period@energy)
threshold = qnorm(p = 0.85, mean = mean(deltas), sd = sd(deltas))
peaks = which(deltas > threshold);
peaks = peaks[- (which(diff(peaks) < MIN_PEAK_SEP_PERIODS) + 1)];


## plot deltas
plot_deltas = function() {
    plot(deltas, type = 'l')
    abline(h = threshold, col = 2)
};
# plot_deltas();

## plot peaks
plot_peaks = function() {
    plot(wave, main = "Wave peaks detection")
    abline(v = peaks * PERIODOGRAM_WINDOW / SAMPLE_RATE, col = 2)
    legend(legend = c("wave", "peaks"), x = "bottomright", col = 1 : 2, pch = 16)
};
plot_peaks();


## detect frequency
sample_peaks = peaks * PERIODOGRAM_WINDOW # in samples
ffs = FF(period)

from_period = peaks + 1
to_period = c(peaks[- 1], PERIODS)
freqs = mapply(from = from_period, to = to_period, function(from, to){
    freq = median(ffs[from : to], na.rm = TRUE)
});
notes = data.frame(offset = sample_peaks, freq = freqs)

## generate resulting wave
res_samples = rep(SILENCE_FREQ, length(wave@left))
for (i in 1 : nrow(notes)) {
    ro = notes[i,];
    freq = ro$freq;
    if (! is.na(freq) && freq > SILENCE_FREQ) {
        offset = ro$offset;
        duration = NOTE_DURATION_SAMPLES;
        mask = offset + 1 : duration;
        amplitude = exp(- seq(from = 0, to = 5, length = duration))
        res_samples[mask] = res_samples[mask] + amplitude * sine(freq = freq, duration = duration, samp.rate = SAMPLE_RATE)@left;
    }
}

res_wave = normalize(Wave(left = res_samples, samp.rate = SAMPLE_RATE, bit = 32, pcm = FALSE))
play(res_wave)
# writeWave(res_wave, filename = '../../target/res.wav')
# writeWave(wave, filename = '../../target/orig.wav')

