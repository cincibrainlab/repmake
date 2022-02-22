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

basename    = 'elecChirp'; % Edit
prefix      = ['model_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_loadDataset.mat'; % any MAT/Parquet inputs (or NA)

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
% target_file_source = strrep(target_file,".mat","_src.csv");


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
itcArr = cell(totalsub,1);
ersp1Arr = cell(totalsub,1);
n2Arr = cell(totalsub,1);

% peak_loc = NaN(totalsub,s.EEG.nbchan);
%%

% create critical values
for i=1:400
    rcrits(i,1)=sqrt(-(1/i)*log(.5));
end

chirp_sensors = {'E23','E18','E16','E10','E3',...
    'E28','E24','E19','E11','E4','E124','E117',...
    'E29','E20','E12','E5','E118','E111','E13','E6','E112',...
    'E7','E106'};

subnames = {p.sub.subj_basename};
sub = p.sub;

for si = 1 :  totalsub
    si
    % load EEG signal
    s = sub(si);
    s.loadDataset('postcomps');

    EEG = s.EEG;
    epoch_length = EEG.pnts / EEG.srate;    freq = bandIntervals;
    trialnumber = EEG.trials;

    sensoridx = cellfun(@(x) find(strcmpi(x,{EEG.chanlocs.labels})), ...
        chirp_sensors, 'uni',0);
    sensoridx = cell2mat(sensoridx);

    data            = mean(EEG.data(sensoridx,:,:));

    frames          = EEG.pnts;
    epochlim        = [-500 2750]; % -500 2750
    srate           = EEG.srate;
    cycles          = [1 30];
    winsize         = 100;
    nfreqs          = 119;
    freqs           = [2 120];
    timesout        = 250;

    [ersp1,itc,n2,t_s,f_s]=newtimef( data, frames, epochlim, EEG.srate,[1 30],...
        'winsize',100,'nfreqs',119,'freqs',[2 120], ...
        'plotersp','off','plotitc','off','verbose','off',...
            'baseline',NaN,'timesout',250);

    ITC1=(abs(itc))-rcrits(trialnumber);
    
    VariableNames = {'subnames','itc1','ersp1','n2','t_s','f_s'};
    %resultArr1{si} = {VariableNames, ITC1, ersp1, n2, t_s, f_s};

    itcArr{si} = ITC1;
    ersp1Arr{si} = ersp1;
    n2Arr{si} = n2;

    %figure; imagesc(t_s,f_s,ersp1), axis xy;
    %figure; imagesc(t_s,f_s,ITC1), axis xy;

    % ITC1 dimension = 119 x 250
    % ERSP1 dim = 118 x 250
    
end

%% Identify ROIs
roi_ERSP_gamma_hz = find(f_s >= 30 & f_s <=100);
roi_ERSP_gamma1_hz = find(f_s >= 30 & f_s <=60);
roi_ERSP_gamma2_hz = find(f_s >= 60 & f_s <=100);
roi_ERSP_alpha_hz = find(f_s >= 8 & f_s <= 12);

roi_ErpOnset_hz = find(f_s >= 2 & f_s <= 13);
roi_ErpOnset_ms = find(t_s >= 92 & t_s <= 308);
roi_ErpOffset_hz = find(f_s >= 2 & f_s <= 13);
roi_ErpOffset_ms = find(t_s >= 2038 & t_s <= 2254);

roi_ITC40_hz1_og = find(f_s >= 31 & f_s <=42);
roi_ITC40_ms1_og = find(t_s >= 676 & t_s <= 784);
roi_ITC40_hz2_og = find(f_s >= 43 & f_s <=46);
roi_ITC40_ms2_og = find(t_s >= 796 & t_s <= 980);
roi_ITC40_hz3_og = find(f_s >= 47 & f_s <=57);
roi_ITC40_ms3_og = find(t_s >= 990 & t_s <= 1066);

roi_ITC40_hz1 = find(f_s >= 31 & f_s <=35);
roi_ITC40_ms1 = find(t_s >= 650 & t_s <= 850);
roi_ITC40_hz2 = find(f_s >= 35 & f_s <=40);
roi_ITC40_ms2 = find(t_s >= 750 & t_s <= 950);
roi_ITC40_hz3 = find(f_s >= 40 & f_s <=45);
roi_ITC40_ms3 = find(t_s >= 850 & t_s <= 1050);
roi_ITC40_hz4 = find(f_s >= 45 & f_s <=50);
roi_ITC40_ms4 = find(t_s >= 950 & t_s <= 1150);
roi_ITC40_hz5 = find(f_s >= 50 & f_s <=55);
roi_ITC40_ms5 = find(t_s >= 1050 & t_s <= 1250);

roi_ITC80_hz = find(f_s >= 70 & f_s <=100);
roi_ITC80_ms = find(t_s >= 1390 & t_s <= 1930);

% Extract subject level values for each ROI

itcCell = cellfun(@(c) c(:,:), itcArr,'uni',0);
erspCell = cellfun(@(c) c(:,:), ersp1Arr,'uni',0);

itcSub = cat(3,itcCell);
erspSub = cat(3,erspCell);

roiTable = cell(length(itcSub),10);

roiTable(:,1) = subnames;
roiTable(:,2) = cellfun(@(x) mean2(x(roi_ERSP_gamma_hz,:)), erspSub, 'uni',0);
roiTable(:,3) = cellfun(@(x) mean2(x(roi_ERSP_gamma1_hz,:)), erspSub, 'uni',0);
roiTable(:,4) = cellfun(@(x) mean2(x(roi_ERSP_gamma2_hz,:)), erspSub, 'uni',0);
roiTable(:,5) = cellfun(@(x) mean2(x(roi_ERSP_alpha_hz,:)), erspSub, 'uni',0);

roiTable(:,6) =  cellfun(@(x) ( mean2(x(roi_ITC40_hz1_og, roi_ITC40_ms1_og)) + mean2(x(roi_ITC40_hz2_og, roi_ITC40_ms2_og)) +...
    mean2(x(roi_ITC40_hz3_og,roi_ITC40_ms3_og)) ) / 3, itcSub, 'uni',0);

roiTable(:,7) = cellfun(@(x) ( mean2(x(roi_ITC40_hz1,roi_ITC40_ms1)) + mean2(x(roi_ITC40_hz2,roi_ITC40_ms2)) +...
    mean2(x(roi_ITC40_hz3,roi_ITC40_ms3)) + mean2(x(roi_ITC40_hz4,roi_ITC40_ms4)) + ...
    mean2(x(roi_ITC40_hz5,roi_ITC40_ms5) ) /5 ), itcSub, 'uni',0);

roiTable(:,8) = cellfun(@(x) mean2(x(roi_ITC80_hz,roi_ITC80_ms)), itcSub, 'uni',0);
roiTable(:,9) = cellfun(@(x) mean2(x(roi_ErpOnset_hz,roi_ErpOnset_ms)), itcSub, 'uni',0);
roiTable(:,10) = cellfun(@(x) mean2(x(roi_ErpOffset_hz,roi_ErpOffset_ms)), itcSub, 'uni',0);

roiCsv = cell2table(roiTable, "VariableNames", {'eegid','ersp_gamma','ersp_gamma1','ersp_gamma2', ...
    'ersp_alpha', 'itc40_og', 'itc40', 'itc80', 'erponset', 'erpoffset'});

grouplist = readtable("BIGBUILD/Proj_FxsChirp/group_list_exportR.csv");

roiCsvExport = innerjoin(roiCsv, grouplist,'LeftKeys','eegid','RightKeys','eeg_og');

writetable(roiCsvExport,target_file_elec);

%% VISUALIZATION
% 
% 
% fxsidx=strcmp(grouplist.group,"FXS")
% tdcidx=strcmp(grouplist.group,"TDC")
% 
% itcMean = mean(cat(3,itcCell{fxsidx}),3);
% itcMean2 = mean(cat(3,itcCell{tdcidx}),3);
% 
% % 30 to 55 Hz mean across all times (no baseline correction)
% % do mouse folks do baseline correction?
% erspMean = mean(cat(3,erspCell{fxsidx}),3);
% erspMean2 = mean(cat(3,erspCell{tdcidx}),3);
% 
% itcdiff = itcMean - itcMean2;
% erspdiff = erspMean-erspMean2;
% 
% erspdiff_roi = erspdiff; 
% erspdiff_roi(roi_ERSP,:) = 1;
% %%
% itcdiff_roi = itcdiff;
% itcdiff_roi(roi_ErpOnset_hz, roi_ErpOnset_ms) = .5;
% itcdiff_roi(roi_ErpOffset_hz, roi_ErpOffset_ms) = .5;
% 
% itcdiff_roi(roi_ErpOffset_hz, roi_ErpOffset_ms) = .5;
% 
% itcdiff_roi(roi_ITC40_hz1, roi_ITC40_ms1) = .5;
% itcdiff_roi(roi_ITC40_hz2, roi_ITC40_ms2) = .5;
% itcdiff_roi(roi_ITC40_hz3, roi_ITC40_ms3) = .5;
% itcdiff_roi(roi_ITC40_hz4, roi_ITC40_ms4) = .5;
% itcdiff_roi(roi_ITC40_hz5, roi_ITC40_ms5) = .5;
% %itcdiff_roi(roi_ITC40_hz6, roi_ITC40_ms6) = 10;
% 
% itcdiff_roi(roi_ITC80_hz, roi_ITC80_ms) = .5;
% 
% 
% 
% figure; 
% colormap jet;
% subplot(2,4,1)
% imagesc(t_s,f_s,erspMean), axis xy;
% subplot(2,4,2)
% imagesc(t_s,f_s,erspMean2), axis xy;
% subplot(2,4,3)
% imagesc(t_s,f_s,erspdiff), axis xy;
% subplot(2,4,4)
% imagesc(t_s,f_s,erspdiff_roi), axis xy;
% 
% 
% subplot(2,4,5)
% imagesc(t_s,f_s,itcMean), axis xy;
% subplot(2,4,6)
% imagesc(t_s,f_s,itcMean2), axis xy;
% subplot(2,4,7)
% imagesc(t_s,f_s,itcdiff), axis xy;
% subplot(2,4,8)
% imagesc(t_s,f_s,itcdiff_roi), axis xy;
% %%
% mean(itcMean,3)
%     
% % csv_elec = cell2table(csvout_elec,"VariableNames",{'eegid','Electrode','peakFreq'});
% % writetable(csv_elec,target_file_elec);
% 
% %%

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    % target_file_net_csv = strrep(target_file,'.mat', '_net.csv');
    %target_file_node_csv = strrep(target_file,'.mat', '_68node.csv');

    % writetable(resTableNetwork, target_file_net_csv );
    % writetable(resTableNode, target_file_node_csv );

    % save(target_file, 'VariableNames', 'resultArr1', '-v6')

     save(target_file, 'VariableNames', 'subnames','itcArr',...
         'ersp1Arr','n2Arr','t_s','f_s','-v6')
    %save(strrep(target_file,'.mat', '_cfc.mat'), 'subnames', 'freqbands', 'chans', 'cfc',"-v6")
    %save(strrep(target_file,'.mat', '_psd.mat'), 'subnames', 'freqbands', 'chans', 'psd',"-v6")

    fprintf("Success: Saved %s\n", target_file);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
