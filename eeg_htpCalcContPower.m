% eeg_htpCalcContPower() - calculate spectral power on continuous data.
%      Power is calculated using MATLAB pWelch function. Key parameter is
%      window length with longer window providing increased frequency
%      resolution. Overlap is set at default at 50%. A hanning window is
%      also implemented. Speed is greatly incrased by GPU. 
%
%      sapienlabs.org/factors-that-impact-power-spectrum-density-estimation/
%
% Usage:
%     >> [ EEG ] = eeg_htpCalcContPower( EEG, gpuon, duration )
%
% Inputs:
%     EEG       - EEGLAB Structure
%     gpuon     - [logical] use gpuArray. default: false
%     duration  - [integer] duration to calculate on. default: 80 seconds
%                 if duration is greater sample, will default to max size.
%     offset    - [integer] start time in seconds. default: 0
%     bandDefs  - [cell] format desired bands as follows (defaults shown):
%                     bandDefs = {
%                         'delta', 2 ,3.5;
%                         'theta', 3.5, 7.5;
%                         'alpha1', 8, 10;
%                         'alpha2', 10.5, 12.5;
%                         'beta', 13, 30;
%                         'gamma1', 30, 55;
%                         'gamma2', 65, 80;
%                         'epsilon', 81, 120;
%                         };
%
% Output:
%     EEG       - EEGLAB Structure with results added to [etc.htp] field
%                 [table] summary: subject chan power_type_bandname
%                 [table] spectro: channel average power for spectrogram
%
%  This file is part of the Cincinnati Visual High Throughput Pipeline,
%  please see http://github.com/cincibrainlab
%
%  Contact: ernest.pedapati@cchmc.org
%

function [EEG, results] = eeg_htpCalcContPower( EEG, varargin )

% function specific inputs
defaultGpu      = 0;
defaultDuration = 80;
defaultOffset   = 0;
defaultBandDefs = {
    'delta', 2 ,3.5;'theta', 3.5, 7.5; 'alpha1', 8, 10; 'alpha2', 10.5, 12.5;
    'beta', 13, 30;'gamma1', 30, 55; 'gamma2', 65, 80; 'epsilon', 81, 120;
    };

% common htp inputs

ip = inputParser;
addRequired(ip,'EEG',@isstruct);
addOptional(ip,'gpuOn',defaultGpu);
addOptional(ip,'duration',defaultDuration);
addOptional(ip,'offset',defaultOffset);
addParameter(ip,'bandDefs',defaultBandDefs);
parse(ip,EEG,varargin{:})

duration = ip.Results.duration;
gpuOn = ip.Results.gpuOn;
offset = ip.Results.offset;
bandDefs = ip.Results.bandDefs;

% Key Parameters
t         = duration; % time in seconds
fs        = EEG.srate;    % sampling rate
win       = ceil(2 * fs);   % window
nfft      = win;           % FFT points--
noverlap  = .5 * win;  % points overlap
samples   = t * fs; % if using time, number of samples
start_sample    = offset * fs; if start_sample == 0, start_sample = 1; end
total_samples = EEG.pnts * EEG.trials;
channo    = EEG.nbchan;
EEG.subject = EEG.setname;

labels    = bandDefs(:,1);
freq      = cell2mat(bandDefs(:,2:3));

% dataset validation
% is size sufficient for duration and offset?
if samples >= total_samples - start_sample
    samples = total_samples;
    start_samples = 1;  % in samples
    warning("Insufficient Data, using max samples.")
end

% calculate power from first and last frequency from banddefs
if ndims(EEG.data) > 2 %#ok<ISMAT>
    %dat = permute(detrend3(permute(EEG.data, [2 3 1])), [3 1 2]);
    dat = EEG.data;
    cdat = reshape(dat, size(dat,1), size(dat,2)*size(dat,3));
else
    cdat = EEG.data;
end

% define final input data
cdat = cdat(:, start_sample:end);

% switch on gpu
if gpuOn, cdat = gpuArray( cdat ); end

% power computation
[pxx,f] = pwelch(cdat', hanning(win), noverlap, freq(1,1):.5:freq(end,2), fs); %#ok<*ASGLU>

if gpuOn, pxx = gather( pxx ); f = gather(f); end

% power derivations
pow_abs = pxx(1:end,:);         % absolute power (V^2/Hz)
pow_db = 10*log10(pow_abs);     % absolute power dB/Hz

pow_rel = NaN*ones(size(pow_abs));  % relative power (unitless)
for chani = 1 : size(pow_rel,2)
    pow_rel(:, chani) = pow_abs(:, chani) ./ sum(pow_abs(:,chani));
end

% band averaged power
pow_prealloc = zeros(length(freq), channo);
pow_abs_band = pow_prealloc; pow_db_band = pow_prealloc; pow_rel_band = pow_prealloc;

for bandi = 1 : length(freq)
    current_band = freq(bandi,:);
    freqidx = [find(f==current_band(1)):find(f==current_band(2))];
    pow_abs_band(bandi,:) = squeeze(mean(pow_abs(freqidx,:),1));
    pow_db_band(bandi,:) = squeeze(mean(pow_db(freqidx,:),1));
    pow_rel_band(bandi,:) = squeeze(mean(pow_rel(freqidx,:),1));
end

% create output table
pow_abs_band  = pow_abs_band';
pow_db_band   = pow_db_band';
pow_rel_band  = pow_rel_band';

abs_labels = cellfun(@(x) sprintf('abs_%s',x), labels','uni',0);
db_labels = cellfun(@(x) sprintf('db_%s',x), labels','uni',0);
rel_labels = cellfun(@(x) sprintf('rel_%s',x), labels','uni',0);

allbandlabels = [abs_labels db_labels rel_labels];
powertable = array2table([pow_abs_band pow_db_band pow_rel_band], 'VariableNames', allbandlabels);

infocolumns = table(repmat(EEG.subject,channo,1), {EEG.chanlocs.labels}', 'VariableNames',{'eegid','chan'});

csvtable = [infocolumns, powertable];

spectro_values = array2table([f ...
    mean(pow_abs,2) mean(pow_db,2) mean(pow_rel,2)], ...
    'VariableNames', {'freq','abspow','dbpow','relpow'});

spectro_info = table(repmat(EEG.subject, length(f),1), ...
    repmat('mean',length(f),1),  'VariableNames', {'eegid','chan'});

EEG.etc.htp.pow.summary_table = csvtable;
EEG.etc.htp.pow.spectro = [spectro_info, spectro_values];
results = EEG.etc.htp.pow;

end