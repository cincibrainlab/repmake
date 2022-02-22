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

basename    = 'bstSourcePowStats'; % Edit
prefix      = ['figure_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_bstSourcePowStats.mat'; % any MAT/Parquet inputs (or NA)

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
%% =========================================================================%
%  Specify Power Type    Spectral power is calculated via BST Welsch
%                        function. Code for analysis is carried through
%                        analysis making it easier to search for.
%  Available Codes:      sourceAbsPow855   Absolute Power
%                        sourceRelPow865   Relative Power
%=========================================================================%
powerTypeList = {'sourceAbsPow855','sourceRelPow865'};

%=========================================================================%
% BRAINSTORM       =======================================================%
% Cortical Vis.    Use Brainstorm function to create custom snapshots of  %
%                  statistical results. Colorbar can be made uniform.     %
%=========================================================================%
powerTypeList = {'sourceAbsPow855','sourceRelPow865'};

fx_getBstPowerResults = @( powerType ) bst_process('CallProcess', 'process_select_files_timefreq', [], [], ...
    'subjectname',   'All', ...
    'condition',     '', ...
    'tag',           powerType, ...
    'includebad',    0, ...
    'includeintra',  0, ...
    'includecommon', 0);

% Gather what source models are available
sFilesRecordings = bst_process('CallProcess', 'process_select_files_results', [], []);
availableSourceModels = unique({sFilesRecordings(:).Comment});
cleanSourceType = @(irregularName) regexprep(irregularName, {'[%(): ]+', '_+$'}, {'_', ''});

% Create fieldnames of all possible combinations of power / source
% calculations
count = 0;
powerCombos = {};

for i = 1 : numel(availableSourceModels)
    sourceType = availableSourceModels{i};
    for j = 1 : numel(powerTypeList)
        count = count + 1;
        powerType = [cleanSourceType(sourceType) '_' powerTypeList{j}];
        powerCombos{count,1} = powerType;
        powerCombos{count,2} = sourceType;
        powerCombos{count,3} = powerTypeList{j};
    end
end

% Gather all relevant statistics
[sSubject,iSubject]=bst_get('Subject', 'Group_analysis');
sStudies = bst_get('StudyWithSubject', sSubject.FileName, 'intra_subject');
sStat = [sStudies.Stat];

selStat = {};
for istat = 1 : numel(sStat)
    currentStat = sStat(istat);

    for i = 1 : size(powerCombos,1)
        powerType = powerCombos{i,1};
        % only select scalp and selected power
        if contains(currentStat.Comment, powerType)
            selStat{end+1} = currentStat;
        end
    end
end

exportImage = {};
for i = 1 : numel(selStat)
    sStat = selStat{i};


    OverlayFile = sStat.FileName;
    OverlayDetails = in_bst(OverlayFile);
    sStatsFields = {sStat.Comment};
    powerType = sStat.Comment;

    target_file_panel = strrep(target_file, '.mat', ['_' powerType '.tif']);

    orientation     = 'fig';
    viewports       = {...
        'top', 'bottom', ...
        'left', 'right', ...
        'left_intern', 'right_intern'};
    viewport_crop   = ...
        {[520 420],[520 420], ...
        [520 530],[520 530], ...
        [520 530],[520 530]};
    viewport_labels = ...
        {'Superior','Inferior', ...
        'L.Lateral','R. Lateral',...
        'L. Sagittal','R. Sagittal'};

    colorMapMin     = -5;
    colorMapMax     = +5;

    newimg = {};


    %for stati = 1 : length(sStats.(powerType))
    %    OverlayFile = availableStats(stati).FileName;
    %    OverlayDetails = in_bst(OverlayFile);

    if ~isempty(OverlayDetails.SurfaceFile)
        [hFig, iDS, iFig] = view_surface_data([], OverlayFile);
        %currentColorBar = fx_BstSetColormap(hFig, colorMapMin, colorMapMax);
        %             saveas(currentColorBar, ...
        %                 fullfile(project.view_output, ['cbar_' OverlayDetails.Comment '.pdf']));
        % close(currentColorBar);
        % create grid freq x viewport
        for viewi = 1 : length(viewports)
            currentView = viewports{viewi};
            figure_3d('ResetView', hFig);
            figure_3d('SetStandardView', hFig, currentView);
            for freqi = 1 : size(OverlayDetails.Freqs,1)

                % current frequency
                currentFreq = OverlayDetails.Freqs{freqi, 1};
                panel_freq('SetCurrentFreq',  freqi, true);

                imgFile = ...
                    fullfile(syspath.BigBuild, ...
                    [OverlayDetails.Comment '_' currentView '_' currentFreq '.tif']);

                % remove colorbar
                bst_colormaps('SetColorbarVisible', hFig, false);

                % modify to white background image
                bst_figures('SetBackgroundColor', hFig, [1 1 1]);

                rawimg = out_figure_image( hFig, imgFile, []);
                cropimg = fx_customImageCropImage(rawimg, viewport_crop{viewi});

                %figure; imshow(fx_customImageCropImage(rawimg, [520 600] ));
                %figure; imshow(rawimg);

                rawimg_index{viewi, freqi} = cropimg;
            end
        end
        currentColorBar = fx_BstSetColormap(hFig, colorMapMin, colorMapMax);

        close(hFig);

        % frequency strips with different viewports
        for i = 1 : size(OverlayDetails.Freqs,1)
            newimg{i} = [rawimg_index{:, i}];
        end

        % create full image without labels
        img_fig = vertcat(newimg{:});


        % create column labels (Viewports)
        view_label_str = {};
        view_label_str = cellfun( @(x,y) fx_customImageText2ImRow(x,y), ...
            viewport_labels, viewport_crop, 'uni',0);
        img_label = horzcat(view_label_str{1,:});

        % add viewport labels to figure
        img_fig_viewport = vertcat(img_fig, img_label);

        % add row labels (Frequencies)
        freq_label_str = {};
        for freqi = 1 : size(OverlayDetails.Freqs,1)
            currentFreq = OverlayDetails.Freqs{freqi, 1};
            imtest = fx_customImageText2ImCol(...
                currentFreq, [520 490] );
            freq_label_str{freqi,1} = imtest;
        end
        freq_label = vertcat(freq_label_str{:,1});


        % Create panel
        whitesquare = 255 .* ones(size(img_label,1), ....
            size(freq_label,2),3, 'uint8');
        position_small_image = [25 0];
        A = whitesquare;
        B = imresize(currentColorBar,.9);
        Y=position_small_image(1);
        X=position_small_image(2);
        A((1:size(B,1))+X,(1:size(B,2))+Y,:) = B;

        freq_label2 = vertcat(freq_label, A);
        panel_imag = horzcat(freq_label2, img_fig_viewport);
        %figure; imshow(horzcat(view_label_str{1,:}))
        %figure; imshow(horzcat(freq_label2, img_fig_viewport))
        %newimg{:, stati} = panel_imag;

        %=========================================================================%
        %                          EXPORT ENVIRONMENT                             %
        %=========================================================================%
        try
            imwrite( panel_imag, strrep(target_file_panel, 'figure_bstSourcePowStats',['figure_bstSourcePowStats_' sStat.Comment]));
            fprintf("Success: Saved %s", target_file);
        catch ME
            disp(ME.message);
            fprintf("Error: Save Target File");
        end

    end
end

brainstorm exit;


