fx_createVertexFromBstAtlas(atlas)

function fx_createVertexFromBstAtlas( atlas )

% create DK atlas CSV with vertices

atlasCsvName = fullfile(['createVertexFromBstAtlas_' genvarname(atlas.Name) '.csv']);

count = 1;
for i = 1 : numel(atlas.Scouts)

    curScout = atlas.Scouts(i);

    for j = 1 : numel(curScout.Vertices)
        atlasDefCsv{count,1} = curScout.Vertices(j);
        atlasDefCsv{count,2} = curScout.Label;
        atlasDefCsv{count,3} = curScout.Region; %#ok<*SAGROW> 
        count = count + 1;
    end

end

atlasVertexTable = sortrows( cell2table(atlasDefCsv, ...
    'VariableNames', {'Vertex','Label','Region'}));

writetable(atlasVertexTable, atlasCsvName);

end