    function [Resp, Data] = calcRespMaps(ImageSize, Parameters, Par, R, VocStartFrame, Sil)
        Resp = zeros([ImageSize, length(Parameters.PreTimes)*length(Parameters.(Par))]);
        Data = zeros([ImageSize, size(R.Frames.AvgTime, 3), length(Parameters.PreTimes)*length(Parameters.(Par))]);
        FunCal = {'Parameters.Corrs', 'Parameters.Vars', 'Parameters.Reals', 'R.General', Sil, 'Parameters.NTrials', 'Parameters.PreTimes(i)', 'Parameters.VocFreqs'};
        RespIndex = find(strcmp(FunCal, ['Parameters.', Par]));
        FunCal(RespIndex) = strcat(FunCal(RespIndex), '(j)');
        for j = 1:length(Parameters.(Par))
            for i = 1:length(Parameters.PreTimes)
                MatIndex = (j-1)*length(Parameters.PreTimes)+i;
                for k =1:numel(FunCal)
                    SpecFunCal{k} = eval(FunCal{k});
                end    
                TrialNums = GetTrialNums(SpecFunCal{:});
                Data(:, :, :, MatIndex) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
                MaxVocResp = max(Data(:, :, VocStartFrame(i):VocStartFrame(i)+10, MatIndex), [], 3);
                PreVocLvl = Data(:, :, VocStartFrame(i), MatIndex);
                Resp(:, :, MatIndex) = 100*(MaxVocResp-PreVocLvl);
            end
        end
    end