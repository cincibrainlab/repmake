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

% Make sure correct project runfile is loaded

eeglab nogui;

%=========================================================================%
% Step 2: Customize basename for script                                   %
%=========================================================================%

basename    = 'bstExtractSourceTimeSeries'; % Edit
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
%
[~,project_name,~] = fileparts(syspath.htpdata);
ProtocolName          = project_name; % set protocol name                 %
fx_getBrainstormVars;  % brainstorm include                                %
%                     script will end if wrong protocol                   %
%=========================================================================%


% Set Tag for Source Type Selection, can use alternativeSourceTypeComment
% if specificed, i.e. Beamformer
if ~exist('alternateSourceTypeComment','var')
    sourceTypeComment = 'MN: EEG(Constr) 2018';
else
    sourceTypeComment = alternateSourceTypeComment;
end

sFilesSources = bst_process('CallProcess', 'process_select_files_results',[], [], ...
    'tag',           sourceTypeComment, ...
    'includebad',    0, ...
    'includeintra',  0, ...
    'includecommon', 0);

bstSubList = fx_customSubjectListClean( {sFilesSources.SubjectName});

sourceDesc = regexprep(sFilesSources(1).Comment, {'[%(): ]+', '_+$'}, {'_', ''});

for i = 1 : numel(bstSubList)

    htpSubIndex = find(strcmp(bstSubList.eegid(i),{p.sub.subj_basename}));
    s = p.sub(htpSubIndex);

    % Process: Scouts time series: [68 scouts]
    sFilesExtract = bst_process('CallProcess', 'process_extract_scout', ...
        sFilesSources(i), [], ...
        'timewindow',     [], ...
        'scouts',         {atlas.Name, {atlas.Scouts.Label}}, ...
        'scoutfunc',      1, ...  % Mean
        'isflip',         1, ...
        'isnorm',         0, ...
        'concatenate',    1, ...
        'save',           0, ...
        'addrowcomment',  1, ...
        'addfilecomment', 1);

    EEG = eeg_emptyset;  % creates empty eeglab set
    EEG = eeg_checkchanlocs(EEG);

    EEG.times = sFilesExtract.Time;  % times vector from bst
    EEG.data = sFilesExtract.Value(:,:);  % data for each source channel

    for j = 1 : length( sFilesExtract.Atlas.Scouts )  % create chanlocs from atlas regions
        tmpatlas = sFilesExtract.Atlas.Scouts(i);
        EEG.chanlocs(i).labels = genvarname( tmpatlas.Label );
        EEG.chanlocs(i).type = 'EEG';
    end

    EEG.group = s.subj_subfolder;
    EEG.setname = s.subj_basename;
    EEG.subject = s.subj_basename;
    EEG.filename = s.filename.postcomps;
    EEG.srate = s.proc_sRate1;

    EEG.comments = sourceDesc;
    EEG.etc.atlas = atlas;
    EEG = eeg_checkset(EEG);

    s.filename.(genvarname(sourceDesc)) = strrep(s.filename.postcomps, 'p.', ['p_' genvarname(sourceDesc) '.']);


    s.storeDataset(EEG, s.pathdb.signal, s.subj_subfolder, s.filename.(genvarname(sourceDesc)));

    s.outputRow('signal');

end
s.loadDataset('signal')
csvfile = p.createResultsCsv(p.sub, 'signal', sourceDesc );

%% =========================================================================%
%                          EXPORT ENVIRONMENT                             %
%=========================================================================%
try
    save(target_file, 'p', 'syspath', 'keyfiles', 'csvfile')
    fprintf("Success: Saved %s", target_file);
catch ME
    disp(ME.message);
    fprintf("Error: Save Target File");
end
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
