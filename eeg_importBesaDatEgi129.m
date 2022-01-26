% eeg_importBesaData() - Import BESA dat file
% 
% Usage:
%    >> [ EEG ] = eeg_importBesaDatEgi129( besa_filename, varargin )
%
% Inputs: (use key value pairs)
%     besa_filename     - *.dat BESA filename 
%     nbchan            - number of channels
%     fs                - sampling rate
%     xmin              - start time of data
%     points_per_trial  - samples per epoch
%
% Outputs:
%     EEG               - EEGLAB structure
%
%  This file is part of the Cincinnati Visual High Throughput Pipeline,
%  please see http://github.com/cincibrainlab
%    
%  Contact: ernest.pedapati@cchmc.org
%

function EEG = eeg_importBesaDatEgi129( besa_filename, varargin )

% Default Parameters
defaultChanFile = 'GSN-HydroCel-129_new.sfp';
defaultNbchan = 129;
defaultFs = 500;
defaultXmin = -.5;
defaultPoints_per_trial = 1626;

ip = inputParser();
addRequired(ip,'besa_filename', @ischar);
addOptional(ip,'channel_file', defaultChanFile);
addOptional(ip,'nbchan',defaultNbchan);
addOptional(ip,'fs',defaultFs);
addOptional(ip,'xmin', defaultXmin);
addOptional(ip,'points_per_trial', defaultPoints_per_trial);
parse(ip,besa_filename,varargin{:})


nbchan = ip.Results.nbchan;
fs     = ip.Results.fs;
xmin   = ip.Results.xmin;
channel_file = ip.Results.channel_file;
points_per_trial = ip.Results.points_per_trial;
[~, setname, ~] = fileparts(besa_filename);

verifyNetFile('GSN-HydroCel-129_new.sfp');

EEG = pop_importdata(...
    'dataformat','float32le',...
    'nbchan', nbchan,...
    'data', besa_filename,...
    'setname', setname, ...
    'srate', fs,...
    'pnts', points_per_trial,...
    'xmin',xmin,...
    'chanlocs',channel_file);

EEG = pop_chanedit(EEG, 'load', defaultChanFile);
% EEG = readegilocs2(EEG, defaultChanFile); % trying built-in EEG function

end

function verifyNetFile(netfile)

if ~isfile(netfile)
    warning("Required file: GSN-HydroCel-129_new.sfp missing")
    response = 'N';
    if strcmpi(response,'n')
        response = input('Do you want to download from github (Y/N)?','s');
        if strcmpi(response,'y')
            urlwrite('https://raw.githubusercontent.com/cincibrainlab/htp_minimum/main/chanfiles/GSN-HydroCel-129_new.sfp', ...
                'GSN-HydroCel-129_new.sfp');
        else
            error("Please add file: GSN-HydroCel-129_new.sfp to path before continuing.")
        end
    end
end

end
