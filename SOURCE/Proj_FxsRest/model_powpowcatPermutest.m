%=========================================================================%
% RepMake           Reproducible Manuscript Toolkit with GNU Make         %
%=========================================================================%
% CLUSTER PERMUTATION TESTING                                             %
%=========================================================================%
% permutest function from
% use git clone https://github.com/edden-gerber/time_series_analysis_and_statistics.git

% Data Type: Power-Power Coupling

%=========================================================================%
% Step 1: Load data                                                       %
% ========================================================================%

data_file = 'model_powpowAAC_relative.mat'; % any MAT/Parquet inputs (or NA)
data_file = 'model_powpowAAC.mat'; % any MAT/Parquet inputs (or NA)

if ~ismissing(data_file)
    load(fullfile(syspath.BigBuild, data_file))
end
%%

% 
curResultArr = resultArr2;
 
 curResultArr
 for ri = 1 : numel(curResultArr)
     resArrEegid{ri} = curResultArr{ri}.eegid;
 end
[subjectList resArrEegid']
% match subjects with group assignments
subjectList = cell2table(resArrEegid', 'VariableNames', {'eegid'});
matchedSubjectTable = innerjoin( subjectList, groupLookupTable, 'Keys', {'eegid','eegid'});

% load frequency axis
sampleResult = curResultArr{1};
if isgpuarray(sampleResult.freqs)
    freqList = gather(sampleResult.freqs);
else
    freqList = sampleResult.freqs;
end
%chanlocs = sampleResult.chanlocs;
chanList = cell2table({chanlocs.labels}', 'VariableNames', {'labelclean'});
matchedChanList = innerjoin( chanList, chanLookupTable, 'Keys', {'labelclean','labelclean'});
networkNames = unique(matchedChanList.RSN);
% preallocate

comodulogramAll = [];

% create loop to load AAC comodulograms
for ni = 1 : numel(networkNames)
    netIdx = strcmp(chanLookupTable.("RSN"), networkNames{ni});
    for si = 1 : numel(curResultArr)
        covmattmp = curResultArr{si}.covMatrix;
        comodulogramAll.(networkNames{ni})(:,:,si)  = mean(covmattmp(:,:,netIdx),3); %#ok<SAGROW>
    end
end

        yfreqTickList = [1,5,10,20,30,50,90];
        xfreqTickList = [1,5,10,20,30,50,90];
        lowfreqTickList = [3.5:12.5];
        highfreqTickList = [30:90];

        lowfreqTickList = lowfreqTickList;
        highfreqTickList = highfreqTickList;

        %lowfreqTickList = yfreqTickList;
        %highfreqTickList = xfreqTickList;

        [~,yTickIdx] = arrayfun( @(x) min(abs(freqList- x)), yfreqTickList);
        [~,xTickIdx] = arrayfun( @(x) min(abs(freqList- x)), xfreqTickList);
        [~,lowTickIdx] = arrayfun( @(x) min(abs(freqList- x)), lowfreqTickList);
        [~,highTickIdx] = arrayfun( @(x) min(abs(freqList- x)), highfreqTickList);


statResultsByNetwork = [];
for ni = 1 : numel(networkNames)

    comodulogram = comodulogramAll.(networkNames{ni});
    % cluster permutation statistic function
    listComps = {{'GroupMain', 'group', {'FXS','TDC'}};
        {'GroupMale', 'subgroup', {'FXS_M','TDC_M'}};
        {'GroupFemale', 'subgroup', {'FXS_F','TDC_F'}};
        {'SexFXS', 'subgroup', {'FXS_M','FXS_F'}};
        {'SexControl', 'subgroup', {'TDC_M','TDC_F'}}};
    groupList = {'FXS_M','TDC_M'};

    clusters = []; p_values = []; t_sums = []; permutation_distribution =[];
    for li = 1 : numel(listComps)
        currentComp = listComps{li};  % current comparision
        currentCompLabel = currentComp{1};
        currentCompField = currentComp{2};
        currentCompList = currentComp{3};
        currentGroup1 = currentCompList{1};
        currentGroup2 = currentCompList{2};

        subindex.(currentGroup1) = strcmp(matchedSubjectTable.(currentCompField), currentGroup1);
        subindex.(currentGroup2) = strcmp(matchedSubjectTable.(currentCompField), currentGroup2);

        [clusters.(currentCompLabel), p_values.(currentCompLabel), t_sums.(currentCompLabel), ...
            permutation_distribution.(currentCompLabel) ] = ...
            permutest_pval2( comodulogram(highTickIdx(1):highTickIdx(end), lowTickIdx(1):lowTickIdx(end), subindex.(currentGroup1) ), ...
            comodulogram(highTickIdx(1):highTickIdx(end),lowTickIdx(1):lowTickIdx(end),subindex.(currentGroup2)), false, ...
            .05, 1000, true)
    end

    statResultsByNetwork.(networkNames{ni}).('clusters') = clusters;
    statResultsByNetwork.(networkNames{ni}).('p_values') = p_values;
    statResultsByNetwork.(networkNames{ni}).('t_sums') = t_sums;
    statResultsByNetwork.(networkNames{ni}).('permutation_distribution') = permutation_distribution;
    
end

% DEBUGING
% figure; 
% plot(mean(mean(comodulogram(:,:,subindex.(currentGroup1) ),3),2), 'b');
% hold on;
% plot(mean(mean(comodulogram(:,:,subindex.(currentGroup2) ),3),2));


%%

%figure;

for li = 1 : numel(listComps)
    figure;
    currentComp = listComps{li};  % current comparision
    currentCompLabel = currentComp{1};
    currentCompField = currentComp{2};
    currentCompList = currentComp{3};
    currentGroup1 = currentCompList{1};
    currentGroup2 = currentCompList{2};
    
    plotCount = 1;

    for ni = 1 : numel(networkNames)
        comodulogram = comodulogramAll.(networkNames{ni});
        clusters = statResultsByNetwork.(networkNames{ni}).clusters;
        p_values =statResultsByNetwork.(networkNames{ni}).p_values;
        t_sums =statResultsByNetwork.(networkNames{ni}).t_sums;
        permutation_distribution = statResultsByNetwork.(networkNames{ni}).permutation_distribution;

        groupList = currentCompList;
        plotList = {'group_average','group_diff', 'permutest'};

        totalPlotsCount = 4;
        yfreqTickList = [1,5,10,20,30,50,90];
        xfreqTickList = [1,5,10,20,30,50,90];
        lowfreqTickList = [3.5,7.5,12.5];
        highfreqTickList = [30,40,50,90];

        lowfreqTickList = lowfreqTickList;
        highfreqTickList = highfreqTickList;

        %lowfreqTickList = yfreqTickList;
        %highfreqTickList = xfreqTickList;

        [~,yTickIdx] = arrayfun( @(x) min(abs(freqList- x)), yfreqTickList);
        [~,xTickIdx] = arrayfun( @(x) min(abs(freqList- x)), xfreqTickList);
        [~,lowTickIdx] = arrayfun( @(x) min(abs(freqList- x)), lowfreqTickList);
        [~,highTickIdx] = arrayfun( @(x) min(abs(freqList- x)), highfreqTickList);


        for pi = 1 : numel(plotList)
            switch plotList{pi}
                case 'group_average'
                    sgtitle(currentCompLabel);
                    for gi = 1 : numel(groupList)
                        networkNames{ni}
                        subplot( numel(networkNames),totalPlotsCount,plotCount);
                        imagesc(mean(comodulogram(:,:,subindex.(groupList{gi})),3));
                        title([networkNames{ni} ' :Group' num2str(gi) ': ' groupList{gi}]);
                        axis square; set(gca,'yDir','normal','YTick', highTickIdx,'YTickLabel', highfreqTickList, 'ylim', [highTickIdx(1) highTickIdx(end)], ...
                            'XTick', lowTickIdx, 'xticklabel', lowfreqTickList, 'xlim', [lowTickIdx(1) lowTickIdx(end)]);
                        clim = mean(median(median(comodulogram),3));
                        climsd = mean(std(median(comodulogram)));

                        caxis([-clim- 2*climsd clim+ 2*climsd])

                        plotCount = plotCount + 1;
                    end
                case 'group_diff'
                    subplot( numel(networkNames),totalPlotsCount, plotCount)
                    comodulogram_group1 = mean(comodulogram(:,:,subindex.(groupList{1})),3);
                    comodulogram_group2 = mean(comodulogram(:,:,subindex.(groupList{2})),3);
                    comodulogram_diff = comodulogram_group1 - comodulogram_group2;
                    imagesc(comodulogram_diff);
                    title([groupList{1} ' - ' groupList{2}]);
                    axis square; set(gca,'yDir','normal','YTick', highTickIdx,'YTickLabel', highfreqTickList, 'ylim', [highTickIdx(1) highTickIdx(end)], ...
                        'XTick', lowTickIdx, 'xticklabel', lowfreqTickList, 'xlim', [lowTickIdx(1) lowTickIdx(end)]);
                    plotCount = plotCount + 1;
                case 'permutest'
                    clust_p_values = p_values.(currentCompLabel);

                    subplot( numel(networkNames),totalPlotsCount, plotCount);
                    comodulogram_diff_sig = comodulogram_diff;
                    comodulogram_diff_sig = zeros(size(comodulogram_diff));
                    hold on;
                    for clusti = 1 : numel(clusters.(currentCompLabel))
                        ind = clusters.(currentCompLabel){clusti};
                        [row,col] = ind2sub([numel(freqList) numel(freqList)], ind);

                        % M1 - M2; +t M1 > M2, -t M1 < M2
                        if sign(t_sums.(currentCompLabel)(clusti)) < 1
                            sign_value = -1;
                        else
                            sign_value = 1;
                        end
                        if clust_p_values(clusti) <= .05
                            comodulogram_diff_sig(ind) = sign_value;
                        end
                        imagesc(comodulogram_diff_sig);
                    end
                    imagesc(comodulogram_diff_sig);
                    axis square; set(gca,'yDir','normal','YTick', highTickIdx,'YTickLabel', highfreqTickList, 'ylim', [highTickIdx(1) highTickIdx(end)], ...
                        'XTick', lowTickIdx, 'xticklabel', lowfreqTickList, 'xlim', [lowTickIdx(1) lowTickIdx(end)]);
                    title('Significant Clusters');
                    plotCount = plotCount + 1;
            end
        end

    end
end