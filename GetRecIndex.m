function RecIndex = GetRecIndex(corr, var, General, Sil, NTrials, PreTimes)

RecIndex = [];

if Sil == 1
   searchString = ['Silence'];
else
   searchString = ['corr', num2str(corr), '_var', num2str(var)];
end
% Iterate through the struct
for i = 1:NTrials
    % Check if the 'basetexture' field contains 'searchString'
    if contains(General.Paradigm.Trials(i).Stimulus.ParSequence.BaseTexture, searchString)
        % If it does, add the corresponding recording index to the list
        if ismember(General.Paradigm.Trials(i).Stimulus.ParSequence.PreTime, PreTimes) 
            RecIndex = [RecIndex, i];
        end
    end
end
end
