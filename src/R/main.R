# Title     : TODO
# Objective : TODO
# Created by: Oscar.Borrego
# Created on: 9/29/2017

library(tuneR);

PINS = 15
CLUSTERS = PINS
# CUTREE_HEIGHT = 40^2
CUTREE_HEIGHT = 20
SILENCE_FREQ = 0
MIN_NOTE_PERIODS = 10
PERIODOGRAM_WINDOW = 1024 # number of samples in a periodogram window (i.o.w a period)
PIN_DURATION_PERIODS = 24000 / PERIODOGRAM_WINDOW # in periods
MB_DELAY_MILLIS = 10
PERIOD_TO_MB_DELAY = round(PERIODOGRAM_WINDOW / 44100 * 1000 / MB_DELAY_MILLIS)

read_pin = function(pin) readWave(sprintf('../../resources/pin_%d.wav', pin))

pins = sapply(1 : PINS, FUN = read_pin)

ffs = unlist(lapply(pins, FUN = function(pin){
    ff = FF(periodogram(pin, width = PERIODOGRAM_WINDOW))
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
compute_ff_dat = function() {
    period = (periodogram(wave, width = PERIODOGRAM_WINDOW));
    ff = FF(period)

    ff_mask = ! is.na(ff);
    ff_avail = ff[ff_mask]
    dendogram = hclust(dist(ff_avail), method = 'centroid')
    ff_clusters = rep(NA, length(ff));
    ff_clusters[ff_mask] = cutree(dendogram, h = CUTREE_HEIGHT)
    ff_dat = data.frame(raw = ff, cluster = ff_clusters)



    ff_cent_agg = aggregate(formula = raw ~ cluster, data = ff_dat, FUN = median)
    ff_centroids = ff_cent_agg[order(ff_cent_agg$cluster), 2]
    ff_dat$centroid = round(ff_centroids[ff_dat$cluster])

    # reorder cluster numbers based on centroids so the graphs look better
    cluster_mapping = order(order(ff_centroids))
    ff_dat$cluster = cluster_mapping[ff_dat$cluster]

    ## smooth the centroids vector and detect the frequencies
    ## cent = ff_dat$centroid
    ## cent[is.na(cent)] = SILENCE_FREQ
    ## ff_dat$centroid = cent;
    ## #cent = runmed(cent, k = 9)
    ## ## note this algorithm does not support multiple concurrent notes
    ## ## to-do: support concurrent/multi-channel detection and translation to music-box format
    ## from = 1
    ## prev_freq = median(cent[1 : MIN_NOTE_PERIODS])
    ## for (i in 2 : (length(cent) + 1)) {
    ##     if (! identical(cent[i], cent[i - 1])) {
    ##         if (i - from >= MIN_NOTE_PERIODS) {
    ##             prev_freq = cent[i - 1]
    ##         } else {
    ##             cent[from : (i - 1)] = prev_freq;
    ##         }
    ##         from = i;
    ##     }
    ## }
    ## ff_dat$clean = cent;

    ff_dat
}
ff_dat = compute_ff_dat();

# compute_channel_intervals = function(){
K = max(ff_dat$cluster, na.rm = TRUE);
channels = sapply(1 : K, FUN = function(cluster){
    indexes = which(ff_dat$cluster == cluster);
    if (length(indexes) > 1) {
        dendogram = hclust(dist(indexes), method = 'single');
        intervals = cutree(dendogram, h = 2);
        dat = data.frame(indexes = indexes, intervals = intervals);

        aggregate(formula = indexes ~ intervals, data = dat, FUN = function(idx){
            range(idx)
        });
    } else {
        NULL
    }

});
# }

PLOT = FALSE
if (PLOT) {
    plot(ff_dat$centroid, pch = 16, col = ff_dat$cluster)
    lines(ff_dat$raw)
}
PLOT = TRUE
if (PLOT) {
    plot(ff_dat$centroid, pch = 16, col = ff_dat$cluster)
    lines(ff_dat$clean)
}
generate_music_box_output = function(){
    cent = ff_dat$clean
    # compute notes
    diff_ind = which(diff(cent) != 0)
    from = c(1, diff_ind + 1)
    to = c(diff_ind, length(cent))
    notes = data.frame(from = from, to = to, freq = cent[from])

    # compute music box pins
    # mask = notes$freq > SILENCE_FREQ
    mask = notes$freq > 80
    freq = notes$freq[mask]
    rang = range(freq)
    pin = rep(- 1, nrow(notes))
    pin[mask] = round((freq - rang[1]) / (rang[2] - rang[1]) * (PINS - 1))
    notes$pin = pin

    # generate music box output
    sink('../../songs/twinkle.mbx');
    delay = 0 # in periods
    for (i in 1 : nrow(notes)) {
        r = notes[i,]
        duration = r$to - r$from # in periods
        if (r$pin >= 0) {
            cat(sprintf("%d:%d\n", delay * PERIOD_TO_MB_DELAY, r$pin));
            beats = floor(duration / PIN_DURATION_PERIODS);
            delay = duration;
            if (beats > 1) {
                ## a single pin was not enough, repeat the same pin beats - 1 times
                for (k in 1 : (beats - 1)) {
                    cat(sprintf("%d:%d\n", round(PIN_DURATION_PERIODS * PERIOD_TO_MB_DELAY), r$pin))
                }
                # update the delay, subtracting the additional pin periods
                delay = round(delay - (beats - 1) * PIN_DURATION_PERIODS);
            }
        }else {
            # this is a silent note
            delay = delay + duration;
        }
    }
    sink(NULL);


    notes
}
# notes = generate_music_box_output();



## make resulting wave
GO = FALSE
if (GO) {
    sines = apply(notes, MARGIN = 1, FUN = function(ro){
        freq = ro['freq']
        duration = (ro['to'] - ro['from']) * PERIODOGRAM_WINDOW
        if (freq > SILENCE_FREQ) {
            sine(freq = freq, duration = duration)
        }else {
            names(duration) = NULL # bug in tuneR code
            silence(duration = duration)
        }
    });
    res = Reduce(bind, sines)
    # play(res)
}
