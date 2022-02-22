%% RUNFILE
%  Project: Stalicla
%  Data: 2/6/2022

% % Analysis Parameters
%  Paradigm Template
%  indir: input directory of files to analyze (user)
%  outdir: directory to store any outputs (user)
%  fl: filelist (generated)
%  res: results table (generated)

%% Input and Output Base Directories
outdir.rest  = tempdir;
indir.rest   = '/srv/RAWDATA/Stalicla/Rest_EyesOpen/';
indir.chirp  = '/srv/RAWDATA/Stalicla/Chirp/';
indir.hab    = '/srv/RAWDATA/Stalicla/Hab/';

% Paradigm #1: Resting EEG (Rest)
fl.rest      = util_htpDirListing(indir.rest,'ext','.set', 'subdirOn', false);
% Paradigm #2: Resting EEG (Rest)
fl.chirp      = util_htpDirListing(indir.chirp,'ext','.set', 'subdirOn', false);
% Paradigm #3: Resting EEG (Rest)
fl.hab      = util_htpDirListing(indir.hab,'ext','.set', 'subdirOn', false);

csv.basename = fullfile(outdir.rest, 'stalicla.csv');
csv.pow_rel = strrep(csv.basename,'.csv','_pow_rel.csv');
csv.pow_lap = strrep(csv.basename,'.csv','_pow_lap.csv');
csv.pow_mne = strrep(csv.basename,'.csv','_pow_mne.csv');
csv.aac_rel = strrep(csv.basename,'.csv','_aac_rel.csv');
csv.aac_lap = strrep(csv.basename,'.csv','_aac_lap.csv');
csv.aac_mne = strrep(csv.basename,'.csv','_aac_mne.csv');

csv.chirp   = strrep(csv.basename,'.csv','_chirp.csv');
csv.hab     = strrep(csv.basename,'.csv','_hab.csv');


%%  Analysis #1a: Spectral Power
res.pow      = table();
runRest = @(filename, filepath) eeg_htpCalcRestPower(...
    pop_loadset(filename, filepath), 'gpuOn', true);
[~, pow_results] = cellfun(@(fn,fl) runRest(fn, fl), ...
    fl.rest{:, 2}, fl.rest{:, 1});
res.pow_rel = vertcat(pow_results(:).summary_table);
writetable(res.pow_rel, csv.pow_rel);
%%  Analysis #1b: Spectral Power (Laplacian)
res.pow      = table(); pow_results = [];
runRest = @(filename, filepath) eeg_htpCalcRestPower(...
    eeg_htpCalcLaplacian(pop_loadset(filename, filepath)), ...
    'gpuOn', 1);
[~, pow_results] = cellfun(@(fn,fl) runRest(fn, fl), ...
    fl.rest{:, 2}, fl.rest{:, 1});
res.pow_lap = vertcat(pow_results(:).summary_table);
writetable(res.pow_lap, csv.pow_lap);
%%  Analysis #1c: Spectral Power (MNE)
% brainstorm;
res.pow      = table(); pow_results = [];
runRest = @(filename, filepath) eeg_htpCalcRestPower(...
    eeg_htpCalcSource(pop_loadset(filename, filepath)), ...
    'gpuOn', 1);
[~, pow_results] = cellfun(@(fn,fl) runRest(fn, fl), ...
    fl.rest{:, 2}, fl.rest{:, 1});
res.pow_mne = vertcat(pow_results(:).summary_table);
writetable(res.pow_mne, csv.pow_mne);

%%  Analysis #2a: Amplitude Amplitude Coupling
res.aac      = table(); aac_results = [];
runAac = @(filename, filepath) eeg_htpCalcAacGlobal(...
    pop_loadset(filename, filepath), 'gpuon', true);
[~, aac_results] = cellfun(@(fn,fl) runAac(fn, fl), ...
    fl.rest{:, 2}, fl.rest{:, 1});
res.aac_rel = vertcat(aac_results(:).summary_table);
writetable(res.aac_rel, csv.aac_rel);

%%  Analysis #2b: Amplitude Amplitude Coupling (Laplacian)
res.aac      = table(); aac_results = [];
runAac = @(filename, filepath) eeg_htpCalcAacGlobal(...
    eeg_htpCalcLaplacian(pop_loadset(filename, filepath)), 'gpuon', true);
[~, aac_results] = cellfun(@(fn,fl) runAac(fn, fl), ...
    fl.rest{:, 2}, fl.rest{:, 1});
res.aac_lap = vertcat(aac_results(:).summary_table);
writetable(res.aac_lap, csv.aac_lap);

%%  Analysis #2c: Amplitude Amplitude Coupling (MNE)
res.aac      = table(); aac_results = [];
runAac = @(filename, filepath) eeg_htpCalcAacGlobal(...
    eeg_htpCalcSource(pop_loadset(filename, filepath)), 'gpuon', true, ...
    'sourcemode', true);
[~, aac_results] = cellfun(@(fn,fl) runAac(fn, fl), ...
    fl.rest{:, 2}, fl.rest{:, 1});
res.aac_mne = vertcat(aac_results(:).summary_table);
writetable(res.aac_mne, csv.pow_mne);

%% Analysis #4: Chirp
res.chirp      = table(); chirp_results = [];
runChirp = @(filename, filepath) eeg_htpCalcChirpItcErsp(...
    pop_loadset(filename, filepath));
[EEGStruct_Chirp, chirp_res] = cellfun(@(fn,fl) runChirp(fn, fl), ...
    fl.chirp{:, 2}, fl.chirp{:, 1});
res.chirp = vertcat(chirp_res(:).summary_table);
writetable(res.chirp, csv.chirp);

EEGcell_Chirp = {};
for i = 1 : numel(EEGStruct_Chirp)
    EEGcell_Chirp{i} = EEGStruct_Chirp(i);
end

eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', ...
    true, 'singleplot', true)
eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', ...
    true, 'singleplot', true, 'groupids', testGroups)
eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', false, 'singleplot', false)


%%  Analysis #3: Debiased Weighted Phase Lag Index
res.dwpli    = table();
%  Analysis #4: Laplacian CSD Spectral Power
res.lap      = table();
%  Analysis #5: Source MNE CSD Spectral Power
res.lap      = table();

%  Paradigm #2: Sensory Auditory Chirp (Chirp)
indir.chirp   = '/srv/RAWDATA/Stalicla/Chirp/';
outdir.chirp  = tempdir;
fl.chirp      = util_htpDirListing(indir.chirp,'ext','.set');

%  Analysis #6: Intratrial Coherence, Event Related Spectral Perturbation,
%  Onset and Offset event related potentials 
res.chirp      = table();

%  Paradigm #3: Sensory Auditory Habituation (Hab)
indir.hab   = '/srv/RAWDATA/Stalicla/Hab/';
outdir.hab  = tempdir;
fl.hab      = util_htpDirListing(indir.hab,'ext','.set');

%  Analysis #7: N1 and P2 Amplitudes
res.hab      = table();

%% Run Analysis


%% Resting Power Analysis
outputdir = tempdir;
datadir = '/srv/RAWDATA/Stalicla/Rest_EyesOpen/';

filelist_rest = util_htpDirListing(datadir,'ext','.set');

res.power = table();

for fi = 1 : height(filelist)

    EEG = pop_loadset(filelist_rest{fi, 2}{1}, filelist_rest{fi,1}{1});
    
    [~, pow_results] = eeg_htpCalcRestPower(EEG, 'gpuOn', 1);

    if fi == 1
        res.power = pow_results.summary_table;
    else
        res.power = [res.power; pow_results.summary_table];
    end

end

writetable(res.power, fullfile(outputdir, 'stalicla_res_power.csv'));


%% Chirp Analysis

res.chirp = table();

datadir = '/srv/RAWDATA/Stalicla/Chirp/';
EEGcell_Chirp = {};
filelist = utility_htpDirectoryListing(datadir,'ext','.set');

for fi = 1 : height(filelist)

    EEG = pop_loadset(filelist{fi, 2}{1}, filelist{fi,1}{1});
    
    [EEGcell_Chirp{fi}, chirp_results] = eeg_htpCalcChirpItcErsp(EEG);

    if fi == 1
        res.chirp = chirp_results.summary_table;
    else
        res.chirp = [res.chirp; chirp_results.summary_table];
    end

end

writetable(res.chirp, fullfile(outputdir, 'stalicla_res_chirp.csv'));

testGroups = double(randi([1 3],1,numel(EEGcell_Chirp),'uint8'));
eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', ...
    true, 'singleplot', true)
eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', ...
    true, 'singleplot', true, 'groupids', testGroups)
eeg_htpVisualizeChirpItcErsp(EEGcell_Chirp, 'groupmean', false, 'singleplot', false)


%% Habituation analysos

res.hab = table();
outputdir = tempdir;
EEGcell_Hab = {};
res.hab = [];
datadir = '/srv/RAWDATA/Stalicla/Hab/';

filelist_hab = util_htpDirListing(datadir,'ext','.set');
filelist = filelist_hab;
for fi = 1 : height(filelist)

    eegfile = fullfile(filelist{fi, 1}, filelist{fi,2});
    
    EEG = pop_loadset(filelist_hab{fi,2}{1}, filelist_hab{fi, 1}{1});
    
    [EEGcell_Hab{fi}, hab_results] = eeg_htpCalcHabErp(EEG, 'plotsOn',0);

    % erp(fi,:) = hab_results.erp;

    if fi == 1
        res.hab = hab_results.summary_table;
    else
        res.hab = [res.hab; hab_results.summary_table];
    end

end

writetable(res.hab, fullfile(outputdir, 'stalicla_res_hab.csv'));

% Grand Average ERP
eeg_htpVisualizeHabErp(EEGcell_Hab, 'groupmean', true)

eeg_htpVisualizeHabErp(EEGcell_Hab, 'groupmean', false, 'singleplot', false);


%% Source modeling

download_headmodel = ...
 'http://www.dropbox.com/s/0m8oqrnlzodfj2n/headmodel_surf_openmeeg.mat?dl=1';

datadir = '/srv/RAWDATA/Stalicla/Rest_EyesOpen';

filelist = utility_htpDirectoryListing(datadir,'ext','.set');

res.power = table();

for fi = 1 : height(filelist)

    eegfile = fullfile(filelist{fi, 1}, filelist{fi,2});
    
    EEG = pop_loadset(eegfile);
    
    [EEG] = eeg_htpComputeSource(EEG);

    if fi == 1
        res.power = pow_results.summary_table;
    else
        res.power = [res.power; pow_results.summary_table];
    end

end



