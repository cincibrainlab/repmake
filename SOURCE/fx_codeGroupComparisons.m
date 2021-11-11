function compblocklist = fx_codeGroupComparisons( listComps, matchedSubjectTable)
% listComps, structured cell input for what comparisions should be made
% matchedSubjectTable, table with ID and grouping values in columns
% output is a n x 3 cell array, with n being the number of pairwise
% comparisions requested in listComps. The 1st column is the comparison
% title/label, the 2nd column is the index of the IDs for each group, and
% 3rd column has a 1x2 cell array with the group labels.
count = 1;
for i = 1 : numel(listComps)
    comp = listComps{i};
    compblock = createComparisonBlock(matchedSubjectTable, ...
        comp{1}, comp{2}, comp{3});
    if ~isempty(compblock{1,2}{1}) && ~isempty(compblock{1,2}{2})
        if count == 1
            compblocklist = compblock;
            count = count +1;
        else
            compblocklist = [compblocklist;compblock];
        end
    end
end

end

function compblock = createComparisonBlock( matchedSubjectTable, comp_title, matching_fieldname, matching_string_pair )
% comp_title, input title of comparisons (for filenames)
% matching_string_pair, cell array {'group1','group2'} to defined comparison
% compblock, output cell array which contains title, indexes, and string
% pair
assert(iscell(matching_string_pair) && numel(matching_string_pair) == 2, ...
    'Wrong Input Format of matching_string_pair')
% helper function to find indexes
smatch = @(key,list) find(strcmp(key, list));
compblock{1,1} = comp_title;
compblock{1,2} = {smatch(matching_string_pair{1}, matchedSubjectTable.(matching_fieldname)), ...
    smatch(matching_string_pair{2}, matchedSubjectTable.(matching_fieldname))};
compblock{1,3} = matching_string_pair;
end

function matchedSubjectTable = lookupSubjectGroups( subjectCol, groupLookupTable )
% input: subjectCol, table column of eegids
% input: groupLookupTable, table with group information with eegid column
% output: matchedSubjectTable, matched table with group info
matchedSubjectTable = innerjoin( subjectCol, groupLookupTable, 'Keys', {'eegid','eegid'});
end

