function obj = peakdetect_v1( obj )
% Neurobiology of Aging 71(2018) 149-155:
% Trials are averaged out before calculation. (not mentioned in ref)
% power spectral desity of each EEG channel was estimated
% findpeaks function used to locate the frequency of local max 
% relative (revised) logarithmic power between 6 and 14 Hz. 
% The peak frequency from each channel was averaged as the IAPF. - Betsy

    if ~isempty(obj.rest_rel_power_v2)
        % rest_rel_power_v2 -- pwelch
        spectrum = obj.rest_rel_power_v2;
    else
        % rest_rel_power -- original
        spectrum = squeeze(mean(obj.rest_rel_power,2)); % dismiss - trials
    end
    peak_loc = NaN(1,obj.EEG.nbchan);
    for i=1:obj.EEG.nbchan
        [pks,locs] = findpeaks(log10(spectrum(:,i))); 
        window = locs>=6*2+1 & locs<=14*2+1; % [6, 14] Hz
        if any(window)
            peak_locs = locs(window);
            [~,index] = max(pks(window));
            peak_loc(i) = (peak_locs(index)-1)/2; % in Hz
        else
            continue % no max -> NaN
        end
        %%%
%         spectrum1 = s.rest_abs_power_v2(:,4);
%         
%         x = reshape(squeeze(EEG.data(4,:,:)),1,[]);
%         [~,~,~,pxx] = spectrogram(x, EEG.srate, round(EEG.srate/2), 0:0.5:80, EEG.srate);
%         spectrum2 = nanmean(pxx,2);
% %         spectrum2 = nanmean(pxx./repmat(sum(pxx),length(0:0.5:80),1),2); 
% 
%         spectrum3 = squeeze(mean(s.rest_abs_power(1:161,:,4),2));
%         
%         [pks1,locs1] = findpeaks(log10(spectrum1)); 
%         window1 = locs1>=6*2+1 & locs1<=14*2+1;
%         peak_locs1 = locs1(window1);
%         [~,index1] = max(pks1(window1));
%         peak_loc1 = (peak_locs1(index1)-1)/2;
%         
%         [pks2,locs2] = findpeaks(log10(spectrum2)); 
%         window2 = locs2>=6*2+1 & locs2<=14*2+1;
%         peak_locs2 = locs2(window2);
%         [~,index2] = max(pks2(window2));
%         peak_loc2 = (peak_locs2(index2)-1)/2;
%         
%         [pks3,locs3] = findpeaks(log10(spectrum3)); 
%         window3 = locs3>=6*2+1 & locs3<=14*2+1;
%         peak_locs3 = locs3(window3);
%         [~,index3] = max(pks3(window3));
%         peak_loc3 = (peak_locs3(index3)-1)/2;
%         
%         figure;subplot(311);plot(0:0.5:80,spectrum1);hold on;
%         stem(peak_loc1,spectrum1(peak_locs1(index1)))
%         title('pwelch');
%         subplot(312);plot(0:0.5:80,spectrum2);hold on;
%         stem(peak_loc2,spectrum2(peak_locs2(index2)))
%         title('average spectrogram');
%         subplot(313);plot(0:0.5:80,spectrum3);hold on;
%         stem(peak_loc3,spectrum3(peak_locs3(index3)))
%         title('generateStoreRoom');suptitle('D0057 E4 absolute')
        %%%
    end
    obj.rest_peakloc_rel = peak_loc;
    
% % rest_abs_power -- 04.19.2021
%     spectrum = squeeze(mean(obj.rest_abs_power,2)); % dismiss - trials
%     peak_loc = NaN(1,obj.EEG.nbchan);
%     for i=1:obj.EEG.nbchan
%         [pks,locs] = findpeaks(log10(spectrum(:,i))); 
%         window = locs>=6*2+1 & locs<=14*2+1; % [6, 14] Hz
%         if any(window)
%             peak_locs = locs(window);
%             [~,index] = max(pks(window));
%             peak_loc(i) = (peak_locs(index)-1)/2; % in Hz
%         else
%             continue % no max -> NaN
%         end
%     end
%     obj.rest_peakloc_abs = peak_loc;
    
% % rest_abs_power_normlogHz
%     spectrum = squeeze(mean(obj.rest_abs_power_normlogHz,2)); % dismiss - trials
%     peak_loc = NaN(1,obj.EEG.nbchan);
%     for i=1:obj.EEG.nbchan
%         [pks,locs] = findpeaks(log10(spectrum(:,i))); 
%         window = locs>=6*2+1 & locs<=14*2+1; % [6, 14] Hz
%         if any(window)
%             peak_locs = locs(window);
%             [~,index] = max(pks(window));
%             peak_loc(i) = (peak_locs(index)-1)/2; % in Hz
%         else
%             continue % no max -> NaN
%         end
%     end
%     obj.rest_peakloc_abs_normlogHz = peak_loc;
    
% % rest_abs_power_normHz
%     spectrum = squeeze(mean(obj.rest_abs_power_normHz,2)); % dismiss - trials
%     peak_loc = NaN(1,obj.EEG.nbchan);
%     for i=1:obj.EEG.nbchan
%         [pks,locs] = findpeaks(log10(spectrum(:,i))); 
%         window = locs>=6*2+1 & locs<=14*2+1; % [6, 14] Hz
%         if any(window)
%             peak_locs = locs(window);
%             [~,index] = max(pks(window));
%             peak_loc(i) = (peak_locs(index)-1)/2; % in Hz
%         else
%             continue % no max -> NaN
%         end
%     end
%     obj.rest_peakloc_abs_normHz = peak_loc;
    
% % rest_abs_power_normDelta
%     spectrum = squeeze(mean(obj.rest_abs_power_normDelta,2)); % dismiss - trials
%     peak_loc = NaN(1,obj.EEG.nbchan);
%     for i=1:obj.EEG.nbchan
%         [pks,locs] = findpeaks(log10(spectrum(:,i))); 
%         window = locs>=6*2+1 & locs<=14*2+1; % [6, 14] Hz
%         if any(window)
%             peak_locs = locs(window);
%             [~,index] = max(pks(window));
%             peak_loc(i) = (peak_locs(index)-1)/2; % in Hz
%         else
%             continue % no max -> NaN
%         end
%     end
%     obj.rest_peakloc_abs_normDelta = peak_loc;
%     obj.rest_peakloc = obj.rest_peakloc_rel; % temp
end