# Title     : TODO
# Objective : TODO
# Created by: Oscar.Borrego
# Created on: 9/29/2017

rm(list = ls())

library(tuneR);

SILENCE_FREQ = 0
PERIODOGRAM_WINDOW = 1024 # number of samples in a periodogram window (i.o.w a period)
NOTE_DURATION_MILLIS = 800
MIN_PEAK_SEP_PERIODS = 4

wave = readMP3('../../resources/mp3/twinkle.mp3');
# wave = mono(readMP3('../../resources/mp3/mary.mp3'));
SAMPLE_RATE = wave@samp.rate
NOTE_DURATION_SAMPLES = round(NOTE_DURATION_MILLIS / 1000 * SAMPLE_RATE)
SAMPLES = length(wave@left)

## todo: review, consider alternatives. Taking periodogram of an arbitrary window size.
## There is some inherent precission loss when taking these windows.
period = (periodogram(wave, width = PERIODOGRAM_WINDOW));
PERIODS = length(period@energy)

compute_peaks = function(){
    deltas = diff(period@energy)
    ## todo: review: using an arbitrary threshold of percentile 85
    threshold = qnorm(p = 0.85, mean = mean(deltas), sd = sd(deltas))
    peaks = which(deltas > threshold);
    ## todo: review: cleaning false peaks base on min inter-peak distance
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
    # plot_peaks();

    peaks;
};
peaks = compute_peaks();

compute_notes = function() {
    ## detect frequencies
    ffs = FF(period)

    from_period = peaks + 1
    to_period = c(peaks[- 1], PERIODS)
    freqs = mapply(from = from_period, to = to_period, function(from, to){
        # todo: refine, consider alternatives. just an initial approach: getting the median of the fundamental frequencies
        freq = median(ffs[from : to], na.rm = TRUE)
    });
    sample_peaks = peaks * PERIODOGRAM_WINDOW # in samples
    data.frame(offset = sample_peaks, freq = freqs)
};
notes = compute_notes();

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
        ## todo: review initial approach: using an exponential decay amplitude with arbitrary (constant) duration
        res_samples[mask] = res_samples[mask] + amplitude * sine(freq = freq, duration = duration, samp.rate = SAMPLE_RATE)@left;
    }
}

res_wave = normalize(Wave(left = res_samples, samp.rate = SAMPLE_RATE, bit = 32, pcm = FALSE))

# play result
player = NULL

if (Sys.info()[["sysname"]] == "Darwin") {
    player = "afplay"
}
play(res_wave, player)
# writeWave(res_wave, filename = '../../target/res.wav')
# writeWave(wave, filename = '../../target/orig.wav')
