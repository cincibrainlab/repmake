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

basename    = 'powpowAAC'; % Edit
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

totalsub = numel(p.sub);
resultArr1 = cell(totalsub,1);
resultArr2 = cell(totalsub,1);

sub = p.sub;
for si = 1 :  totalsub
    s = sub(si);
    s.loadDataset('signal');
    EEG = s.EEG;
    %EEG = eeg_regepochs(EEG);
    chanlocs = EEG.chanlocs;
    s.unloadDataset;

    EEG.data = gpuArray(double(EEG.data));
    %EEG.data = gather(EEG.data);
    %EEG.data = double(EEG.data);

    upperFreqLimit = 90;
    inputDataType = 1;
    methodType = 2;
    numIterations = 2;
    useRelativePower = true;

    EEG = calc_PowPowCAT(EEG, upperFreqLimit, inputDataType, methodType, numIterations, useRelativePower);
    EEG.etc.PowPowCAT.eegid = s.subj_basename;
    EEG.etc.PowPowCAT.chanlocs = EEG.chanlocs;
    EEG.etc.PowPowCAT.freqs = gather(EEG.etc.PowPowCAT.freqs);

    resultArr1{si} = EEG.etc.PowPowCAT;
    EEG = [];
end

% Create output table for R
freqs = resultArr1{1}.freqs;

bandinfo = cell2struct(cfg.predefinedBands, {'bandname','range','measure'},2);
bandroi = find(ismember({bandinfo.bandname},{'theta','alpha1','alpha2','gamma1','gamma2'}));

bandinfo = bandinfo(bandrio);
bands = struct();

for bandi = 1 : length(bandinfo)
    curband = bandinfo(bandi);
    range =str2num(curband.range);
    rangecnt = 1;
    for rangei = {'low','high'}        
    bands.(curband.bandname).(rangei{1}) = range(rangecnt);
    rangecnt = rangecnt + 1;
    end
end 

thetaIdx = find(freqs > bands.theta.low & freqs < bands.theta.high );
alpha1Idx = find(freqs > bands.alpha1.low & freqs < bands.alpha1.high );
alpha2Idx = find(freqs > bands.alpha2.low & freqs < bands.alpha2.high );
gamma1Idx = find(freqs > bands.gamma1.low & freqs < bands.gamma1.high );
gamma2Idx = find(freqs > bands.gamma2.low & freqs < bands.gamma2.high );

%%
% Create atlas table
chanlist = cell2table({chanlocs.labels}', 'VariableNames', {'labelclean'});
atlasLookupTable = readtable("atlas_dk_networks_mni.csv");
matchedAtlasTable = innerjoin( chanlist, atlasLookupTable, 'Keys', {'labelclean','labelclean'});

networks = unique(matchedAtlasTable.RSN);
for i = 1 : numel(networks)
    netindex.(networks{i}) = find(strcmp(matchedAtlasTable.RSN,  networks{i}));
end

nodes = unique(matchedAtlasTable.labelclean);
for i = 1 : numel(nodes)
    nodeindex.(nodes{i}) = find(strcmp(matchedAtlasTable.labelclean,  nodes{i}));
end

AACTypes = {'Alpha1Gamma1', 'Alpha2Gamma1', 'ThetaGamma1'};

counter =1;
resTable = {};
for i = 1 : numel(resultArr1)

    powpow = resultArr1{i};
        % 100 x 100 x 68
    covmat = powpow.covMatrix;
    for chani = 1 : numel(chanlist)
        selectedChannel = chanlist{chani,1}{1};
        %networkIndex = netindex.(selectedNetwork);

     for ci = 1 : numel(AACTypes)
            selectedAAC = AACTypes{ci};
            switch selectedAAC
                case 'Alpha1Gamma1'
                    lowFreqIndex = alpha1Idx;
                    highFreqIndex = gamma1Idx;

                case 'Alpha2Gamma1'
                    lowFreqIndex = alpha2Idx;
                    highFreqIndex = gamma1Idx;

                case 'ThetaGamma1'
                    lowFreqIndex = thetaIdx;
                    highFreqIndex = gamma1Idx;
            end
     end

     selCovMatChannel = covmat(:,:, chani);
     selCovMatAAC = selCovMatChannel(lowFreqIndex, highFreqIndex, :);
     meanAAC = mean(mean(selCovMatAAC,1));

     resTable{counter, 1} = powpow.eegid;
     resTable{counter, 2} = selectedAAC;
     resTable{counter, 3} = selectedChannel;
     resTable{counter, 4} = meanAAC;

     fprintf("%d) Channel: %s\tType: %s AAC: %1.4d\n", counter, selectedChannel, ...
         selectedAAC, meanAAC);
     counter = counter + 1;

    end
end
resTableChannel = cell2table(resTable, 'VariableNames',{'eegid', 'AACType','Channel','value'});
%%

%networks = nodes;
%netindex = nodeindex;
%%
counter =1;
resTable = {};
for i = 1 : numel(resultArr1)

    powpow = resultArr1{i};


    % 100 x 100 x 68
    covmat = powpow.covMatrix;
    for neti = 1 : numel(networks)
        selectedNetwork = networks{neti};
        networkIndex = netindex.(selectedNetwork);

        for ci = 1 : numel(AACTypes)
            selectedAAC = AACTypes{ci};
            switch selectedAAC
                case 'Alpha1Gamma1'
                    lowFreqIndex = alpha1Idx;
                    highFreqIndex = gamma1Idx;

                case 'Alpha2Gamma1'
                    lowFreqIndex = alpha2Idx;
                    highFreqIndex = gamma1Idx;

                case 'ThetaGamma1'
                    lowFreqIndex = thetaIdx;
                    highFreqIndex = gamma1Idx;
            end

            selCovMatNetwork = covmat(:,:, networkIndex);
            selCovMatAAC = selCovMatNetwork(lowFreqIndex, highFreqIndex, :);
            meanNetAAC = mean(selCovMatAAC, 3);
            meanAAC = mean(mean(meanNetAAC));

            resTable{counter, 1} = powpow.eegid;
            resTable{counter, 2} = selectedAAC;
            resTable{counter, 3} = selectedNetwork;
            resTable{counter, 4} = meanAAC;

            fprintf("%d) RSN Network: %s\tType: %s AAC: %1.4d\n", counter, selectedNetwork, selectedAAC, meanAAC);
            counter = counter + 1;
        end

    end
end

resTableNetwork = cell2table(resTable, 'VariableNames',{'eegid', 'AACType','RSN','value'});

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    target_file_net_csv = strrep(target_file,'.mat', '_net.csv');
    target_file_chan_csv = strrep(target_file,'.mat', '_chan.csv');

    writetable(resTableNetwork, target_file_net_csv );
    writetable(resTableChannel, target_file_chan_csv );

    if useRelativePower
        target_file = strrep(target_file,".mat", "_relative.mat");
    else
        target_file = strrep(target_file,".mat", "_absolute.mat");
    end
     save(target_file, 'resultArr1', 'p', "-v7.3");
    fprintf("Success: Saved %s", target_file_csv);

catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end

%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %     
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
