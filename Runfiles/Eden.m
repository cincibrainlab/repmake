%% RUNFILE
%  Project: B4 Preterm
%  Data: 2/13/2022
%  Obtain analysis scripts from www.github.com/cincibrainlab/vhtp

% % Analysis Parameters
%  Paradigm Template
%  indir: input directory of files to analyze (user)
%  outdir: directory to store any outputs (user)
%  fl: filelist (generated)
%  res: results table (generated)

%% Input and Output Base Directories
outdir.rest  = '/srv/BIGBUILD/Proj_Eden';
indir.rest   = '/srv/RAWDATA/Grace_Projects/Proj_Eden';

% Paradigm #1: Resting EEG (Rest)
fl.rest      = util_htpDirListing(indir.rest,'ext','.set', 'subdirOn', false);

% Create output filenames
csv.basename = fullfile(outdir.rest, 'EDEN.csv');

csv.fl.rest = strrep(csv.basename,'.csv','_filelist_rest.csv');

csv.pow_rel = strrep(csv.basename,'.csv','_pow_rel.csv');
csv.pow_lap = strrep(csv.basename,'.csv','_pow_lap.csv');
csv.pow_mne = strrep(csv.basename,'.csv','_pow_mne.csv');
csv.aac_rel = strrep(csv.basename,'.csv','_aac_rel.csv');
csv.aac_lap = strrep(csv.basename,'.csv','_aac_lap.csv');
csv.aac_mne = strrep(csv.basename,'.csv','_aac_mne.csv');

csv.pli_mne = strrep(csv.basename,'.csv','_pli_mne.csv');

writetable(fl.rest, csv.fl.rest);



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
runHab              = @( EEG ) eeg_htpCalcHabErp( EEG );
runPli              = @( EEG ) eeg_htpCalcPhaseLagFrontalTemporal( EEG );


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

%% DWPLI
[~, res.pli.mne] = runEegFun(loadSourceEeg2, runPli, getFiles(fl.rest), getPaths(fl.rest));
createResultsCsv( summary2table( res.pli.mne ), csv.pli_mne );

%% Analysis Chirp
[EEGcell_Chirp, res.chirp] = runEegFun(loadEeg, runChirp, getFiles(fl.chirp), getPaths(fl.chirp));
createResultsCsv( summary2table( res.chirp ), csv.chirp );
 
%% Analysis Hab
[EEGcell_Hab, res.hab] = runEegFun(loadEeg, runHab, getFiles(fl.hab), getPaths(fl.hab));
createResultsCsv( summary2table( res.hab ), csv.hab );

eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', ...
    true, 'singleplot', true);
eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', ...
    true, 'singleplot', true, 'groupids', testGroups)
eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', false, 'singleplot', false)

% Grand Average ERP
eeg_htpVisualizeHabErp(EEGcell_Hab, 'groupmean', true)
eeg_htpVisualizeHabErp(EEGcell_Hab, 'groupmean', false, 'singleplot', false);








