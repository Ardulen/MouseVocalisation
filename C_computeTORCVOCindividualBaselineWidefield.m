function [T, P, M] = C_computeTORCVOCindividualBaselineWidefield(R, varargin)

P = parsePairs(varargin);
checkField(P,'Animal'); 
checkField(P,'Recording'); 
checkField(P, 'Trials', 'All');
checkField(P, 'Corrs', [0, 0.8]);
checkField(P, 'Vars', [0.02, 0.2, 0.4]);
checkField(P, 'FR', 100);
checkField(P, 'WindowSize', 5);
checkField(P, 'IntAfterAvg', 1)
checkField(P, 'Mean', 1) % 1 for mean 0 for median

    T = struct;
    Time=R.Frames.TimeAvg;
    ImageSize = [size(R.Frames.AvgTime, 1), size(R.Frames.AvgTime, 2)]; 
     %% Vocalization Response
    Parameters.Corrs = R.General.Paradigm.Stimulus.Parameters.Correlations.Value;
    Parameters.Vars = R.General.Paradigm.Stimulus.Parameters.Variances.Value;
    Parameters.Reals = 1:R.General.Paradigm.Stimulus.Parameters.NRealizations.Value;
    Parameters.NTrials = R.General.Paradigm.Trial;
    Parameters.PreTimes = R.General.Paradigm.Stimulus.Parameters.DurContext.Value;
    Parameters.VocFreqs = R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value;
    Parameters.VocFreqsSil = R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value;
    
    fprintf('\n');
    VocStartFrame = zeros(1, length(Parameters.PreTimes));
        
    T.VocResp.FullResp = zeros([ImageSize(1), ImageSize(2), numel(Parameters.Corrs), numel(Parameters.Vars), numel(Parameters.Reals), numel(Parameters.VocFreqs), numel(Parameters.PreTimes)-1]);
    T.VocResp.SEM = zeros([ImageSize(1), ImageSize(2), size(R.Frames.AvgTime, 3), numel(Parameters.Corrs), numel(Parameters.Vars), numel(Parameters.Reals), numel(Parameters.VocFreqs), numel(Parameters.PreTimes)-1]);
    T.DiffAvg = zeros([ImageSize(1), ImageSize(2), size(R.Frames.AvgTime, 3), numel(Parameters.Corrs), numel(Parameters.Vars), numel(Parameters.Reals), numel(Parameters.VocFreqs), numel(Parameters.PreTimes)-1]);
    for j = 1:numel(Parameters.Corrs)
        for k = 1:numel(Parameters.Vars)
            for q = 1:numel(Parameters.Reals)
                BaseTrialNums = GetTrialNums(Parameters.Corrs(j), Parameters.Vars(k), Parameters.Reals(q), R.General, 0, Parameters.NTrials, Parameters.PreTimes(end), Parameters.VocFreqs);
                for p = 1:numel(Parameters.VocFreqs)
                    fprintf(['Calculating Corr: ', num2str(Parameters.Corrs(j)), ', Var: ', num2str(Parameters.Vars(k)), ', Realization: ', num2str(Parameters.Reals(q)), ', VocFreq: ', num2str(Parameters.VocFreqs(p)), ', Pretime: ']);
                    for i =1:length(Parameters.PreTimes)-1
                        printupdate(i,length(Parameters.PreTimes)-1,i==1);
                        VocStartFrame(i) = (2+Parameters.PreTimes(i))*P.FR;
                        TrialNums = GetTrialNums(Parameters.Corrs(j), Parameters.Vars(k), Parameters.Reals(q), R.General, 0, Parameters.NTrials, Parameters.PreTimes(i), Parameters.VocFreqs(p));
                        [T.VocResp.FullResp(:, :, j, k, q, p, i), T.VocResp.SEM(:, :, :, j, k, q, p, i), T.DiffAvg(:, :, :, j, k, q, p, i)] = calcVocRespPerTrialBaseline(R, TrialNums, BaseTrialNums, VocStartFrame, ImageSize, P.Mean);
                    end
                    fprintf(repmat('\b', 1, numel(['Calculating Corr: ', num2str(Parameters.Corrs(j)), ', Var: ', num2str(Parameters.Vars(k)), ', Realization: ', num2str(Parameters.Reals(q)), ', VocFreq: ', num2str(Parameters.VocFreqs(p)), ', Pretime: i / i'])));
                end
            end
        end
    end
    fprintf('\nAveraging data');
    if P.IntAfterAvg
        if P.Mean
            T.VocResp.PreTime = squeeze(mean(mean(mean(mean(T.VocResp.FullResp, 3), 4), 5), 6));
            T.VocResp.Corrs = squeeze(mean(mean(mean(T.VocResp.FullResp, 4), 5), 6));
            T.VocResp.Vars = squeeze(mean(mean(mean(T.VocResp.FullResp, 3), 5), 6));
            T.VocResp.Reals = squeeze(mean(mean(mean(T.VocResp.FullResp, 3), 4), 6));
            T.VocResp.VocFreqs = squeeze(mean(mean(mean(T.VocResp.FullResp, 3), 4), 5));
        else
            T.VocResp.PreTime = squeeze(median(median(median(median(T.VocResp.FullResp, 3), 4), 5), 6));
            T.VocResp.Corrs = squeeze(median(median(median(T.VocResp.FullResp, 4), 5), 6));
            T.VocResp.Vars = squeeze(median(median(median(T.VocResp.FullResp, 3), 5), 6));
            T.VocResp.Reals = squeeze(median(median(median(T.VocResp.FullResp, 3), 4), 6));
            T.VocResp.VocFreqs = squeeze(median(median(median(T.VocResp.FullResp, 3), 4), 5));
        end            
        Params = {'Corrs', 'Vars', 'Reals', 'VocFreqs'};
        for i = 1:numel(Params)
            % Get the size of the original array
            originalSize = size(T.VocResp.(Params{i}));

            % Reshape the array
            T.VocResp.(Params{i}) = reshape(T.VocResp.(Params{i}), [originalSize(1), originalSize(2), prod(originalSize(3:4))]);
        end
    else
        T.VocResp.PreTime = zeros([ImageSize(1), ImageSize(2), numel(Parameters.PreTimes)-1]);
        T.VocResp.Corrs = zeros([ImageSize(1), ImageSize(2), numel(Parameters.Corrs), numel(Parameters.PreTimes)-1]);
        T.VocResp.Vars = zeros([ImageSize(1), ImageSize(2), numel(Parameters.Vars), numel(Parameters.PreTimes)-1]);
        T.VocResp.Reals = zeros([ImageSize(1), ImageSize(2), numel(Parameters.Reals), numel(Parameters.PreTimes)-1]);
        T.VocResp.VocFreqs = zeros([ImageSize(1), ImageSize(2), numel(Parameters.VocFreqs), numel(Parameters.PreTimes)-1]);
        if P.Mean
            D.PreTime = squeeze(mean(mean(mean(mean(T.DiffAvg, 4), 5), 6), 7));
            D.Corrs = squeeze(mean(mean(mean(T.DiffAvg, 5), 6), 7));
            D.Vars = squeeze(mean(mean(mean(T.DiffAvg, 4), 6), 7));
            D.Reals = squeeze(mean(mean(mean(T.DiffAvg, 4), 5), 7));
            D.VocFreqs = squeeze(mean(mean(mean(T.DiffAvg, 4), 5), 6));
        else
            D.PreTime = squeeze(median(median(median(median(T.DiffAvg, 4), 5), 6), 7));
            D.Corrs = squeeze(median(median(median(T.DiffAvg, 5), 6), 7));
            D.Vars = squeeze(median(median(median(T.DiffAvg, 4), 6), 7));
            D.Reals = squeeze(median(median(median(T.DiffAvg, 4), 5), 7));
            D.VocFreqs = squeeze(median(median(median(T.DiffAvg, 4), 5), 6));        
        end
        for i = 1:numel(Parameters.PreTimes)-1
            VocStart = (2+Parameters.PreTimes(i))*P.FR;
            dat = VocStart:VocStart+10;
            for j = 1:ImageSize(1)
                for k = 1:ImageSize(2)
                    T.VocResp.PreTime(j, k, i) = trapz(dat, D.PreTime(j, k, dat, i));
                end
            end
        end
        
        
        Params = {'Corrs', 'Vars', 'Reals', 'VocFreqs'};
        for p = 1:numel(Params)
            for q = 1:numel(Parameters.(Params{p}))
                for i = 1:numel(Parameters.PreTimes)-1
                    VocStart = (2+Parameters.PreTimes(i))*P.FR;
                    dat = VocStart:VocStart+10;
                    for j = 1:ImageSize(1)
                        for k = 1:ImageSize(2)
                            T.VocResp.(Params{p})(j, k, q, i) = trapz(dat, D.(Params{p})(j, k, dat, q, i));
                        end
                    end
                end
            end
        end
        

%         for i = 1:numel(Params)
%             % Get the size of the original array
%             originalSize = size(T.VocResp.(Params{i}));
% 
%             % Reshape the array
%             T.VocResp.(Params{i}) = reshape(T.VocResp.(Params{i}), [originalSize(1), originalSize(2), prod(originalSize(3:4))]);
%         end
    end
        
    fprintf('\nCalculating full data array');
    for i = 1:(length(Parameters.PreTimes)-1)
        TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, Parameters.PreTimes(i), Parameters.VocFreqs);
        Data.Full(:, :, :, i) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
        SEM.Full(:, :, :, i) = 2*std(R.Frames.AvgTime(:, :, :, TrialNums),[],4)/sqrt(size(R.Frames.AvgTime(:, :, :, TrialNums),4));
    end
    
    FunCal = {'Parameters.Corrs', 'Parameters.Vars', 'Parameters.Reals', 'R.General', '0', 'Parameters.NTrials', 'Parameters.PreTimes(i)', 'Parameters.VocFreqs'};
    [Data.Corrs, SEM.Corrs] = calcDataArray('Corrs', numel(Parameters.Corrs), R, FunCal, ImageSize, Parameters);
    [Data.Vars, SEM.Vars] = calcDataArray('Vars', numel(Parameters.Vars), R, FunCal, ImageSize, Parameters);
    [Data.Reals, SEM.Reals] = calcDataArray('Reals', numel(Parameters.Reals), R, FunCal, ImageSize, Parameters);
    [Data.VocFreqs, SEM.VocFreqs] = calcDataArray('VocFreqs', numel(Parameters.VocFreqs), R, FunCal, ImageSize, Parameters);
        
    for i= 1:(length(Parameters.PreTimes)-1)
        TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 1, Parameters.NTrials, Parameters.PreTimes(i), Parameters.VocFreqs);
        SEM.Full(:, :, :, i+length(Parameters.PreTimes)-1) = 2*std(R.Frames.AvgTime(:, :, :, TrialNums),[],4)/sqrt(size(R.Frames.AvgTime(:, :, :, TrialNums),4));
    end    
    [T.VocResp.Sil, Data.Full(:, :, :, 4:6)] = calcRespMaps(ImageSize, Parameters, 'Par', R, VocStartFrame, 1, 50, 0);
    [T.VocResp.VocFreqsSil, ~] = calcRespMaps(ImageSize, Parameters, 'VocFreqs', R, VocStartFrame, '1', 50, 0); 
    FunCal = {'Parameters.Corrs', 'Parameters.Vars', 'Parameters.Reals', 'R.General', '1', 'Parameters.NTrials', 'Parameters.PreTimes(i)', 'Parameters.VocFreqs'};
    [Data.VocFreqsSil, SEM.VocFreqsSil] = calcDataArray('VocFreqs', numel(Parameters.VocFreqs), R, FunCal, ImageSize, Parameters);


    %% Summary picture
    fprintf('\nCalulcating Summary maps')
    % Maximum Texture Response

    TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, Parameters.PreTimes, Parameters.VocFreqs);
    Data.Summary(:, :, :, 1) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
    SEM.Summary(:, :, :, 1) = 2*std(R.Frames.AvgTime(:, :, :, TrialNums),[],4)/sqrt(size(R.Frames.AvgTime(:, :, :, TrialNums),4));
    T.TexResp = 100*squeeze(max(Data.Summary(:, :, 2*P.FR:1:2.5*P.FR, 1), [], 3));
    % Sustained level using Pretimes 3 and 5

    TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, [3, 5], Parameters.VocFreqs);
    Data.Summary(:, :, :, 2) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
    SEM.Summary(:, :, :, 2) = 2*std(R.Frames.AvgTime(:, :, :, TrialNums),[],4)/sqrt(size(R.Frames.AvgTime(:, :, :, TrialNums),4));
    T.SusLvl = 100*squeeze(median(Data.Summary(:, :, 4*P.FR:1:5*P.FR, 2), 3));

    % vocalisation offset reponse

    [T.VocResp.OffsetSil, Data.OffsetVocSil] = calcRespMaps(ImageSize, Parameters, 'Par', R, VocStartFrame, 1, 50, 1);


    % sound offset response

    Data.OffsetResp = zeros([ImageSize, length(Time), (length(Parameters.PreTimes)-1)*2]);
    T.OffsetResp = zeros([ImageSize, length(Parameters.PreTimes)-1]);
    AvgMovMed = zeros([ImageSize, size(R.Frames.AvgTime, 3)]);
    for i =1:2:(length(Parameters.PreTimes)-1)*2
       oddindex = i/2+0.5;
       FunCal = {Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, Parameters.PreTimes(oddindex), Parameters.VocFreqs};
       VocStartFrame(oddindex) = (2+Parameters.PreTimes(oddindex))*P.FR;
       TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, Parameters.PreTimes(oddindex), Parameters.VocFreqs);
       TexBaseline = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
       [AvgMovMed, T.OffsetResp(:, :, oddindex), Data.OffsetResp(:, :, :, i)] = calcPeakSize(AvgMovMed, FunCal, ImageSize, VocStartFrame(oddindex), TexBaseline, 50, R, 1);              
       Data.OffsetResp(:, :, :, i+1) = AvgMovMed;
    end   


    %% Calculate decay maps
    fprintf('\nCalulcating Decay maps')
    DataDims = size(Data.Summary(:, :, 2.21*P.FR:1:5*P.FR, 2));


    MovMedian = movmedian(squeeze(Data.Summary(:, :, 2.21*P.FR:1:5*P.FR, 2)), 25, 3);
    [MedianMin, MedIndices] = min(MovMedian, [], 3);
    a0 = [0, 5, 0];
    options = optimoptions('lsqnonlin', 'Display', 'off');
    As = zeros(DataDims(1), DataDims(2));
    for i = 1:DataDims(1)
        for j = 1:DataDims(2)
                DecayTimeStop = MedIndices(i, j);
                if DecayTimeStop > 4
                    x=(1:(DecayTimeStop+1))'./P.FR;
                    y = double(squeeze(Data.Summary(i, j, 2.21*P.FR:2.21*P.FR+DecayTimeStop, 2)));
                    fun=@(a)a(1)*exp(-a(2)*x)+a(3) - y;
                    a = lsqnonlin(fun, a0, [], [], options);
                    As(i, j) = 1./a(2);
                else 
                    As(i, j) = NaN;
                end
        end
    end
    T.FitDecMap = As;
    T.DecayMap = 0.2+MedIndices./P.FR;
    T.Parameters = Parameters;
    T.Data = Data;
    T.SEM = SEM;
    M = struct;
    M.Metrics.Mean.TexResp = double(T.TexResp);
    M.Metrics.Mean.TexVocResp = mean(T.VocResp.PreTime, 3);
    M.Metrics.Mean.SilVocResp = mean(T.VocResp.Sil, 3);
    M.Metrics.Mean.SilVocOffset = mean(T.VocResp.OffsetSil, 3);
    M.Metrics.Mean.OffsetResp = mean(T.OffsetResp, 3);
    M.Metrics.Mean.SusLvl = double(T.SusLvl);
    M.Metrics.Mean.FitDecMap = T.FitDecMap;
    
    
end  