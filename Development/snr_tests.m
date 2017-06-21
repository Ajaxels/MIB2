% 20us 0.04 Torr, 2.5kV
I = double(I1a);
Isignal = medfilt2(I, [3 3]);
snr=10*log10(mean((Isignal(:)).^2)/mean((I(:)-Isignal(:)).^2))


% 10us 0.02 Torr, 2.2kV
I = double(I2a);
Isignal = medfilt2(I, [3 3]);
snr=10*log10(mean((Isignal(:)).^2)/mean((I(:)-Isignal(:)).^2))

I = double(I3a);
Isignal = medfilt2(I, [3 3]);
snr=10*log10(mean((Isignal(:)).^2)/mean((I(:)-Isignal(:)).^2))