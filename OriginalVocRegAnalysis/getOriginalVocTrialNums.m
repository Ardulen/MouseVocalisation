function TrialNums = getOriginalVocTrialNums(R, SearchString, PreTimes)
TrialNums = [];
% Iterate through the struct
for i = 1:144
    % Check if the 'BaseTexture' field contains 'searchString'
    if contains(R.General.Paradigm.Trials(i).Stimulus.ParSequence.BaseTexture, SearchString)
        % If it does, add the corresponding recording index to the list
        if ismember(R.General.Paradigm.Trials(i).Stimulus.ParSequence.PreTime, PreTimes) 
                TrialNums = [TrialNums, i];
        end
    end
end