function VocList = getVocFreqlist(R)
VocList = zeros(1, 144);
for i = 1:144
    VocList(i) = R.General.Paradigm.Trials(i).Stimulus.ParSequence.BaseFrequency;
end
% Find unique entries and their counts
[uniqueEntries, ~, entryIndices] = unique(VocList);
counts = hist(entryIndices, 1:numel(uniqueEntries));

% Display each entry and its count
disp('Entry   Count');
disp([uniqueEntries', counts']);