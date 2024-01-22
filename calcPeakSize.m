function [AvgMovMed, Resp, Data] = calcPeakSize(MovingMed, Response, FunCal, ImageSize, VocStartFrame, TexBaseline, WindowSize, RespIndex, R)              
    AvgMovMed = MovingMed;
    Resp = Response;
    TrialNums = GetTrialNums(FunCal{:});
    Data = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
    X = VocStartFrame:VocStartFrame+10;
    for k = 1:ImageSize(1)
        for q = 1:ImageSize(2)
            AvgMovMed(k, q, :) = medfilt1(squeeze(TexBaseline(k, q, :)), WindowSize);
            Area1 = trapz(X, Data(k, q, VocStartFrame:VocStartFrame+10));
            Area2 = trapz(X, AvgMovMed(k, q, VocStartFrame:VocStartFrame+10));
            Resp(k, q, RespIndex) = 100*(Area1-Area2);
        end
    end

end