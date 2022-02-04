

%% Resting Power Analysis
outputdir = tempdir;
datadir = '/srv/RAWDATA/Stalicla/Rest_EyesOpen/';

filelist_rest = utility_htpDirectoryListing(datadir,'ext','.set');

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
filelist = utility_htpDirectoryListing(datadir,'ext','DIN8.set');

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

filelist_hab = utility_htpDirectoryListing(datadir,'ext','.set');
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



