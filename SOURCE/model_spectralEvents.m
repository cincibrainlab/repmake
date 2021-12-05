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

basename    = 'spectralEvents'; % Edit
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

%=========================================================================%
%                            CONSTRUCT MODEL                              %
%=========================================================================%

%%   X{a} - m-by-n matrix (of the a^th subject/session cell in cell array X) 
%       representing the time-series trials of the given subject. m is the number
%       of timepoints and n is the number of trials. Note that m timepoints must 
%       be uniform across all trials and subjects.



% create channel m-by-n matrix nested in subject (load data once)
tmpMat = [];
for si = 1 : length(p.sub)
    current_sub = p.sub(si).subj_basename;
    
    p.sub(si).loadDataset('mne');
    if si == 1
        Fs = p.sub(si).EEG.srate;  % get sampling rate
        channames   = {p.sub(1).EEG.chanlocs.labels};
    end
    for ci = 1 : length(channames)
        current_channel = channames{ci};
        tmpMat.(current_sub).(current_channel) = p.sub(si).se_exportTrialsByChanName(channames{ci}, 500);
    end
    p.sub(si).unloadDataset;
end
% create subject m-by-n matrix nested in channels
chanmat = [];
classLabels = [];
for ci = channames
   
    for si = fieldnames(tmpMat)'

        chanmat.(ci{1}).(si{1}) = tmpMat.(si{1}).(ci{1});
        classLabels.(ci{1}).(si{1}) = 1;
    end
end

% Spectral Events Parameters
%% Define Band Ranges
bandDefs = {
    'delta', 2 , 3.5;
    'theta', 3.5, 7.5;
    'alpha1', 8, 10;
    'alpha2', 10.5, 12.5;
    'beta', 13, 30;
    'gamma1', 30, 55;
    'gamma2', 65, 90;
    'epsilon', 81, 120;
    };
bandDefs = {
    'theta', 3.5, 7.5;
    'alpha2', 10.5, 12.5;
    'gamma1', 30, 55;
    'gamma2', 65, 90;
    };
bandIntervals = [];
for bi = 1 : length(bandDefs)
    bandIntervals.(bandDefs{bi,1}) = [bandDefs{bi,2} bandDefs{bi,3}];
end

Fs = Fs;  % sample rate
findMethod = 1;
fVec = 2:90;
findMethod = 1;
vis = 0;

sig = [];
cl = [];
for ci = channames
    for si = 1 : length(p.sub)

        sig.(ci{1}).(p.sub(si).subj_basename) = chanmat.(ci{1}).(p.sub(si).subj_basename); %#ok<*SAGROW>
        cl.(ci{1}).(p.sub(si).subj_basename) =  classLabels.(ci{1}).(p.sub(si).subj_basename);
    end
end

specEvents = []; TFRs =[]; timeseries = [];
chanSpectralEvents = []; chanTFRs = []; chantimeseries = [];
    
for ci = channames
    disp(ci)
    for bi = fieldnames(bandIntervals)'
        
       eventBand = bandIntervals.(bi{1});

        sigX = struct2cell(sig.(ci{1}));
        clX = struct2cell(cl.(ci{1}));
        [specEvents.(bi{1}), ~,~] = fx_spectralevents(eventBand,fVec, ...
            Fs,findMethod, vis, sigX, ...
            clX);
%         [specEvents.(bi{1}), TFRs.(bi{1}), timeseries.(bi{1})] = fx_spectralevents(eventBand,fVec, ...
%             Fs,findMethod, vis, sigX, ...
%             clX); %Run spectral event analysis
    end

    chanSpectralEvents.(ci{1}) = specEvents;
    %chanTFRs.(ci{1}) = TFRs;
    %chantimeseries.(ci{1}) = timeseries;  
    

end

% Output Results to MAT File
save(target_file, 'chanSpectralEvents');
%%
% Create CSV
count = 1;
for ci = channames 
    disp(ci);
    channame = ci{1};
    se_tmp = chanSpectralEvents.(channame);
    for bi = fieldnames(bandIntervals)' 
       eventBand = bi{1};
       se_band_tmp = se_tmp.(eventBand);

       for si = 1 : numel(p.sub)

           % create CSV
           csvout{count, 1} = ci{1};
           csvout{count, 2} = bi{1};
           csvout{count, 3} = p.sub(si).subj_basename;
           csvout{count, 4} = se_TrialSummary.NumTrials;


           se_TrialSummary = se_band_tmp(si).("TrialSummary");
           se_Events = se_band_tmp(si).("Events");
           se_IEI = se_band_tmp(si).("IEI");


           features = {'eventnumber_median','eventnumber_mean','iei_mean','iei_median',...
               'eventduration_mean', 'noeventtrials_percent', 'eventpower_median','eventpower_mean', ...
               'trialpower_median','trialpower_mean', 'coverage_mean', 'fspan_mean'}; %Fields within specEv_struct

           for fi = features

               switch fi{1}
                   case 'eventnumber_median'
                       csvout{count, 5} = ...
                           median(se_TrialSummary.TrialSummary.eventnumber);
                   case 'eventnumber_mean'
                       csvout{count, 6} = ...
                           mean(se_TrialSummary.TrialSummary.eventnumber);
                   case 'iei_mean' % Inter-event interval (IEI)
                       csvout{count, 7} = ...
                           mean(se_IEI.IEI_all);
                   case 'iei_median' % Inter-event interval (IEI)
                       csvout{count, 8} = ...
                           median(se_IEI.IEI_all');
                   case 'eventduration_mean' % no empty trials
                       csvout{count, 9} = ...
                           sum(se_TrialSummary.TrialSummary.meaneventduration)/nnz(se_TrialSummary.TrialSummary.meaneventduration);
                   case 'noeventtrials_percent'
                       csvout{count, 10} = ...
                           sum(se_TrialSummary.TrialSummary.eventnumber' == 0) / se_TrialSummary.NumTrials;
                   case 'eventpower_median'
                       csvout{count, 11} = ...
                           median(se_TrialSummary.TrialSummary.meaneventpower);
                   case 'eventpower_mean'
                       csvout{count, 12} = ...
                           mean(se_TrialSummary.TrialSummary.meaneventpower);
                   case 'trialpower_median'
                       csvout{count, 13} = ...
                           median(se_TrialSummary.TrialSummary.meanpower);
                   case 'trialpower_mean'
                       csvout{count, 14} = ...
                           mean(se_TrialSummary.TrialSummary.meanpower);
                   case 'coverage_mean'
                       csvout{count, 15} = ...
                           mean(se_TrialSummary.TrialSummary.coverage);
                   case 'fspan_mean'
                       csvout{count, 16} = ...
                           sum(se_TrialSummary.TrialSummary.meaneventFspan) / nnz(se_TrialSummary.TrialSummary.meaneventFspan);
               end

           end
       count = count + 1;
       end
    end
end

target_file_secsv = strrep(target_file, ".mat", "_se.csv");

  % create CSV
           csvout{count, 1} = ci{1};
           csvout{count, 2} = bi{1};
           csvout{count, 3} = p.sub.subj_basename;
           csvout{count, 4} = se_TrialSummary.NumTrials;

columnNames = {'channel','band','eegid','notrials','eventnumber_median','eventnumber_mean','iei_mean','iei_median',...
               'eventduration_mean', 'noeventtrials_percent', 'eventpower_median','eventpower_mean', ...
               'trialpower_median','trialpower_mean', 'coverage_mean', 'fspan_mean'};

writetable(cell2table(csvout, 'VariableNames', columnNames), target_file_secsv);
