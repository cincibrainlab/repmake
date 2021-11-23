function [sig, t, N] = fx_eegfilt(Fs, locutoff, hicutoff, x) % Filter into high freq band.
dt = 1 / Fs;

% Fs = 500;
fNQ = Fs/2;
% locutoff = 5;                             % High freq passband = [100, 140] Hz.
% hicutoff = 7;
filtorder = 10*fix(Fs/locutoff);
MINFREQ = 0;
trans          = 0.15;                      % fractional width of transition zones
f=[MINFREQ (1-trans)*locutoff/fNQ locutoff/fNQ hicutoff/fNQ (1+trans)*hicutoff/fNQ 1];
m=[0       0                      1            1            0                      0];
filtwts = firls(filtorder,f,m);             % get FIR filter coefficients
sig = filtfilt(filtwts,1, double(x'));            % Define high freq band activity.

% Drop the edges of filtered data to avoid filter artifacts.
sig = sig(Fs*4:end-Fs*4,:);
t   = (1:length(sig))*dt;
N   = length(sig);

end