%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make         %
%=========================================================================%
% MODEL SCRIPT     =======================================================%
%                  This script generates a single model from a dataset    %
%                  and exports to either R Build folder or MATLAB build.  %
%                  Generally, R datasets are optimized for size & import  %
%                  whereas the MATLAB Build folder is for temporary and   %
%                  larger files.                                          %
%                  Notes:                                                 %
%                        matlab_00_common.m - common include file         %
%                        repmanClass - required class for helper methods  %
%                           included in htp_minimum distribution          %
%                        target_file - primary output tracked by Make     %
%=========================================================================%

%=========================================================================%
% CONFIGURATION    =======================================================%
%                  Define inputs and outputs. Filenames in RepMake stay   %
%                  consistent between the script name & any output files. %
%                  The prefix specifies type of output (i.e., figure_).   %
%                  This code automatically switches between a specific    %
%                  command line output file and if the script is run from %
%                  Matlab. Note: Cap sensitive and no spaces.             %
%=========================================================================%

%=========================================================================%
% Step 1: Load common packages, data, and functions.                      %
% ========================================================================%

eeglab nogui;

%=========================================================================%
% Step 2: Customize basename for script                                   %
%=========================================================================%

basename    = 'IAPF'; % Edit
prefix      = ['model_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_makeMne.mat'; % any MAT/Parquet inputs (or NA)

if ~ismissing(data_file)
    load(fullfile(syspath.BigBuild, data_file))
end

%=========================================================================%
% Step 4: Specify target for interactive Matlab (no modification needed)  %
%=========================================================================%

output_file_extension = 'MAT'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.BigBuild, output_file_extension);
end

target_file_elec = strrep(target_file,".mat","_elec.csv");
target_file_source = strrep(target_file,".mat","_src.csv");


%=========================================================================%
%                            CONSTRUCT MODEL                              %
%=========================================================================%

% %% Define Band Ranges
% bandDefs = {
%     'delta', 2 , 3.5;
%     'theta', 3.5, 7.5;
%     'alpha1', 8, 10;
%     'alpha2', 10.5, 12.5;
%     'beta', 13, 30;
%     'gamma1', 30, 55;
%     'gamma2', 65, 90;
%     'epsilon', 81, 120;
%     };
% 
% bandLabels = bandDefs(:,1);
% bandIntervals = cell2mat(bandDefs(:,2:3));


bandDefsTmp = cfg.predefinedBands(:,1:2);
bandDefs = {};
for bandi = 1 : length(bandDefsTmp)
    bandDefs{bandi,1} = bandDefsTmp{bandi,1};
    range = str2num(bandDefsTmp{bandi,2});
    bandDefs{bandi,2} = range(1);
    bandDefs{bandi,3} = range(2);
end

bandIntervals = cell2mat(bandDefs(:,2:3));

% Main Subject by Subject Loop
totalsub = numel(p.sub);
resultArr1 = cell(totalsub,1);
resultArr2 = cell(totalsub,1);
   
% peak_loc = NaN(totalsub,s.EEG.nbchan);
%%
sub = p.sub;
for si = 1 :  totalsub

    % load EEG signal
    s = sub(si);
    s.loadDataset('signal');

    epoch_length = s.EEG.pnts / s.EEG.srate;
    freq = bandIntervals;

    power_results{i, 1} = s.subj_basename;
    %=========================================================================%
    % DATA PREPARATION      Data is detrended prior to power calculation and  %
    %                       converted to continuous data.
    %=========================================================================%

    dat = permute((permute(s.EEG.data, [2 3 1])), [3 1 2]);
    cdat = reshape(dat, size(dat,1), size(dat,2)*size(dat,3));

    %=========================================================================%
    % PWELCH PARAMETERS                                                       %
    %=========================================================================%

    fs  = s.EEG.srate;    % sampling rate
    win = ceil(2 * fs);   % window
    nfft = win;           % FFT points--
    noverlap = .5 * win;  % points overlap

    %=========================================================================%
    % PWELCH COMPUTATION                                                      %
    %=========================================================================%

    % [pxx,f] = pwelch(cdat', hanning(win), noverlap, nfft, fs,'onesided');
    [pxx,f] = pwelch(cdat', hanning(win), noverlap, ...
        bandIntervals(1):.5:bandIntervals(end), fs);

    freqlist = bandIntervals(1):.5:bandIntervals(end);

    spectrum = pxx;

    for i=1:s.EEG.nbchan
        [pks,locs] = findpeaks(log10(spectrum(:,i)));

        window = freqlist(locs) >= 6 & freqlist(locs) <= 14;
        window_old = locs>=6*2+1 & locs<=14*2+1; % [6, 14] Hz

        if any(window)
            peak_locs = locs(window);
            [~,index] = max(pks(window));

            peak_locs_old = locs(window_old);
            [~,index_old] = max(pks(window_old));

            peak_loc(si, i) = freqlist(peak_locs(index)); %#ok<SAGROW> 
            %peak_loc_old(i) = (peak_locs(index_old)-1)/2; % in Hz
        else
            continue % no max -> NaN
        end
    end
end
%%
peak_loc_elec = NaN(totalsub,s.EEG.nbchan);

sub = p.sub;
for si = 1 :  totalsub

    % load EEG signal
    s = sub(si);
    s.loadDataset('postcomps');

    try
    EEG = pop_select(EEG, 'trial',1:40);
    catch
        warning('too few trials');
    end

    epoch_length = EEG.pnts / EEG.srate;
    freq = bandIntervals;

    power_results{i, 1} = s.subj_basename;
    %=========================================================================%
    % DATA PREPARATION      Data is detrended prior to power calculation and  %
    %                       converted to continuous data.
    %=========================================================================%

    dat = permute((permute(EEG.data, [2 3 1])), [3 1 2]);
    cdat = reshape(dat, size(dat,1), size(dat,2)*size(dat,3));

    %=========================================================================%
    % PWELCH PARAMETERS                                                       %
    %=========================================================================%

    fs  = EEG.srate;    % sampling rate
    win = ceil(2 * fs);   % window
    nfft = win;           % FFT points--
    noverlap = .5 * win;  % points overlap

    %=========================================================================%
    % PWELCH COMPUTATION                                                      %
    %=========================================================================%

    % Troubleshooting
    bandIntervals(1) = 0;

    % [pxx,f] = pwelch(cdat', hanning(win), noverlap, nfft, fs,'onesided');
    [pxx,f1] = pwelch(cdat', hanning(win), noverlap, ...
        bandIntervals(1):.5:bandIntervals(end), fs);

    trial_spectrogram = @(chan_series) spectrogram(chan_series, hanning(win), noverlap, ...
        bandIntervals(1):.5:bandIntervals(end), fs);

    freqBins = bandIntervals(1):.5:bandIntervals(end);

    for i=1:EEG.nbchan
        [pks,locs] = findpeaks(log10(spectrum(:,i)));

        window = freqlist(locs) >= 5 & freqlist(locs) <= 14;
        window_old = locs>=5*2+1 & locs<=14*2+1; % [6, 14] Hz

        if any(window)
            peak_locs = locs(window);
            [~,index] = max(pks(window));

            peak_locs_old = locs(window_old);
            [~,index_old] = max(pks(window_old));

            peak_loc_elec(si, i) = freqlist(peak_locs(index));
            peak_loc_old(i) = (peak_locs(index_old)-1)/2; % in Hz
        else
            continue % no max -> NaN
        end
    end
end



%
    % Plot verification
    figure;
    subplot(1,3,1)
    plot(freqlist,mean(log10(spectrum),2))
    xlim([0 20])
    title('Mean Spectrogram');
    xlabel("Hz")
    hold on;
    xline(7);
    axis square;
    subplot(1,3,2)
    hist(peak_loc_old,10)
    ylim([0 60])
    xlabel("Hz")
    axis square;
    title('Original peakdetect v1')
    subplot(1,3,3)
    hist(peak_loc_elec,10);
    ylim([0 60])
    xlabel("Hz")
    title('Revised Algo');
    sgtitle('Peak Detection (Revision)');
    axis square

    s.unloadDataset;
    EEG = [];

%% create Source Peak CSV
csvout = {};
count = 1;
for si = 1 : totalsub
    sub = p.sub(si);
    curPeak = peak_loc(si,:);

    if si == 1
        sub.loadDataset('signal');
        chanlocs = sub.EEG.chanlocs;
        sub.unloadDataset();
    end

    for ci = 1 : 1 : length(chanlocs)

    csvout{count, 1} = sub.subj_basename;
    csvout{count, 2} = chanlocs(ci).labels;
    csvout{count, 3} = curPeak(ci);
    
    count = count + 1;
    end

end
csv_source = cell2table(csvout,"VariableNames",{'eegid','Electrode','peakFreq'});
writetable(csv_source,target_file_source);


%% create Source Peak CSV
csvout_elec = {};
count = 1;
for si = 1 : totalsub
    sub = p.sub(si);
    curPeak = peak_loc_elec(si,:);

    if si == 1
        sub.loadDataset('postcomps');
        chanlocs = sub.EEG.chanlocs;
        sub.unloadDataset();
    end

    for ci = 1 : 1 : length(chanlocs)

    csvout_elec{count, 1} = sub.subj_basename;
    csvout_elec{count, 2} = chanlocs(ci).labels;
    csvout_elec{count, 3} = curPeak(ci);
    
    count = count + 1;
    end

end

csv_elec = cell2table(csvout_elec,"VariableNames",{'eegid','Electrode','peakFreq'});
writetable(csv_elec,target_file_elec);

%%

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    % target_file_net_csv = strrep(target_file,'.mat', '_net.csv');
    target_file_node_csv = strrep(target_file,'.mat', '_68node.csv');

    % writetable(resTableNetwork, target_file_net_csv );
    writetable(resTableNode, target_file_node_csv );

    % save(target_file, 'subnames', 'freqbands', 'chans', 'cfc', 'psd',"-v7.3")
    %save(strrep(target_file,'.mat', '_cfc.mat'), 'subnames', 'freqbands', 'chans', 'cfc',"-v6")
    %save(strrep(target_file,'.mat', '_psd.mat'), 'subnames', 'freqbands', 'chans', 'psd',"-v6")

    fprintf("Success: Saved %s", target_file_node_csv);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
