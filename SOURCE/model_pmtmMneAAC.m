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

matlab_00_common

eeglab nogui;

%=========================================================================%
% Step 2: Customize basename for script                                   %
%=========================================================================%

basename    = 'pmtmMneAAC'; % Edit
prefix      = ['model_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_contDataset.mat'; % any MAT/Parquet inputs (or NA)

if ~ismissing(data_file)
    load(fullfile(syspath.MatlabBuild, data_file))
end
    
%=========================================================================%
% Step 4: Specify target for interactive Matlab (no modification needed)  %
%=========================================================================%

output_file_extension = 'MAT'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.MatlabBuild, output_file_extension);
end

%=========================================================================%
%                            CONSTRUCT MODEL                              %
%=========================================================================%

%=========================================================================%
% BRAINSTORM       =======================================================%
% HELPER           Activate Brainstorm in no display (nogui) mode. Checks %
%                  and activates ProtocolName. Retrieves several key BST  %
%                  variables:                                             %
%                  protocol_name  protocol name                           %
%                  sStudy       study structure                           %
%                  sProtocol    protocol structure                        %
%                  sSubjects    subject structure                         %
%                  sStudyList   all assets in study                       %
%                  atlas        cortical atlas structure                  %
%                  sCortex      cortical structure                        %
%                  GlobalData   global brainstorm structure               %
%                                                                         %
ProtocolName          = 'FXSREST'; % set protocol name                    %
% brainstorm_01_common  % brainstorm include                                %
%                     script will end if wrong protocol                   %
%=========================================================================%
resultArr = {};
for si = 1 :  numel(p.sub)
    s = p.sub(si);
    s.loadDataset('signal');
    EEG = s.EEG;
    EEG = eeg_regepochs(EEG);
    s.unloadDataset;

    % EEG.data = gpuArray(double(EEG.data));
    %     EEG.data = gather(EEG.data);

    freqbands = 2:1:90;

    clear pxx cross_freq_corr
    for elecIdx = 1:EEG.nbchan
        x = squeeze(EEG.data(elecIdx,:,:)); % tp x trial (col)
        [pxx(:,:,elecIdx), ~] = pmtm(x, [], freqbands, EEG.srate);

        % freq x trial x chan
    end

    % frequency based correlation
    cube = permute(pxx, [2 1 3]); % trial x freq x chan
    % part 1 uni-channel
    for i=1:EEG.nbchan
        chan_slice = cube(:,:,i);
        cross_freq_corr(:,:,i) = corr(log(chan_slice)); % log-transform
        % freq x freq x chan
    end

    resultArr{si,1} = cross_freq_corr;
    resultArr{si,2} = pxx;
    
end

subnames = {p.sub.subj_basename};
cfc = resultArr(:,1);
psd = resultArr(:,2);
chans = {EEG.chanlocs.labels};

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    save(target_file, 'subnames', 'freqbands', 'chans', 'cfc', 'psd',"-v7.3")
    save(target_file, 'subnames', 'freqbands', 'chans', 'cfc', 'psd',"-v6")

    fprintf("Success: Saved %s", target_file);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
