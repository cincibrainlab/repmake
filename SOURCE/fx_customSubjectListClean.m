function subjectList = fx_customSubjectListClean( subjectList, project_name )

if nargin < 2
    project_name = 'default';
end

if ~iscolumn(subjectList), subjectList = subjectList'; end

switch project_name
    case 'Proj_RepMakeTest'
        subjectListTmp = cleanSubList(subjectList,'DD','D');
        subjectList = cleanSubList( subjectListTmp, '_postcomp', '');
    otherwise
        subjectList = cleanSubList( subjectList, '', '');

end
end

function cleanedSubList = cleanSubList( subjectList, badchars, newchars )
% input: subjectList, cell array or table column of strings
% input: badchars, characters to remove or replace
% input: newchars, replacement chracters or '' for blank
% output: subjectList, after cleaning
% helper function to clean a string of a character sequence
strr = @(cellarr, old, new) cellfun(@(cellarr) strrep(cellarr, old, new), cellarr, 'uni',0 );
if(istable(subjectList)), subjectList = table2cell(subjectList); end
subjectListTmp = strr( subjectList, badchars, newchars);
cleanedSubList = cell2table(subjectListTmp, 'VariableNames', {'eegid'});
end
