function [TrialIndices, RecindexSil] = getTrialIndices(Corrs, Vars, R, PreTimes)
    General = R.General;
    size = length(Corrs)*length(Vars);
    NTrials = R.General.Paradigm.Trial;
    it = 1;
        for i = 1:length(Corrs)
            for j = 1:length(Vars)
                Recindex = GetRecIndex(Corrs(i), Vars(j), General, 0, NTrials, PreTimes);
                TrialIndices(:,it) = Recindex;
                it = it+1;
            end
        end
      
      RecindexSil = GetRecIndex(0, 0, General, 1, NTrials, PreTimes);
end
