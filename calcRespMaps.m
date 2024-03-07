function [Resp, Data] = calcRespMaps(ImageSize, Parameters, Par, R, VocStartFrame, Sil, WindowSize, offset, VocFreqs, Relative)
    % calculates the vocalization response maps and data averaged over all
    % parameters except a selected parameter "Par" for the Pretimes present
    % in the data using the highest Pretime as baseline, if Sil == 1 Calculates the 
    % response averaged over all VocFreqs and Realizations for all silent
    % trials
    if Sil == 1
        Resp = zeros([ImageSize, length(Parameters.PreTimes)-1]);
        Data = zeros([ImageSize, size(R.Frames.AvgTime, 3), (length(Parameters.PreTimes)-1)]);
        for i = 1:(length(Parameters.PreTimes)-1)
            TrialNums = GetTrialNums(0, 0, 0, R.General, 1, Parameters.NTrials, Parameters.PreTimes(i), VocFreqs);
            Data(:, :, :, i) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
            X = VocStartFrame(i):VocStartFrame(i)+10;
            AvgMovMed = zeros([ImageSize, size(R.Frames.AvgTime, 3)]);
            for k = 1:ImageSize(1)
                for q = 1:ImageSize(2)
                    if offset == 0
                        AvgMovMed(k, q, :) = movmedian(squeeze(Data(k, q, :, i)), [WindowSize, 0]);
                        Area1 = trapz(X, Data(k, q, X, i));
                        Area2 = trapz(X, AvgMovMed(k, q, X));
                        Resp(k, q, round(i)) = 100*(Area1-Area2);
                    else
                        AvgMovMed(k, q, :) = medfilt1(squeeze(Data(k, q, :, i)), WindowSize);
                        OffStart = VocStartFrame(i)+10:20:VocStartFrame(i)+170;
                        OnStart = VocStartFrame(i):20:VocStartFrame(i)+160;
                        TotArea = 0;
                        for j = 1:numel(OffStart)
                            OffArea1 = trapz(X, Data(k, q, OffStart(j):OffStart(j)+10, i));
                            OffArea2 = trapz(X, AvgMovMed(k, q, OffStart(j):OffStart(j)+10));
                            OffDiff = 100*(OffArea1-OffArea2);
                            if Relative
                                OnArea1 = trapz(X, Data(k, q, OnStart(j):OnStart(j)+10, i));
                                OnArea2 = trapz(X, AvgMovMed(k, q, OnStart(j):OnStart(j)+10));
                                OnDiff = 100*(OnArea1-OnArea2);
                                TotArea = TotArea + (OnDiff-OffDiff)/(OnDiff+OffDiff);
                            else
                                TotArea = TotArea + OffDiff;
                            end
                        end
                        Resp(k, q, round(i)) = TotArea/7;
                    end
                end
            end
            %Data(:, :, :, i+1) = AvgMovMed;
        end  
    else
        Resp = zeros([ImageSize, length(Parameters.(Par)), (length(Parameters.PreTimes)-1)]);
        Data = zeros([ImageSize, size(R.Frames.AvgTime, 3), length(Parameters.PreTimes)*length(Parameters.(Par))]);
        FunCal = {'Parameters.Corrs', 'Parameters.Vars', 'Parameters.Reals', 'R.General', Sil, 'Parameters.NTrials', 'Parameters.PreTimes(i)', 'Parameters.VocFreqs'};
        RespIndex = find(strcmp(FunCal, ['Parameters.', Par]));
        FunCal(RespIndex) = strcat(FunCal(RespIndex), '(j)');
        for j = 1:length(Parameters.(Par))
            i = 4;
            for k =1:numel(FunCal)
                TexFunCal{k} = eval(FunCal{k});
            end
            TrialNums = GetTrialNums(TexFunCal{:});
            TexBaseline = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
            AvgMovMed = zeros([ImageSize, size(R.Frames.AvgTime, 3)]);
            for i = 1:(length(Parameters.PreTimes)-1)
                MatIndex = (j-1)*length(Parameters.PreTimes)+i;
                for k =1:numel(FunCal)
                    SpecFunCal{k} = eval(FunCal{k});
                end
                [AvgMovMed, Resp(:, :, j, i), Data(:, :, :, MatIndex)] = calcPeakSize(AvgMovMed, SpecFunCal, ImageSize, VocStartFrame(i), TexBaseline, WindowSize, R, Sil);              
            end
            Data(:, :, :, MatIndex+1) = AvgMovMed;
        end
    end
end