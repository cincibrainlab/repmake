%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make         %
%=========================================================================%
% FIGURE SCRIPT    =======================================================%
%                  Creates visualization from MATLAB Data                 %
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

basename    = 'pmtmMneAAC'; % Edit
prefix      = ['figure_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_pmtmMneAAC_cfc.mat'; % any MAT/Parquet inputs (or NA)

if ~ismissing(data_file)
    load(fullfile(syspath.BigBuild, data_file))
end

%=========================================================================%
% Step 4: Specify target for interactive Matlab (no modification needed)  %
%=========================================================================%

output_file_extension = 'PNG'; % CSV, DOCX, MAT

if IsBatchMode, target_file = target_file; else
    target_file = r.outFile(prefix, syspath.BigBuild, output_file_extension);
end

%=========================================================================%
%                           CONSTRUCT FIGURE                              %
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
[~,project_name,~] = fileparts(syspath.htpdata);                          %
ProtocolName          = project_name; % set protocol name                 %
fx_getBrainstormVars;  % brainstorm include                               %
%                     script will end if wrong protocol                   %
brainstorm; % need graphics mode to set FDR
%=========================================================================%

%=========================================================================%
%  Specify Power Type    Spectral power is calculated via BST Welsch
%                        function. Code for analysis is carried through
%                        analysis making it easier to search for.
%  Available Codes:      scalpAbsPow755   Absolute Power
%                        scalpRelPow765   Relative Power
%                        scalpAbsFFT775   Absolute Power continuous
%                        scalpRelFFT785   Relative Power continuous
%=========================================================================%



%=========================================================================%
% AAC              =======================================================%
% PLOTS            Use function to create custom snapshots of             %
%                  statistical results. Colorbar can be made uniform.     %
%=========================================================================%
% Create atlas table
chanlist = cell2table(chans', 'VariableNames', {'labelclean'});
atlasLookupTable = readtable("atlas_dk_networks_mni.csv");
matchedAtlasTable = innerjoin( chanlist, atlasLookupTable, 'Keys', {'labelclean','labelclean'});

networks = unique(matchedAtlasTable.RSN);
for i = 1 : numel(networks)
    netindex.(networks{i}) = find(strcmp(matchedAtlasTable.RSN,  networks{i}));
end

resultArr1 = cfc;

% Create output table for R
freqs = freqbands;

bands.theta.low = 4.5;
bands.theta.high = 7.5;
bands.alpha1.low = 8;
bands.alpha1.high = 10;
bands.alpha2.low = 10;
bands.alpha2.high = 12.5;

bands.gamma1.low = 30;
bands.gamma1.high = 55;
bands.gamma2.low = 65;
bands.gamma2.high = 90;

thetaIdx = find(freqs > bands.theta.low & freqs < bands.theta.high );
alpha1Idx = find(freqs > bands.alpha1.low & freqs < bands.alpha1.high );
alpha2Idx = find(freqs > bands.alpha2.low & freqs < bands.alpha2.high );
gamma1Idx = find(freqs > bands.gamma1.low & freqs < bands.gamma1.high );
gamma2Idx = find(freqs > bands.gamma2.low & freqs < bands.gamma2.high );


% Create atlas table
chanlist = cell2table(chans', 'VariableNames', {'labelclean'});
atlasLookupTable = readtable("atlas_dk_networks_mni.csv");
matchedAtlasTable = innerjoin( chanlist, atlasLookupTable, 'Keys', {'labelclean','labelclean'});

networks = unique(matchedAtlasTable.RSN);
for i = 1 : numel(networks)
    netindex.(networks{i}) = find(strcmp(matchedAtlasTable.RSN,  networks{i}));
end

AACTypes = {'Alpha1Gamma1', 'Alpha2Gamma1', 'ThetaGamma1'};


counter =1;
resTable = {};
for i = 1 : numel(cfc)

    covmat = cfc{i};


    % 100 x 100 x 68
    %covmat = powpow.covMatrix;
    for neti = 1 : numel(networks)
        selectedNetwork = networks{neti};
        networkIndex = netindex.(selectedNetwork);

        for ci = 1 : numel(AACTypes)
            selectedAAC = AACTypes{ci};
            switch selectedAAC
                case 'Alpha1Gamma1'
                    lowFreqIndex = gamma1Idx;
                    highFreqIndex = alpha1Idx;

                case 'Alpha2Gamma1'
                    lowFreqIndex = gamma1Idx;
                    highFreqIndex = alpha2Idx;

                case 'ThetaGamma1'
                    lowFreqIndex = gamma1Idx;
                    highFreqIndex = thetaIdx;
            end

            selCovMatNetwork = covmat(:,:, networkIndex);
            selCovMatAAC = selCovMatNetwork(lowFreqIndex, highFreqIndex, :);
            meanNetAAC = mean(selCovMatAAC, 3);
            meanAAC = mean(mean(meanNetAAC));

            resTable{counter, 1} = p.sub(i).subj_basename;
            resTable{counter, 2} = selectedAAC;
            resTable{counter, 3} = selectedNetwork;
            resTable{counter, 4} = meanAAC;

            fprintf("%d) RSN Network: %s\tType: %s AAC: %1.4d\n", counter, selectedNetwork, selectedAAC, meanAAC);
            counter = counter + 1;
        end

    end
end

resTable = cell2table(resTable, 'VariableNames',{'eegid', 'AACType','RSN','value'});

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    target_file_csv = strrep(target_file,'.mat', '.csv');
    writetable(resTable, target_file_csv )
    % save(target_file, 'subnames', 'freqbands', 'chans', 'cfc', 'psd',"-v7.3")
    %save(strrep(target_file,'.mat', '_cfc.mat'), 'subnames', 'freqbands', 'chans', 'cfc',"-v6")
    %save(strrep(target_file,'.mat', '_psd.mat'), 'subnames', 'freqbands', 'chans', 'psd',"-v6")

    fprintf("Success: Saved %s", target_file_csv);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end


% Can modify subject names if needed to match table in this function
subjectList = fx_customSubjectListClean(subnames, project_name);

% match table to join groups (fieldnames will be used as needed based
% on listComps in runfile.
matchedSubjectTable = innerjoin( subjectList, groupLookupTable, 'Keys', {'eegid','eegid'});
% Generate components with accurate
allComps = fx_codeGroupComparisons(listComps, matchedSubjectTable  );
%%
for compi = 1 : size(allComps,1)
    % get subject Ids
    selectComparisonTitle   = allComps{compi,1};
    selectComparisonIdx     = allComps{compi,2};
    selectComparisonGroupNames = allComps{compi,3};
    for neti = 1 : numel(networks)
        currentNetwork  = networks{neti};
        currentNetIndex = netindex.(currentNetwork);
        target_file2 = strrep(target_file, '.png', ['_' selectComparisonTitle '_' networks{neti} '.png']);
        fprintf("%s (%s): %s\n", selectComparisonTitle, currentNetwork, target_file2);

        % check to make sure comparision vector isn't empty
        if ~(isempty(selectComparisonIdx{1}) || isempty(selectComparisonIdx{2}))
            
            cfcByNetwork = cellfun(@(x) mean(x(:,:,currentNetIndex),3), cfc, 'uni',0);
            cfcByNetworkMat = zeros(size(cfcByNetwork{1},1),...
                size(cfcByNetwork{1},2),...
                numel(cfcByNetwork));

            % Group 1
            groupA = cfcByNetworkMat(:,:,selectComparisonIdx{1});

            % Group 2
            groupB = cfcByNetworkMat(:,:, selectComparisonIdx{2});

        end
    end
end

%%

for compi = 1 : size(allComps,1)
    count = 0;

    % get subject Ids
    selectComparisonTitle = allComps{compi,1};
    selectComparisonIdx = allComps{compi,2};
    selectComparisonGroupNames = allComps{compi,3};

    for neti = 1 : numel(networks)
            figure;
        currentNetIndex = netindex.(networks{i});
        if ~(isempty(selectComparisonIdx{1}) || isempty(selectComparisonIdx{2}))

            matA = cfc(selectComparisonIdx{1});

            % averages across network nodes
            netA = cellfun(@(x) mean(x(:,:,currentNetIndex),3), matA, 'uni',0);
            matdA = zeros(size(netA{1},1),size(netA{1},2),numel(netA));

            for k = 1 : numel(netA)
                matdA(:,:,k) = netA{k};
            end

            count = 0;

            meanMatdA = mean(matdA,3);
            diagidx = eye(size(meanMatdA), 'logical');
            meanMatdA(diagidx) = mean(meanMatdA(~diagidx));

            count = count +1;
            subplot(1,2,1);
            imagesc(meanMatdA); axis square
            set(gca, 'YDir', 'normal');
            title(selectComparisonGroupNames{1})
            colorbar;
            matB = cfc(selectComparisonIdx{2});

            % averages across network nodes
            netB = cellfun(@(x) mean(x(:,:,currentNetIndex),3), matB, 'uni',0);

            matdB = zeros(size(netB{1},1),size(netB{1},2),numel(netB));

            for k = 1 : numel(netB)
                matdB(:,:,k) = netB{k};
            end

            meanMatdB = mean(matdB,3);
            diagidx = eye(size(meanMatdB), 'logical');
            meanMatdB(diagidx) = mean(meanMatdB(~diagidx));

            count = count +1;

            subplot(1, 2,2);
            imagesc(meanMatdB); axis square;
            set(gca, 'YDir', 'normal');
            title(selectComparisonGroupNames{2})
            sgtitle([selectComparisonTitle '_' networks{i}])
            colorbar;
            saveas(gcf, strrep(target_file, '.png', ['_' selectComparisonTitle '_' networks{i} '.png']))
            close gcf;
        end
    end
end
%%
%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    imwrite(exportImage.(powerType), strrep(target_file, 'figure_bstElecPowStats',['figure_bstElecPowStats_' selStatCurrent.Comment]));
    fprintf("Success: Saved %s", target_file);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end

brainstorm exit;
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
