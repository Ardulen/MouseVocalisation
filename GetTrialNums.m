function TrialNums = GetTrialNums(Corrs, Vars, Reals, General, Sil, NTrials, PreTimes, VocFreqs)
% returns the Trialindices to be selected in Frames.AvgTime based on the
% given input parameters



TrialNums = [];
SearchStrings = [];
if Sil == 1
   SearchStrings = "Silence";
else
    for i = 1:length(Corrs)
        for j =1:length(Vars)
            for k = 1:length(Reals)
                SearchStrings = [SearchStrings, string(['TORCNoise_corr', num2str(Corrs(i)), '_var', num2str(Vars(j)), '_real', num2str(Reals(k))])];
            end
        end
    end
end
% Iterate through the struct
for i = 1:NTrials
    % Check if the 'basetexture' field contains 'searchString'
    if ismember(General.Paradigm.Trials(i).Stimulus.ParSequence.BaseTexture, SearchStrings)
        % If it does, add the corresponding recording index to the list
        if ismember(General.Paradigm.Trials(i).Stimulus.ParSequence.PreTime, PreTimes) 
            if ismember(General.Paradigm.Trials(i).Stimulus.ParSequence.VocFrequency, VocFreqs)
                TrialNums = [TrialNums, i];
            end
        end
    end
end
end