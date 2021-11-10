%=========================================================================%
% MATLAB COMMON   ========================================================%
%                 Specify Computer Specific Paths                         %
%                 Create 1 file per host                                  %
%=========================================================================%

% Host/Computer Description
% Linux Cluster CBL
hostname = char(java.net.InetAddress.getLocalHost.getHostName);

% Folder root directory
ROOT_PATH = '/srv/';

%=========================================================================%
%                     CREATE REPRODUCIBLE ENVIRONMENT                     %
%=========================================================================%
IsBatchMode = batchStartupOptionUsed; % to run from command line
if IsBatchMode, restoredefaultpath(); end  % reset to default path

%=========================================================================%
%                           TOOLBOX CONFIGURATION                         %
% eeglab: https://sccn.ucsd.edu/eeglab/download.php                       %
% high throughput pipline: github.com/cincibrainlab/htp_minimum.git       %
% fieldtrip: https://www.fieldtriptoolbox.org/download/                   %
% brainstorm: https://www.fieldtriptoolbox.org/download/                  %
%=========================================================================%

TOOLKIT_PATH            = fullfile(ROOT_PATH, 'TOOLKITS/');   % edit

% Subdirectories
HTP_PATH                = fullfile(TOOLKIT_PATH, 'htp_minimum');
EEGLAB_PATH             = fullfile(TOOLKIT_PATH, 'eeglab2021');
BRAINSTORM_PATH         = fullfile(TOOLKIT_PATH, 'brainstorm3');
FIELDTRIP_PATH          = fullfile(TOOLKIT_PATH, 'fieldtrip-master');
OPENMEEG_PATH           = fullfile(TOOLKIT_PATH, 'OpenMEEG-2.4.1-Linux');

%=========================================================================%
%                           SOURCE DIRECTORY                              %
%=========================================================================%
REPMAKE_PATH           = fullfile(ROOT_PATH,'REPMAKE');
SOURCE_PATH            = fullfile(REPMAKE_PATH, 'SOURCE');

% Add paths to toolboxes (w or without subfolders)
cellfun(@(x) addpath(x), {EEGLAB_PATH, BRAINSTORM_PATH, ...
    FIELDTRIP_PATH, REPMAKE_PATH, SOURCE_PATH}, 'uni',0)
cellfun(@(x) addpath(genpath(x)), {HTP_PATH, OPENMEEG_PATH}, 'uni',0)

%=========================================================================%
%                          CUSTOM FUNCTIONS                               %
%=========================================================================%

r = repMakeClass;

%=========================================================================%
% RepMake          Reproducible Manuscript Toolkit with GNU Make         %
%                  Version 8/2021                                         %
%                  cincibrainlab.com                                      %
% ========================================================================%
