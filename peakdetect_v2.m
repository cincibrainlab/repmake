function obj = peakdetect_v2( obj )
% variant from peakdetect_v1, but 
% wider frequency window [3, 14]
% consider single trials

% change back to 6-14 Hz 03/09/2021
    spectrum = obj.rest_rel_power; % 161 x 138 x 128
    peak_loc = NaN(obj.EEG.trials,obj.EEG.nbchan);
    for j=1:obj.EEG.trials
        for i=1:obj.EEG.nbchan
            [pks,locs] = findpeaks(log10(spectrum(:,j,i))); 
            window = locs>=6*2+1 & locs<=14*2+1; % [3, 14] Hz
            if any(window)
                peak_locs = locs(window);
                [~,index] = max(pks(window));
                peak_loc(j,i) = (peak_locs(index)-1)/2; % in Hz
            else
                continue % no max -> NaN
            end
        end
    end
    obj.rest_peakloc2 = peak_loc;
end