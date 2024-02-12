function [PixelAvgArea, SEM, DiffAvg] = calcVocRespPerTrialBaseline(R, TrialNums, BaseTrialNums, VocStartFrame, ImageSize, Mean)
X = VocStartFrame:VocStartFrame+10;
PixelAvgArea = zeros([ImageSize(1), ImageSize(2)]);
DiffAvg = zeros([ImageSize(1), ImageSize(2), size(R.Frames.AvgTime, 3)]); 
SEM = zeros([ImageSize(1), ImageSize(2), size(R.Frames.AvgTime, 3)]);
for k = 1:ImageSize(1)
    for q = 1:ImageSize(2)
        TrialAvgArea = zeros([1, numel(TrialNums)]);
        TrialDiffAvg = zeros([size(R.Frames.AvgTime, 3), numel(TrialNums)]);
        SEMTrialAvgArea = zeros([size(R.Frames.AvgTime, 3), numel(TrialNums)]);
        for j = 1:numel(TrialNums)
            Peaks = zeros([1, numel(BaseTrialNums)]);
            Diffs = zeros([size(R.Frames.AvgTime, 3), numel(BaseTrialNums)]);
            for i = 1:numel(BaseTrialNums)
                Data = squeeze(R.Frames.AvgTime(k, q, :, TrialNums(j)));
                Baseline = squeeze(R.Frames.AvgTime(k, q, :, BaseTrialNums(i)));
                Diffs(:, i) = 100*(Data-Baseline);
                VocData = Data(X);
                VocBaseline = Baseline(X);
                AreaData = trapz(X, VocData);
                AreaBaseline = trapz(X, VocBaseline);
                Peaks(i) = AreaData-AreaBaseline;
            end
            if Mean
                TrialAvgArea(j) = mean(Peaks);
                TrialDiffAvg(:, j) = mean(Diffs, 2);
            else
                TrialAvgArea(j) = median(Peaks);
                TrialDiffAvg(:, j) = median(Diffs, 2);
            end
            SEMTrialAvgArea(:, j) = 2*std(Diffs, [], 2)/sqrt(size(Diffs, 2));
        end
        if Mean
            PixelAvgArea(k, q) = mean(TrialAvgArea);
            DiffAvg(k, q, :) = mean(TrialDiffAvg, 2);
        else
            PixelAvgArea(k, q) = median(TrialAvgArea);
            DiffAvg(k, q, :) = median(TrialDiffAvg, 2);
        end
        SEM(k, q, :) = 2*std(TrialAvgArea, [], 2)/sqrt(size(TrialAvgArea, 2));%+sqrt(sum((SEMTrialAvgArea)/size(SEMTrialAvgArea, 2)).^2);
    end
end