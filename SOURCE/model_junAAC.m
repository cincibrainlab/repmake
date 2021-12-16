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

basename    = 'junAAC'; % Edit
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

% Main Subject by Subject Loop
totalsub = numel(p.sub);
resultArr1 = cell(totalsub,1);
resultArr2 = cell(totalsub,1);

sub = p.sub;
for si = 1 :  totalsub

    % load EEG signal
    s = sub(si);
    s.loadDataset('signal');
    cEEG = s.EEG;
    EEG = s.EEG;

    % check if data is continuous, if not epoch to 1 s bins
    if ndims(EEG.data)
        warning("Data is continuous. Converted to 1 second epochs.")
        EEG = eeg_regepochs(EEG, 'recurrence', 1);
    end

    EEG.data = gpuArray(EEG.data);

    %
    %     % calculate power
    %     s.setFreqTable([2,3.5;4,7.5;8,10;10.5,12.5;13,30;30,55;65,89.5;90,140]); % 8-band 08/28
    %     s.getPntsTable;
    %     s.EEG = eeg_regepochs(s.EEG, 'recurrence', 2);
    %     s.generateStoreRoom;
    %     s.rest_rel_power

    % get channel structure
    chanlocs = EEG.chanlocs;

    % create full atlas table in chanlocs order
    chanlist = cell2table({chanlocs.labels}', 'VariableNames', {'labelclean'});
    atlasLookupTable = readtable("atlas_dk_networks_mni.csv");
    matchedAtlasTable = innerjoin( chanlist, atlasLookupTable, 'Keys', {'labelclean','labelclean'});

    networks = unique(matchedAtlasTable.RSN);
    for i = 1 : numel(networks)
        netindex.(networks{i}) = strcmp(matchedAtlasTable.RSN,  networks{i});
    end

    nodes = unique(matchedAtlasTable.labelclean);
    for i = 1 : numel(nodes)
        nodeindex.(nodes{i}) = find(strcmp(matchedAtlasTable.labelclean,  nodes{i}));
    end

    % Remove the "other" nodes
    % chanlocs(~(matchedAtlasTable.RSN == "other"))
    % cEEG = pop_select(cEEG, 'channel', find(~(matchedAtlasTable.RSN == "other")));
    % EEG = pop_select(EEG, 'channel', find(~(matchedAtlasTable.RSN == "other")));
    chanlocs = EEG.chanlocs;

    % alternative power calculation
    upperFreqLimit = 90;
    deviationFromLog = 5;
    PSD = [];

    %PSD = zeros(length(freqBins), size(EEG.data,2), length(chanlocs))
    freqBins = logspace(log10(1+deviationFromLog), log10(upperFreqLimit+deviationFromLog), 281)-deviationFromLog;
    PSDType = {'absolute','relative'}; PSDArray = [];
    for pi = 1 : numel(PSDType)
        for i = 1 : size(EEG.data,1)
            [~, freqs, times, firstPSD] = spectrogram(EEG.data(i,:), EEG.srate, floor(EEG.srate/2), freqBins, EEG.srate);
            %freqs =  s.rest_rel_hz;
            % hz x trial x chan
            switch PSDType{pi}
                case 'absolute'
                    PSDArray.(PSDType{pi})(:,:,i) = firstPSD; %#ok<*SAGROW> % 100 (hz pnts) x 161 (trials) x 68
                case 'relative'
                    PSDArray.(PSDType{pi})(:,:,i) = firstPSD ./ sum(firstPSD,1); % Relative Power
            end
        end
    end
    firstPSD2 = squeeze(s.rest_rel_power);
    %%

    glmaac=[]; count = 0;
    loBandArr = {'theta','alpha1','alpha2'};
    hiBandArr = {'gamma1'};

    % create band indexes and global cluster for correlation
    bandname = []; bandindex =[]; bandpower =[]; cluster =[];
    for pi = 1 : numel(PSDType)

        PSD = gather(PSDArray.(PSDType{pi}));

        for bandi = 1 : length(bandDefs)
            bandname =[ PSDType{pi} '_' bandDefs{bandi,1}];

            bandindex.(bandname) = freqs > bandDefs{bandi,2} & freqs < bandDefs{bandi,3};
            bandpower.(bandname) = squeeze(mean(PSD(bandindex.(bandname),:,:),1));
            cluster_indices = 1 : numel(chanlocs);  % replace with any channel index, i.e. network indexes
            cluster.(bandname) =  squeeze(mean(bandpower.(bandname)(:,cluster_indices),2));
        end

    end

    % compute global to local AAC
    globalaac = @(globalPower, localNodePower) corr(globalPower, localNodePower, 'Type', 'Spearman');
    bandDefs2 = fieldnames(cluster); aac = []; PSD = [];
    for pi = 1 : numel(PSDType)
        PSD = PSDArray.(PSDType{pi});
        for bandi = 1 : length(bandDefs2)
            % bandname = bandDefs{bandi,1};
            bandname = bandDefs2{bandi};
            bandSplitName = strsplit(bandname, "_");
            lowerPowerType = bandSplitName{1};

            if contains(bandname, {'theta','alpha1','alpha2'}) % low to high frequency
                lowerband = bandname;

                globalnode = repmat(cluster.(lowerband), [1 size(bandpower.(lowerband),2)]);
                localnodes = bandpower.(bandname);

                % upperbands = {'absolute_gamma1','absolute_gamma2','absolute_epsilon'};
                for ui = 1 : length(bandDefs2)
                    upperband = bandDefs2{ui,1};
                    bandSplitName = strsplit(upperband, "_");
                    upperPowerType = bandSplitName{1};
                    if strcmp(lowerPowerType, upperPowerType)
                        if contains(upperband, {'gamma1','gamma2','epsilon'})
                            % aac for just upper bands with lower bands
                            label = sprintf("%s_%s", lowerband, bandDefs2{ui,1});
                            aac.(label) = globalaac(globalnode, bandpower.(bandDefs2{ui,1}));
                        end
                    end
                end
            end
        end
    end

    for i = 1 : numel(fieldnames(aac))
        label = fieldnames(aac);
        aac.(label{i}) = aac.(label{i})(1,:);
    end

    aacAll{si} = aac;

    s.unloadDataset;
    EEG = [];
end

% c1 = globalnode;
% c2 = bandpower.(bandDefs2{ui,1});
% plot(log(c1(:,1)),log(c2(:,1)),'o')
% corr(log(c1(:,1)),log(c2(:,1)))


aacCsv = [];
count = 1;
for i = 1 : numel(p.sub)
    s = p.sub(i);

    aacStruct = aacAll{i};
    aacLabels = fieldnames(aacStruct);
    for ai = 1 : numel(aacLabels)

        aacValues = aacStruct.(aacLabels{ai});

        for vi = 1 : numel(aacValues)
            aacSplitLabel = strsplit(aacLabels{ai},'_');

            aacCsv{count, 1} = s.subj_basename;
            aacCsv{count, 2} = aacSplitLabel{1};
            aacCsv{count, 3} = aacSplitLabel{2};
            aacCsv{count, 4} = aacSplitLabel{4};
            aacCsv{count, 5} = chanlocs(vi).labels;
            aacCsv{count, 6} = aacValues(vi);
            count = count + 1;
        end
    end

end

resTableNode = cell2table(aacCsv, 'VariableNames',{'eegid','powertype','lowerband','upperband','label','value'});

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
