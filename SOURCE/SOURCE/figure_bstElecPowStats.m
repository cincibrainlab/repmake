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

basename    = 'bstElecPowStats'; % Edit
prefix      = ['figure_' basename];

%=========================================================================%
% Step 3: Specify  pre-existing MAT to load into environment when script. %
%         If data will be used for multple tables or figures we recommend %
%         creating a model file with data saved in a MAT. Use missing if  %
%         no data is necessary.                                           %
%=========================================================================%

data_file = 'model_bstElecPowStats.mat'; % any MAT/Parquet inputs (or NA)

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

powerTypeList = {'scalpAbsPow755','scalpRelPow765'};

%=========================================================================%
% BRAINSTORM       =======================================================%
% TOPOPLOTS        Use Brainstorm function to create custom snapshots of  %
%                  statistical results. Colorbar can be made uniform.     %
%=========================================================================%

% Gather all relevant statistics
[sSubject,iSubject]=bst_get('Subject', 'Group_analysis');
sStudies = bst_get('StudyWithSubject', sSubject.FileName, 'intra_subject');
sStat = [sStudies.Stat];

selStat = {};
for istat = 1 : numel(sStat)
    currentStat = sStat(istat);

    for i = 1 : numel(powerTypeList)
        powerType = powerTypeList{i};
        % only select scalp and selected power
        if contains(currentStat.Comment, powerType)
            selStat{end+1} = currentStat;
        end
    end
end



exportImage = {};
for i = 1 : numel(selStat)
    selStatCurrent = selStat{i};

%=========================================================================%
% Step 1: Retrieve Statistics Variable and Parameters                     %
%=========================================================================%

    OverlayDetails = in_bst(selStatCurrent.FileName);
    Freq = OverlayDetails.Freqs;
    nFreq = length(Freq);

%=========================================================================%
% Step 2: Generate Topography Plot of Statistics                          %
%=========================================================================%

    [hFig, iDS, iFig] = view_topography(selStatCurrent.FileName, 'EEG', '2DDisc');

%=========================================================================%
% Step 3: Confirm FDR correction                                          %
%=========================================================================%

    ctrl = bst_get('PanelControls', 'Stat');
    if ctrl.jRadioCorrFdr.isSelected
        ctrl.jRadioCorrFdr.setSelected(1);
        panel_stat('SaveOptions');
    end
    
%=========================================================================%
% Step 4: Create Snapshots                                          %
%=========================================================================%

    colorMapMin     = -5;
    colorMapMax     = +5;
    currentColorBar = fx_BstSetColormap(hFig, colorMapMin, colorMapMax);

    for fi = 1 : nFreq
        panel_freq('SetCurrentFreq',  fi, true);
        
        sColormap = bst_colormaps('GetColormap', 'stat2');
        sColormap.MaxMode  = 'custom';
        sColormap.MinValue = colorMapMin;
        sColormap.MaxValue = colorMapMax;
        bst_colormaps('SetColormap', 'stat2', sColormap);
        bst_colormaps('FireColormapChanged','stat2');
        bst_colormaps('SetColorbarVisible', hFig, false);
    
        F = getframe(hFig);
        [X, Map] = frame2im(F);
        hPanel{fi} = X;
    end
    close(hFig);
    hPanelTopo = imtile(hPanel, 'GridSize', [1 nFreq]);
       
%=========================================================================%
% Step 4: Create Freq Labels                                              %
%=========================================================================%
    freq_label_str = {};
    for freqi = 1 : size(OverlayDetails.Freqs,1)
        currentFreq = OverlayDetails.Freqs{freqi, 1};
        imtest = fx_customImageText2ImCol(...
            currentFreq, [200 size(hPanelTopo,2)/nFreq] );
        freq_label_str{freqi,1} = imtest;
    end
    hPanelFreqLabel = horzcat(freq_label_str{:,1});

%=========================================================================%
% Step 4: Combine Images with Colorbar                                    %
%=========================================================================%

    hPanelFinal = vertcat(hPanelTopo, hPanelFreqLabel);
    currentColorBarRot = imrotate(currentColorBar,90);
    hPanelHeight = size(hPanelFinal,1);
    padHeight = (hPanelHeight - size(currentColorBarRot,1))/2;
    paddedImage = padarray(currentColorBarRot,[padHeight 0],255);  %swapped the elements of padsize
    exportImage.(powerType) = horzcat(paddedImage,hPanelFinal);

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

end

brainstorm exit;
%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make          %
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
