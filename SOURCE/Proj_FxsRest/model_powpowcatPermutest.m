
subjectList = cell2table({p.sub.subj_basename}', 'VariableNames', {'eegid'});
 matchedSubjectTable = innerjoin( subjectList, groupLookupTable, 'Keys', {'eegid','eegid'});

 subindex.('fxs') = strcmp(matchedSubjectTable.group, 'FXS');
 subindex.('tdc') = strcmp(matchedSubjectTable.group, 'TDC');
chanlocs(1)
for si2 = 1 : numel(resultArr1)

    covmattmp = resultArr1{si2}.covMatrix;
    covmat(:,:,si2) = covmattmp(:,:,1);

end

   p.sub



[clusters, p_values, t_sums, permutation_distribution ] = ...
    permutest( covmat(:,:,subindex.('fxs') ), covmat(:,:,subindex.('tdc')), false, ...
    .05, 1000, true)


%%
figure;
sgtitle('Node 1 Comparision')
subplot(1,4,1)
imagesc(mean(covmat(:,:,subindex.('fxs')),3))
colorbar; caxis([0 1]); axis square;
set(gca,'ydir','normal')
title('FXS n=70')

subplot(1,4,2); 
imagesc(mean(covmat(:,:,subindex.('tdc')),3))
colorbar; caxis([0 1]); axis square;
set(gca,'ydir','normal')
title('Control n=71')

subplot(1,4,3)
imagesc(mean(covmat(:,:,subindex.('fxs')),3) - mean(covmat(:,:,subindex.('tdc')),3))
colorbar; axis square;
set(gca,'ydir','normal')
title('FXS - Control')

subplot(1,4,4)
imagesc(mean(covmat(:,:,subindex.('fxs')),3) - mean(covmat(:,:,subindex.('tdc')),3))
colorbar; axis square;
set(gca,'ydir','normal')
title('TDC>FXS Red; FXS<TDC Green ')

hold on;
for clusti = 1 : numel(clusters)
    ind = clusters{clusti};
[row,col] = ind2sub([100 100], ind);
if sign(t_sums(clusti) < 1)
    scatter(row,col, 'r.');
else
    scatter(row,col, 'g.');
end
end
