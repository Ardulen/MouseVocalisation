function [T, P, M] = C_computeTORCVOCindividualBaselineWidefield(R, varargin)

P = parsePairs(varargin);
checkField(P,'Animal'); 
checkField(P,'Recording'); 
checkField(P, 'Trials', 'All');
checkField(P, 'Corrs', [0, 0.8]);
checkField(P, 'Vars', [0.02, 0.2, 0.4]);
checkField(P, 'FR', 100);
checkField(P, 'WindowSize', 5);
checkField(P, 'IntPreAvg', 1)
checkField(P, 'Mean', 1) % 1 for mean 0 for median
checkField(P, 'Save', 0)
checkField(P, 'Source', 'VideoCalcium')
checkField(P, 'AllVocs', 0)

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
    for i =1:length(Parameters.PreTimes)-1
        VocStartFrame(i) = (2+Parameters.PreTimes(i))*P.FR;
    end
    %Onset/Offset Index per VocFreq
    T.VocResp.OnsetOffsetSilPerFreq = zeros([ImageSize, numel(Parameters.VocFreqs), numel(Parameters.PreTimes)-1]);
    for i = 1:numel(Parameters.VocFreqs)
        [T.VocResp.OnsetOffsetSilPerFreq(:, :, i, :), ~] = calcRespMaps(ImageSize, Parameters, 'Par', R, VocStartFrame, 1, 50, 1, Parameters.VocFreqs(i), 1);
    end  
    
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
    if P.IntPreAvg
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
%         Params = {'Corrs', 'Vars', 'Reals', 'VocFreqs'};
%         for i = 1:numel(Params)
%             % Get the size of the original array
%             originalSize = size(T.VocResp.(Params{i}));
% 
%             % Reshape the array
%             T.VocResp.(Params{i}) = reshape(T.VocResp.(Params{i}), [originalSize(1), originalSize(2), prod(originalSize(3:4))]);
%         end
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
            if P.AllVocs
                StartFrames = VocStart:20:VocStart+180;
                for j = 1:ImageSize(1)
                    for k = 1:ImageSize(2)
                        Area = 0;
                        for q = 1:numel(StartFrames)
                            dat = StartFrames(q):StartFrames(q)+10;                           
                            Area = Area + trapz(dat, D.PreTime(j, k, dat, i));
                        end
                        T.VocResp.PreTime(j, k, i) = Area/10;
                    end
                end
            else
                dat = VocStart:VocStart+10;
                for j = 1:ImageSize(1)
                    for k = 1:ImageSize(2)
                        T.VocResp.PreTime(j, k, i) = trapz(dat, D.PreTime(j, k, dat, i));
                    end
                end
            end
        end
        
        
        Params = {'Corrs', 'Vars', 'Reals', 'VocFreqs'};
        for p = 1:numel(Params)
            for q = 1:numel(Parameters.(Params{p}))
                for i = 1:numel(Parameters.PreTimes)-1
                    VocStart = (2+Parameters.PreTimes(i))*P.FR;
                    if P.AllVocs
                        StartFrames = VocStart:20:VocStart+180;
                        for j = 1:ImageSize(1)
                            for k = 1:ImageSize(2)
                                Area = 0;
                                for l = 1:numel(StartFrames)
                                    dat = StartFrames(l):StartFrames(l)+10;                           
                                    Area = Area + trapz(dat, D.(Params{p})(j, k, dat, q, i));
                                end
                                T.VocResp.(Params{p})(j, k, q, i) = Area/10;
                            end
                        end
                    else
                        dat = VocStart:VocStart+10;
                        for j = 1:ImageSize(1)
                            for k = 1:ImageSize(2)
                                T.VocResp.(Params{p})(j, k, q, i) = trapz(dat, D.(Params{p})(j, k, dat, q, i));
                            end
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
    [T.VocResp.Sil, Data.Full(:, :, :, 4:6)] = calcRespMaps(ImageSize, Parameters, 'Par', R, VocStartFrame, 1, 50, 0, Parameters.VocFreqs, 0);
    [T.VocResp.VocFreqsSil, ~] = calcRespMaps(ImageSize, Parameters, 'VocFreqs', R, VocStartFrame, '1', 50, 0, Parameters.VocFreqs, 0); 
    FunCal = {'Parameters.Corrs', 'Parameters.Vars', 'Parameters.Reals', 'R.General', '1', 'Parameters.NTrials', 'Parameters.PreTimes(i)', 'Parameters.VocFreqs'};
    [Data.VocFreqsSil, SEM.VocFreqsSil] = calcDataArray('VocFreqs', numel(Parameters.VocFreqs), R, FunCal, ImageSize, Parameters);


    %% Summary picture
    fprintf('\nCalulcating Summary maps')
    % Maximum Texture Response

    TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, Parameters.PreTimes, Parameters.VocFreqs);
    Data.Summary(:, :, :, 1) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
    SEM.Summary(:, :, :, 1) = 2*std(R.Frames.AvgTime(:, :, :, TrialNums),[],4)/sqrt(size(R.Frames.AvgTime(:, :, :, TrialNums),4));
    T.Summary.TexResp = 100*squeeze(max(Data.Summary(:, :, 2*P.FR:1:2.5*P.FR, 1), [], 3));
    % Sustained level using Pretimes 3 and 5

    TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, [3, 5], Parameters.VocFreqs);
    Data.Summary(:, :, :, 2) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
    SEM.Summary(:, :, :, 2) = 2*std(R.Frames.AvgTime(:, :, :, TrialNums),[],4)/sqrt(size(R.Frames.AvgTime(:, :, :, TrialNums),4));
    T.Summary.SusLvl = 100*squeeze(median(Data.Summary(:, :, 4*P.FR:1:5*P.FR, 2), 3));

    % vocalisation offset reponse

    [T.VocResp.OffsetSil, Data.OffsetVocSil] = calcRespMaps(ImageSize, Parameters, 'Par', R, VocStartFrame, 1, 50, 1, Parameters.VocFreqs, 0);
    % Onset/Offset response
    [T.VocResp.OnsetOffsetSil, ~] = calcRespMaps(ImageSize, Parameters, 'Par', R, VocStartFrame, 1, 50, 1, Parameters.VocFreqs, 1);

    
    % Voc offset response divided by VocFreq
    
    T.VocResp.OffsetSilPerFreq = zeros([ImageSize, numel(Parameters.VocFreqs), numel(Parameters.PreTimes)-1]);
    for i = 1:numel(Parameters.VocFreqs)
        [T.VocResp.OffsetSilPerFreq(:, :, i, :), ~] = calcRespMaps(ImageSize, Parameters, 'Par', R, VocStartFrame, 1, 50, 1, Parameters.VocFreqs(i), 0);
    end
    
    %Onset/Offset Index per VocFreq
    T.VocResp.OnsetOffsetSilPerFreq = zeros([ImageSize, numel(Parameters.VocFreqs), numel(Parameters.PreTimes)-1]);
    for i = 1:numel(Parameters.VocFreqs)
        [T.VocResp.OnsetOffsetSilPerFreq(:, :, i, :), ~] = calcRespMaps(ImageSize, Parameters, 'Par', R, VocStartFrame, 1, 50, 1, Parameters.VocFreqs(i), 1);
    end    
    
    % sound offset response

    Data.OffsetResp = zeros([ImageSize, length(Time), (length(Parameters.PreTimes)-1)*2]);
    OffsetResp = zeros([ImageSize, length(Parameters.PreTimes)-1]);
    AvgMovMed = zeros([ImageSize, size(R.Frames.AvgTime, 3)]);
    for i =1:2:(length(Parameters.PreTimes)-1)*2
       oddindex = i/2+0.5;
       FunCal = {Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, Parameters.PreTimes(oddindex), Parameters.VocFreqs};
       VocStartFrame(oddindex) = (2+Parameters.PreTimes(oddindex))*P.FR;
       TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, Parameters.PreTimes(oddindex), Parameters.VocFreqs);
       TexBaseline = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
       [AvgMovMed, OffsetResp(:, :, oddindex), Data.OffsetResp(:, :, :, i)] = calcPeakSize(AvgMovMed, FunCal, ImageSize, VocStartFrame(oddindex), TexBaseline, 50, R, 1);              
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
    T.Summary.FitDecMap = As;
    T.Summary.DecayMap = 0.2+MedIndices./P.FR;
    T.Summary.OffsetResp = mean(OffsetResp, 3);
    T.Summary.TexVocResp = mean(T.VocResp.PreTime, 3);
    T.Summary.SilVocResp = mean(T.VocResp.Sil, 3);
    T.Summary.SilVocOffset = mean(T.VocResp.OffsetSil, 3);
    T.Parameters = Parameters;
    T.Data = Data;
    T.SEM = SEM;
    M = struct;
    M.Metrics.Mean.TexResp = double(T.Summary.TexResp);
    M.Metrics.Mean.TexVocResp = T.Summary.TexVocResp;
    M.Metrics.Mean.SilVocResp = T.Summary.SilVocResp;
    M.Metrics.Mean.SilVocOffset = T.Summary.SilVocOffset;
    M.Metrics.Mean.OffsetResp = T.Summary.OffsetResp;
    M.Metrics.Mean.SusLvl = double(T.Summary.SusLvl);
    M.Metrics.Mean.FitDecMap = T.Summary.FitDecMap;
    
    [X, Y, PixelPerMM] = C_pixelToMM(P,R,R.Frames);
    M.Image.Xmm = X;
    M.Image.Ymm = Y;
    M.Image.PixelPerMM = PixelPerMM;
    M.Image.AnatomyFrame = R.Frames.AverageRaw;
    M.Image.CraniotomyMask = R.Frames.CraniotomyMask;
    M.Image.CraniotomyEllipsoid = R.Frames.CraniotomyEllipsoid;
    
    if P.Save
        
        folderPath = ['/home/experimenter/dnp-backup/ControllerData/', P.Animal, '/R', num2str(P.Recording), '/Results/'];

        % Save the variable to a MAT-file in the specified folder
        save(fullfile(folderPath, 'M.mat'), 'M');
    end
end  