g

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








