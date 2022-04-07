%% RUNFILE
%  Project: Stalicla
%  Data: 2/13/2022
%  Obtain analysis scripts from www.github.com/cincibrainlab/vhtp

% % Analysis Parameters
%  Paradigm Template
%  indir: input directory of files to analyze (user)
%  outdir: directory to store any outputs (user)
%  fl: filelist (generated)
%  res: results table (generated)

%% Input and Output Base Directories
outdir.rest  = '/srv/BIGBUILD/Proj_Stalicla/';
indir.rest   = '/srv/onedrive/DTA_Stalicla/Rest/';
indir.chirp  = '/srv/onedrive/DTA_Stalicla/Chirp';
indir.hab    = '/srv/onedrive/DTA_Stalicla/Hab/';

% Paradigm #1: Resting EEG (Rest)
fl.rest      = util_htpDirListing(indir.rest,'ext','.set', 'subdirOn', false);
% Paradigm #2: Resting EEG (Rest)
fl.chirp      = util_htpDirListing(indir.chirp,'ext','.set', 'subdirOn', false);
% Paradigm #3: Resting EEG (Rest)
fl.hab      = util_htpDirListing(indir.hab,'ext','.set', 'subdirOn', false);

% Create output filenames
csv.basename = fullfile(outdir.rest, 'stalicla.csv');

csv.fl.rest = strrep(csv.basename,'.csv','_filelist_rest.csv');
csv.fl.chirp = strrep(csv.basename,'.csv','_filelist_chirp.csv');
csv.fl.hab = strrep(csv.basename,'.csv','_filelist_hab.csv');

csv.pow_rel = strrep(csv.basename,'.csv','_pow_rel.csv');
csv.pow_lap = strrep(csv.basename,'.csv','_pow_lap.csv');
csv.pow_mne = strrep(csv.basename,'.csv','_pow_mne.csv');
csv.aac_rel = strrep(csv.basename,'.csv','_aac_rel.csv');
csv.aac_lap = strrep(csv.basename,'.csv','_aac_lap.csv');
csv.aac_mne = strrep(csv.basename,'.csv','_aac_mne.csv');

csv.chirp   = strrep(csv.basename,'.csv','_chirp.csv');
csv.hab     = strrep(csv.basename,'.csv','_hab.csv');

writetable(fl.rest, csv.fl.rest);
writetable(fl.chirp, csv.fl.chirp);
writetable(fl.hab, csv.fl.hab);


% Summary functions

% File management functions
getFiles            = @( filelist_table ) filelist_table{:, 2};
getPaths            = @( filelist_table ) filelist_table{:, 1};

% load EEG functions
loadEeg             = @( filename, filepath ) pop_loadset(filename, filepath);
loadLaplacianEeg    = @( filename, filepath ) eeg_htpCalcLaplacian( loadEeg( filename, filepath ) );
loadSourceEeg       = @( filename, filepath ) eeg_htpCalcSource( loadEeg( filename, filepath ) );
loadSourceEeg2       = @( filename, filepath ) eeg_htpCalcSource( loadEeg( filename, filepath ), 'usepreexisting', true );

% calculate functions
runEegFun       = @( EegLoad, EegCalc, files, paths ) cellfun(@(fn,fl) EegCalc(EegLoad(fn, fl)), files, paths);

% summary functions
runRest             = @( EEG ) eeg_htpCalcRestPower( EEG , 'gpuOn', true);
runAac              = @( EEG ) eeg_htpCalcAacGlobal( EEG , 'gpuOn', true);
runAacSource        = @( EEG ) eeg_htpCalcAacGlobal( EEG , 'sourcemode', true, 'gpuOn', true);
runChirp            = @( EEG ) eeg_htpCalcChirpItcErsp( EEG );
runHab            = @( EEG ) eeg_htpCalcHabErp( EEG );

% reporting function
summary2table = @( result_struct )  vertcat(result_struct(:).summary_table);
createResultsCsv = @(result_table, csvfile) writetable(vertcat(result_table), csvfile);

%%  Spectral Power
res.rest.pow      = table();
[~, res.rest.pow] = runEegFun(loadEeg, runRest, getFiles(fl.rest), getPaths(fl.rest));
createResultsCsv( summary2table( res.rest.pow ), csv.pow_rel );

res.rest.lap      = table();
[~, res.rest.lap  ] = runEegFun(loadLaplacianEeg, runRest, getFiles(fl.rest), getPaths(fl.rest));
createResultsCsv( summary2table( res.rest.lap ), csv.pow_lap );

res.rest.source      = table();
[~, res.rest.source  ] = runEegFun(loadSourceEeg2, runRest, getFiles(fl.rest), getPaths(fl.rest));
createResultsCsv( summary2table( res.rest.source ), csv.pow_mne );

%% AAC
[~, res.aac.pow] = runEegFun(loadEeg, runAac, getFiles(fl.rest), getPaths(fl.rest));
createResultsCsv( summary2table( res.aac.pow ), csv.aac_rel );

[~, res.aac.lap] = runEegFun(loadLaplacianEeg, runAac, getFiles(fl.rest), getPaths(fl.rest));
createResultsCsv( summary2table( res.aac.lap ), csv.aac_lap );

[~, res.aac.mne] = runEegFun(loadSourceEeg2, runAacSource, getFiles(fl.rest), getPaths(fl.rest));
createResultsCsv( summary2table( res.aac.mne ), csv.aac_mne );

%% Analysis Chirp
[EEGcell_Chirp, res.chirp] = runEegFun(loadEeg, runChirp, getFiles(fl.chirp), getPaths(fl.chirp));
createResultsCsv( summary2table( res.chirp ), csv.chirp );

writetable(cell2table({EEGcell_Chirp.subject}'), "/srv/BIGBUILD/Proj_Stalicla/image_order.csv");
chirpIds = readtable("/srv/BIGBUILD/Proj_Stalicla/chirp_assignments.csv");

eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', ...
    true, 'singleplot', true, 'groupids', chirpIds{:,3})

 
%% Analysis Hab
[EEGcell_Hab_ts, res.hab] = runEegFun(loadEeg, runHab, getFiles(fl.hab), getPaths(fl.hab));
createResultsCsv( summary2table( res.hab ), csv.hab );

writetable(cell2table({EEGcell_Hab.subject}'), "/srv/BIGBUILD/Proj_Stalicla/image_order_hab.csv");
habIds = readtable("/srv/BIGBUILD/Proj_Stalicla/hab_assignments.csv");

%%
eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', ...
    false, 'singleplot', true);
eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', ...
    true, 'singleplot', true, 'groupids', testGroups)
eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', false, 'singleplot', false)

% Grand Average ERP
BASELINE = 1;
ACUTE_HIGH = 5;
ACUTE_PLACEBO = 2;

eeg_htpVisualizeHabErp(EEGcell_Hab_ts, 'groupmean', false, 'singleplot', false)
eeg_htpVisualizeHabErp(EEGcell_Hab, 'groupmean', true, 'singleplot', true,...
    'groupids', habIds{:,6}, ...
    'groupOverlay', [BASELINE,ACUTE_PLACEBO,ACUTE_HIGH], ...
    'drugNames', {'High Dose','Placebo', 'Baseline'}, ...
    'plotstyle','tetra', 'outputdir','/srv/BIGBUILD/Proj_Stalicla/');

eeg_htpVisualizeHabErp(EEGcell_Hab, 'groupmean', true, 'singleplot', true,...
    'groupids', habIds{:,6}, 'groupOverlay', [1,3,7], 'plotstyle','tetra', 'outputdir','/srv/BIGBUILD/Proj_Stalicla/');

eeg_htpVisualizeHabErp(EEGcell_Hab, 'groupmean', true, 'singleplot', true,...
    'groupids', habIds{:,6}, 'groupOverlay', [2,4,5], 'plotstyle','tetra', 'outputdir','/srv/BIGBUILD/Proj_Stalicla/');

% 
% mutate(groupnum2 = ifelse(str_detect(group2, "ACUTE_Placebo"), 2, 0),
%                        groupnum2 = ifelse(str_detect(group2, "CHRONIC_Placebo"), 3, groupnum2),
%                        groupnum2 = ifelse(str_detect(group2, "ACUTE_Low"), 4, groupnum2),
%                        groupnum2 = ifelse(str_detect(group2, "ACUTE_High"), 5, groupnum2),
%                        groupnum2 = ifelse(str_detect(group2, "CHRONIC_Low"), 6, groupnum2),
%                        groupnum2 = ifelse(str_detect(group2, "CHRONIC_High"), 7, groupnum2),
%                        groupnum2 = ifelse(str_detect(group2, "FOLLOWUP"), 8, groupnum2),
%                        groupnum2 = ifelse(str_detect(group2, "BASELINE"), 1, groupnum2)) 








