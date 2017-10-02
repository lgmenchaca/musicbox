# Title     : TODO
# Objective : TODO
# Created by: Oscar.Borrego
# Created on: 9/29/2017

library(tuneR);

PINS = 1 : 15
CLUSTERS = length(PINS)
# CUTREE_HEIGHT = 40^2
CUTREE_HEIGHT = 20
SILENCE_FREQ = 0
MIN_NOTE_PERIODS = 10

read_pin = function(pin) readWave(sprintf('../../resources/pin_%d.wav', pin))



pins = sapply(PINS, FUN = read_pin)

ffs = unlist(lapply(pins, FUN = function(pin){
    ff = FF(periodogram(pin, width = 1024))
    ff = ff[! is.na(ff) & ff > 400 & ff < 1700]
    quantile(ff, 0.85)
}));

PLOT = FALSE
if (PLOT) {
    plot(ffs);
    lines(c(1, length(ffs)), ffs[c(1, length(ffs))]);
}

# wave = Reduce(bind, c(pins, rev(pins)))
wave = readMP3('../../resources/mp3/twinkle.mp3');

period = (periodogram(wave, width = 1024));
ff = FF(period)

ff_mask = ! is.na(ff);
ff_avail = ff[ff_mask]
# centers = seq(from = min(ff_avail), to = max(ff_avail), length = CLUSTERS)
dendogram = hclust(dist(ff_avail), method = 'centroid')
# kmeans_result = kmeans(x = ff_avail, centers = CLUSTERS)
ff_clusters = rep(NA, length(ff));
ff_clusters[ff_mask] = cutree(dendogram, h = CUTREE_HEIGHT)
ff_dat = data.frame(raw = ff, cluster = ff_clusters)

ff_cent_agg = aggregate(formula = raw ~ cluster, data = ff_dat, FUN = median)
ff_centroids = ff_cent_agg[order(ff_cent_agg$cluster), 2]
ff_dat$centroid = round(ff_centroids[ff_dat$cluster])

PLOT = FALSE
if (PLOT) {
    plot(ff_dat$centroid, pch = 16, col = ff_dat$cluster)
    lines(ff_dat$raw)
}

{
    cent = ff_dat$centroid
    cent[is.na(cent)] = SILENCE_FREQ
    ff_dat$centroid = cent;
    # cent = runmed(cent, k = 9)
    open = 1
    prev_freq = cent[open]
    # notes = matrix(numeric(0), ncol = 3, dimnames = list(NULL, c("open", "close", "freq")))
    for (i in 2 : length(cent)) {
        if (cent[i] != cent[i - 1]) {
            if (i - open >= MIN_NOTE_PERIODS) {
                prev_freq = cent[i - 1]
            } else {
                cent[open : (i - 1)] = prev_freq;
            }
            open = i;
        }
    }
    ff_dat$clean = cent;
}


PLOT = TRUE
if (PLOT) {
    plot(ff_dat$centroid, pch = 16, col = ff_dat$cluster)
    lines(ff_dat$clean)
}
