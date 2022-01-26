% Source Chirp

res.chirp = table();

datadir = '/srv/RAWDATA/Proj_FxsChirp/S04_POSTCOMP/';

filelist = utility_htpDirectoryListing(datadir,'ext','.set');

% start brainstorm
try brainstorm, catch, error("Brainstorm Not Found."); end

% create source files
for fi = 1 : height(filelist)

    EEG = pop_loadset(filelist{fi, 2}{1}, filelist{fi,1}{1});
    EEG2 = eeg_htpComputeSource(EEG);

end

%%
% Chirp Calculation on Source
datadir = '/tmp/';
filelist = utility_htpDirectoryListing(datadir,'keyword','2018','ext','.set', 'subdirOn', true);

for fi = 1 : height(filelist)
fi
    [EEGcell_SourceChirp{fi}, chirp_results] = eeg_htpCalcChirpItcErsp(EEG2, 'SourceOn', true);

    if fi == 1
        res.chirp = chirp_results.summary_table;
    else
        res.chirp = [res.chirp; chirp_results.summary_table];
    end

end

grpidx = cellfun(@(x) x.group,EEGcell_SourceChirp,'UniformOutput',0 );

grpidx2 = strcmp(grpidx,"TDC");
grpidx2(1:40) = 0;

eeg_htpVisualizeChirpItcErsp(EEGcell_SourceChirp, 'groupids', grpidx2  )

%%
for fi = 2 : height(filelist)

    %eegfile = fullfile(filelist{fi, 1}, filelist{fi,2}); % combine dir and filename
    
    EEG = pop_loadset(filelist{fi, 2}{1}, filelist{fi,1}{1});
%     
%     % epoch by points 
%     epochTime = 1626 / EEG.srate;
%     epochStart = - .500;
%     epochEnd = epochTime -.500;
% 
%     EEG = eeg_regepochs(EEG, 'limits', [epochStart epochEnd], 'rmbase', 0);
  [EEG2] = eeg_htpComputeSource(EEG);

    [EEGcell_Chirp{fi}, chirp_results] = eeg_htpCalcChirpItcErsp(EEG2, 'SourceOn', true);

    if fi == 1
        res.chirp = chirp_results.summary_table;
    else
        res.chirp = [res.chirp; chirp_results.summary_table];
    end

end

eeg_htpVisualizeChirpItcErsp({EEGcell_Chirp{fi}})

writetable(res.chirp, fullfile(outputdir, 'stalicla_res_chirp.csv'));

  [EEG2] = eeg_htpComputeSource(EEG);

  contains({EEG2.chanlocs.labels},"temporal")