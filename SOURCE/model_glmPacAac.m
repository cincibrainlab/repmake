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

basename    = 'glmPacAac'; % Edit
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

bandLabels = bandDefs(:,1);
bandIntervals = cell2mat(bandDefs(:,2:3));


% Main Subject by Subject Loop
totalsub = numel(p.sub);
resultArr1 = cell(totalsub,1);
resultArr2 = cell(totalsub,1);


glmAacAll = cell(length(p.sub),1);
glmPacAll = cell(length(p.sub),1);
sub = p.sub;
sub(1).loadDataset('signal');
cEEG = sub(1).EEG;
        % create full atlas table in chanlocs order
        chanlist = cell2table({cEEG.chanlocs.labels}', 'VariableNames', {'labelclean'});
        atlasLookupTable = readtable("atlas_dk_networks_mni.csv");
        matchedAtlasTable = innerjoin( chanlist, atlasLookupTable, 'Keys', {'labelclean','labelclean'});


parfor si = 1 :  totalsub

    % load EEG signal
    s = sub(si);
    s.loadDataset('signal');
    cEEG = s.EEG;

    if si == 1


%         networks = unique(matchedAtlasTable.RSN);
%         for i = 1 : numel(networks)
%             netindex.(networks{i}) = strcmp(matchedAtlasTable.RSN,  networks{i});
%         end
% 
%         nodes = unique(matchedAtlasTable.labelclean);
%         for i = 1 : numel(nodes)
%             nodeindex.(nodes{i}) = find(strcmp(matchedAtlasTable.labelclean,  nodes{i}));
%         end
    end

    glmaac=[]; count = 0;
    loBandArr = {'theta','alpha1','alpha2'};
    hiBandArr = {'gamma1'};

    cEEG = pop_select(cEEG, 'channel', find(~(matchedAtlasTable.RSN == "other")));

    loBandArr = {'theta','alpha1','alpha2'};
    hiBandArr = {'gamma1'};

    [glmResults] = fx_glmPacAac( si, loBandArr, hiBandArr, bandDefs, cEEG);


    glmAacAll{si} = glmResults;
    % glmPacAll{si} = glmpac;

    s.unloadDataset;
    EEG = [];
    cEEG = [];


end
% 
% 
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
% 
% sub = p.sub;
% parfor si = 1 :  totalsub
% 
%     % load EEG signal
%     s = sub(si);
%     s.loadDataset('signal');
%     cEEG = s.EEG;
%     EEG = s.EEG;
% 
%     % get channel structure
%     chanlocs = cEEG.chanlocs;
% 
%     % Remove the "other" nodes
%     % chanlocs(~(matchedAtlasTable.RSN == "other"))
%     cEEG = pop_select(cEEG, 'channel', find(~(matchedAtlasTable.RSN == "other")));
% 
%     loBandArr = {'theta','alpha1','alpha2'};
%     hiBandArr = {'gamma1'};
% 
%     [glmaac, glmpac] = fx_glmPacAac( loBandArr, hiBandArr, bandDefs, cEEG);
% 
% 
%     glmAacAll{si} = glmaac;
%     glmPacAll{si} = glmpac;
% 
%     s.unloadDataset;
%     EEG = [];
%     cEEG = [];
% 
% end
% 
% % c1 = globalnode;
% % c2 = bandpower.(bandDefs2{ui,1});
% % plot(log(c1(:,1)),log(c2(:,1)),'o')
% % corr(log(c1(:,1)),log(c2(:,1)))
% 
% 
% aacCsv = [];
% count = 1;
% for i = 1 : numel(p.sub)
%     s = p.sub(i);
% 
%     aacStruct = aacAll{i};
%     aacLabels = fieldnames(aacStruct);
%     for ai = 1 : numel(aacLabels)
% 
%         aacValues = aacStruct.(aacLabels{ai});
% 
%         for vi = 1 : numel(aacValues)
%             aacSplitLabel = strsplit(aacLabels{ai},'_');
% 
%             aacCsv{count, 1} = s.subj_basename;
%             aacCsv{count, 2} = aacSplitLabel{1};
%             aacCsv{count, 3} = aacSplitLabel{2};
%             aacCsv{count, 4} = aacSplitLabel{4};
%             aacCsv{count, 5} = chanlocs(vi).labels;
%             aacCsv{count, 6} = aacValues(vi);
%             count = count + 1;
%         end
%     end
% 
% end
% 
% resTableNode = cell2table(aacCsv, 'VariableNames',{'eegid','powertype','lowerband','upperband','label','value'});

%=========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    % target_file_net_csv = strrep(target_file,'.mat', '_net.csv');
    target_file_node_csv = strrep(target_file,'.mat', '_44node.csv');

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
