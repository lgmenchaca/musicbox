# Title     : TODO
# Objective : TODO
# Created by: Oscar.Borrego
# Created on: 9/29/2017

library(tuneR);

PINS = 1 : 15

read_pin = function(pin) readWave(sprintf('../../resources/pin_%d.wav', pin))


pins = sapply(PINS, FUN = read_pin)

ffs = unlist(lapply(pins, FUN = function(pin){
    ff = FF(periodogram(pin, width = 1024))
    ff = ff[! is.na(ff) & ff > 400 & ff < 1700]
    quantile(ff, 0.85)
}));
plot(ffs);
lines(c(1,length(ffs)), ffs[c(1,length(ffs))]);

wave = Reduce(bind, c(pins, rev(pins)))

