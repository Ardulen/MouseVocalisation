function [Resp, Data] = calcRespMaps(ImageSize, Parameters, Par, R, VocStartFrame, Sil, WindowSize, offset)
    % calculates the vocalization response maps and data averaged over all
    % parameters except a selected parameter "Par" for the Pretimes present
    % in the data using the highest Pretime as baseline, if Sil == 1 Calculates the 
    % response averaged over all VocFreqs and Realizations for all silent
    % trials
    if Sil == 1
        Resp = zeros([ImageSize, length(Parameters.PreTimes)-1]);
        Data = zeros([ImageSize, size(R.Frames.AvgTime, 3), (length(Parameters.PreTimes)-1)*2]);
        for i = 1:2:(length(Parameters.PreTimes)-1)*2
            oddindex = i/2+0.5; % used to revert the odd numbers the loop is over back to integers for seperate indexing
            TrialNums = GetTrialNums(0, 0, 0, R.General, 1, Parameters.NTrials, Parameters.PreTimes(oddindex), Parameters.VocFreqs);
            Data(:, :, :, i) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
            X = VocStartFrame(oddindex):VocStartFrame(oddindex)+10;
            AvgMovMed = zeros([ImageSize, size(R.Frames.AvgTime, 3)]);
            for k = 1:ImageSize(1)
                for q = 1:ImageSize(2)
                    AvgMovMed(k, q, :) = medfilt1(squeeze(Data(k, q, :, i)), WindowSize);
                    if offset == 0
                        Area1 = trapz(X, Data(k, q, VocStartFrame(oddindex):VocStartFrame(oddindex)+10, i));
                        Area2 = trapz(X, AvgMovMed(k, q, VocStartFrame(oddindex):VocStartFrame(oddindex)+10));
                        Resp(k, q, round(oddindex)) = 100*(Area1-Area2);
                    else
                        SecStart = VocStartFrame(oddindex)+30:20:VocStartFrame(oddindex)+170;
                        TotArea = 0;
                        for j = 1:numel(SecStart)
                            Area1 = trapz(X, Data(k, q, SecStart(j):SecStart(j)+10, i));
                            Area2 = trapz(X, AvgMovMed(k, q, SecStart(j):SecStart(j)+10));
                            Diff = 100*(Area1-Area2);
                            TotArea = TotArea + Diff;
                        end
                        Resp(k, q, round(oddindex)) = TotArea/7;
                    end
                end
            end
            Data(:, :, :, i+1) = AvgMovMed;
        end  
    else
        Resp = zeros([ImageSize, (length(Parameters.PreTimes)-1)*length(Parameters.(Par))]);
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
                RespIndex = (j-1)*(length(Parameters.PreTimes)-1)+i;
                for k =1:numel(FunCal)
                    SpecFunCal{k} = eval(FunCal{k});
                end
                [AvgMovMed, Resp, Data(:, :, :, MatIndex)] = calcPeakSize(AvgMovMed, Resp, SpecFunCal, ImageSize, VocStartFrame(i), TexBaseline, WindowSize, RespIndex, R);              
%                 TrialNums = GetTrialNums(SpecFunCal{:});
%                 Data(:, :, :, MatIndex) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
%                 X = VocStartFrame(i):VocStartFrame(i)+10;
%                 for k = 1:ImageSize(1)
%                     for q = 1:ImageSize(2)
%                         AvgMovMed(k, q, :) = medfilt1(squeeze(TexBaseline(k, q, :)), WindowSize);
%                         Area1 = trapz(X, Data(k, q, VocStartFrame(i):VocStartFrame(i)+10, MatIndex));
%                         Area2 = trapz(X, AvgMovMed(k, q, VocStartFrame(i):VocStartFrame(i)+10));
%                         Resp(k, q, RespIndex) = 100*(Area1-Area2);
%                     end
%                 end

                        %MaxVocResp = max(Data(:, :, VocStartFrame(i):VocStartFrame(i)+10, MatIndex), [], 3);
                        %PreVocLvl = Data(:, :, VocStartFrame(i), MatIndex);
                        %Resp(:, :, MatIndex) = 100*(MaxVocResp-PreVocLvl);
            end
            Data(:, :, :, MatIndex+1) = AvgMovMed;
        end
    end
end