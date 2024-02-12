function [AvgMovMed, Resp, Data] = calcPeakSize(MovingMed, FunCal, ImageSize, VocStartFrame, TexBaseline, WindowSize, R, Sil)              
    AvgMovMed = MovingMed;
    Resp = zeros([ImageSize(1), ImageSize(2)]);
    TrialNums = GetTrialNums(FunCal{:});
    Data = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
    X = VocStartFrame:VocStartFrame+10;
    for k = 1:ImageSize(1)
        for q = 1:ImageSize(2)
            if strcmp(Sil, '1')
                AvgMovMed(k, q, :) = movmedian(squeeze(Data(k, q, :)), [WindowSize, 0]);
            else
                AvgMovMed(k, q, :) = medfilt1(squeeze(TexBaseline(k, q, :)), WindowSize);
            end
            Area1 = trapz(X, Data(k, q, VocStartFrame:VocStartFrame+10));
            Area2 = trapz(X, AvgMovMed(k, q, VocStartFrame:VocStartFrame+10));
            Resp(k, q) = 100*(Area1-Area2);
        end
    end

end