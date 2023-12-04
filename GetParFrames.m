     function ParFrames = GetParFrames(TrialIndices, AvgImage)
        Len = length(TrialIndices);
        Wid = length(TrialIndices(1, :));
        ImageSize = size(AvgImage);
        ParFrames = zeros(ImageSize(1), ImageSize(2), ImageSize(3), Len, Wid);
        for i = 1:length(TrialIndices(1, :))
            TempAvg = AvgImage(:, :, :, TrialIndices(:, i));
            ParFrames(:,:,:, :, i) = TempAvg;
        end
     end