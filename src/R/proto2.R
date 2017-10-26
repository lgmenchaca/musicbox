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
PERIOD_TO_MB_DELAY = round(PERIODOGRAM_WINDOW / 44100 * 1000 / MB_DELAY_MILLIS)
SAMPLE_RATE = 44100
MIN_PEAK_SEP_PERIODS = 4

# wave = readMP3('../../resources/mp3/twinkle.mp3');
wave = mono(readMP3('../../resources/mp3/mary.mp3'));
compute_ff_dat = function() {
    period = (periodogram(wave, width = PERIODOGRAM_WINDOW));
    ff = FF(period)

    ff_mask = ! is.na(ff);
    ff_avail = ff[ff_mask]
    dendogram = hclust(dist(ff_avail), method = 'centroid')
    ff_clusters = rep(NA, length(ff));
    ff_clusters[ff_mask] = cutree(dendogram, h = CUTREE_FREQUENCY_HEIGHT)
    ff_dat = data.frame(raw = ff, cluster = ff_clusters)



    ff_cent_agg = aggregate(formula = raw ~ cluster, data = ff_dat, FUN = median)
    ff_centroids = ff_cent_agg[order(ff_cent_agg$cluster), 2]
    ff_dat$centroid = round(ff_centroids[ff_dat$cluster])

    # reorder cluster numbers based on centroids so the graphs look better
    cluster_mapping = order(order(ff_centroids))
    ff_dat$cluster = cluster_mapping[ff_dat$cluster]


    ff_dat
}
ff_dat = compute_ff_dat();

compute_channel_intervals = function() {
    K = max(ff_dat$cluster, na.rm = TRUE);
    cluster = 9
    Reduce(f = rbind, x = sapply(1 : K, FUN = function(cluster) {
        indexes = which(ff_dat$cluster == cluster);
        if (length(indexes) > 1) {
            dendogram = hclust(dist(indexes), method = 'single');
            intervals = cutree(dendogram, h = CUTREE_PERIOD_HEIGHT);
            dat = data.frame(indexes = indexes, intervals = intervals);

            intervals_dat = aggregate(formula = indexes ~ intervals, data = dat, FUN = range)[,2];
            data.frame(cluster = cluster, from = intervals_dat[,1], to = intervals_dat[,2], centroid = ff_dat[indexes[1],'centroid'])
        } else {
            NULL
        }
    }));
}
channels = compute_channel_intervals();

PLOT = FALSE
if (PLOT) {
    plot(ff_dat$centroid, pch = 1, col = ff_dat$cluster)
    #lines(ff_dat$raw)
    apply(channels, 1, function(row) {
        lines(row[c('from', 'to')], rep(row['centroid'], 2), col = row['cluster'] + 1, lwd = 2);
    });
}

PLOT = FALSE
if (PLOT) {
    plot(ff_dat$centroid, pch = 16, col = ff_dat$cluster)
    lines(ff_dat$clean)
}

## make resulting wave
GO = FALSE
if (GO) {
    res_samples = rep(SILENCE_FREQ, length(wave@left))
    for(i in 1 : nrow(channels)) {
        ro = channels[i,];
        freq = ro$centroid;
        offset = (ro$from - 1) * PERIODOGRAM_WINDOW # in samples
        duration = (ro$to - ro$from + 1) * PERIODOGRAM_WINDOW # in samples
        if (freq > SILENCE_FREQ && duration > 2 * PERIODOGRAM_WINDOW) {
            mask = offset + (1 : duration);
            res_samples[mask] = res_samples[mask] + sine(freq = freq, duration = duration)@left
        }
    }
    res_wave = normalize(Wave(left = res_samples, samp.rate = SAMPLE_RATE, bit = 32, pcm = FALSE))
    writeWave(res_wave, filename = '../../target/res.wav')
    writeWave(wave, filename = '../../target/orig.wav')
    # play(res_wave)
}

GO = TRUE
if (GO) {
    period = (periodogram(wave, width = PERIODOGRAM_WINDOW));
    deltas = diff(period@energy)
    threshold = quantile(deltas, 0.95)
    peaks = which(deltas > threshold);
    peaks = peaks[-(which(diff(peaks) < MIN_PEAK_SEP_PERIODS) + 1)];

    plot(wave, main="Wave peaks detection")
    abline(v=peaks * PERIODOGRAM_WINDOW / SAMPLE_RATE,col=2)
    legend(legend=c("wave","peaks"), x="bottomright", col=1:2, pch=16)

    res_samples = rep(SILENCE_FREQ, length(wave@left))
    for (peak in peaks) {
        offset = peak * PERIODOGRAM_WINDOW # in samples
        duration = 4 * PERIODOGRAM_WINDOW # in samples
        mask = offset + (1 : duration);
        res_samples[mask] = res_samples[mask] + sine(freq = 440, duration = duration)@left
    }

    res_wave = normalize(Wave(left = res_samples, samp.rate = SAMPLE_RATE, bit = 32, pcm = FALSE))
    writeWave(res_wave, filename = '../../target/res.wav')
    writeWave(wave, filename = '../../target/orig.wav')

}
