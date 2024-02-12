function [Data, SEM] = calcDataArray(Par, ParNum, R, FunCal, ImageSize, Parameters)
    Data = zeros([ImageSize, size(R.Frames.AvgTime, 3), (length(Parameters.PreTimes)-1)*ParNum]);
    SEM = zeros([ImageSize, size(R.Frames.AvgTime, 3), (length(Parameters.PreTimes)-1)*ParNum]);
    RespIndex = find(strcmp(FunCal, ['Parameters.', Par]));
    FunCal(RespIndex) = strcat(FunCal(RespIndex), '(j)');
    for j = 1:length(Parameters.(Par))
        for i = 1:(length(Parameters.PreTimes)-1)
            MatIndex = (j-1)*(length(Parameters.PreTimes)-1)+i;
            for k =1:numel(FunCal)
                SpecFunCal{k} = eval(FunCal{k});
            end
            TrialNums = GetTrialNums(SpecFunCal{:});
            Data(:, :, :, MatIndex) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
            SEM(:, :, :, MatIndex) = 2*std(R.Frames.AvgTime(:, :, :, TrialNums),[],4)/sqrt(size(R.Frames.AvgTime(:, :, :, TrialNums),4));
        end
    end