% eeg_htpCalcHabErp() - calculate amplitude ERP from Habitution paradigm.
%
%
% Usage:
%    >> [ EEG ] = eeg_htpCalcHabErp( EEG, varargin )
%
% Inputs:
%     EEG       - EEGLAB Structure
%     plotsOn   - ERP plot with extraction ROI bars
%     baseline  - Baseline latency range in milliseconds [start end]
%     
%  This file is part of the Cincinnati Visual High Throughput Pipeline,
%  please see http://github.com/cincibrainlab
%
%  Contact: lauren.ethridge@ou.edu (Original script)
%           ernest.pedapati@cchmc.org (EEGLAB function adaption)
%

function [EEG, results] = eeg_htpCalcHabErp( EEG, varargin )

defaultPlotsOn = 0;
defaultBaseline = [-500 0];

ip = inputParser;
addRequired(ip,'EEG',@isstruct);
addOptional(ip,'plotsOn', defaultPlotsOn);
addOptional(ip,'baseline', defaultBaseline);

parse(ip,EEG,varargin{:})

plotsOn = ip.Results.plotsOn;
baseline = ip.Results.baseline;

% remove baseline
EEG = pop_rmbase(EEG, baseline);

% define ROI of auditory cortex projection
chirp_sensor_labels = {'E23','E18','E16','E10','E3',...
    'E28','E24','E19','E11','E4','E124','E117',...
    'E29','E20','E12','E5','E118','E111','E13','E6','E112',...
    'E7','E106'};

% find sensor indexes
sensoridx = cell2mat(cellfun(@(x) find(strcmpi(x,{EEG.chanlocs.labels})), ...
    chirp_sensor_labels, 'uni',0));

% define analysis parameters
data               = squeeze(mean(EEG.data(sensoridx,:,:)));
erp                = mean(data,2);
t                  = EEG.times;
Fs                 = EEG.srate;
trials             = EEG.trials;

% define ROI indexes

% N1
n1a_idx = 276:316;
n1b_idx = 532:572;
n1c_idx = 789:829;
n1d_idx = 1049:1089;

% P1
p1a_idx = 316:356;
p1b_idx = 575:615;
p1c_idx = 835:875;
p1d_idx = 1093:1133;

N1 = cellfun( @(idx) min(erp(idx)), {n1a_idx, n1b_idx, n1c_idx, n1d_idx});
P1 = cellfun( @(idx) max(erp(idx)), {p1a_idx, p1b_idx, p1c_idx, p1d_idx});

N1PC = arrayfun( @(n1) (N1(1) - n1) / N1(1), [N1(2:4)]);
P1PC = arrayfun( @(p1) (P1(1) - p1) / P1(1), [P1(2:4)]);

if plotsOn
    roi_strip = nan(1,length(erp));
    roi_strip([n1a_idx n1b_idx n1c_idx n1d_idx]) = -.5;
    roi_strip([p1a_idx p1b_idx p1c_idx p1d_idx]) =  .5;
    figure;
    plot(t,erp); xlabel('Time (ms)'); ylabel('Amplitude (microvolts)');
    hold on;
    plot(t,roi_strip,'k.')
    title(sprintf('ERP average waveforms for %s', EEG.setname));
    xlim([-500 2500])
end

inforow = table({EEG.setname}, 'VariableNames', {'eegid'});
resultsrow = array2table([N1 P1 N1PC P1PC], 'VariableNames', {'N1R1','N1R2',...
    'N1R3', 'N1R4', 'P1R1', 'P1R2', 'P1R3', 'P1R4', ...
    'N1PerR2', 'N1PerR3', 'N1PerR4', 'P1PerR2', 'P1PerR3', 'P1PerR4'});

% store average ERP
EEG.etc.htp.hab.erp = erp;
EEG.etc.htp.hab.times = t;
EEG.etc.htp.hab.summary_table = [inforow resultsrow];

results = EEG.etc.htp.hab;

end