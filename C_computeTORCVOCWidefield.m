function [T, P] = C_computeTORCVOCWidefield(R, varargin)

P = parsePairs(varargin);
checkField(P,'Animal'); 
checkField(P,'Recording'); 
checkField(P, 'Trials', 'All');
checkField(P, 'Corrs', [0, 0.8]);
checkField(P, 'Vars', [0.02, 0.2, 0.4]);
checkField(P, 'FR', 100);

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

    for i =1:2
        T.VocResp.PreTime(:, :, :, i) = zeros([ImageSize, length(Parameters.PreTimes)]);
        T.VocResp.Sil(:, :, :, i) = zeros([ImageSize, length(Parameters.PreTimes)]);
    end
    Data.Full = zeros([ImageSize, length(Time), length(Parameters.PreTimes)]);
    Data.Sil = zeros([ImageSize, length(Time), length(Parameters.PreTimes)]);
    VocStartFrame = zeros(1, length(Parameters.PreTimes));

    
    for i =1:length(Parameters.PreTimes)
        TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, Parameters.PreTimes(i), Parameters.VocFreqs);
        Data.Full(:, :, :, i) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
        VocStartFrame(i) = (2+Parameters.PreTimes(i))*P.FR;
        [MaxVocResp, MaxVocIndex] = max(Data.Full(:, :, VocStartFrame(i):VocStartFrame(i)+10, i), [], 3);
        PreVocLvl = Data.Full(:, :, VocStartFrame(i), i);
        [PostVocLvl, PostVocIndex] = min(Data.Full(:, :, VocStartFrame(i)+5:VocStartFrame(i)+15, i), [], 3);
        T.VocResp.PreTime(:, :, i, 1) = 100*(MaxVocResp-PreVocLvl);
        a = sqrt((MaxVocResp-PreVocLvl).^2+(VocStartFrame(i)-MaxVocIndex).^2);
        b = sqrt((PostVocIndex-VocStartFrame(i)).^2+(PostVocLvl-PreVocLvl).^2);
        c = sqrt((MaxVocResp-PostVocLvl).^2+(PostVocIndex-MaxVocIndex).^2);
        s = (a+b+c)./2;
        T.VocResp.PreTime(:, :, i, 2) = 100*sqrt(s.*(s-a).*(s-b).*(s-c));
        TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 1, Parameters.NTrials, Parameters.PreTimes(i), Parameters.VocFreqs);
        Data.Full(:, :, :, i+4) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
        T.VocResp.Sil(:, :, i, 1) = 100*(max(Data.Full(:, :, VocStartFrame(i):VocStartFrame(i)+10, i+4), [], 3)-Data.Full(:, :, VocStartFrame(i), i+4));
        [MaxVocResp, MaxVocIndex] = max(Data.Full(:, :, VocStartFrame(i):VocStartFrame(i)+10, i+4), [], 3);
        PreVocLvl = Data.Full(:, :, VocStartFrame(i), i+4);
        [PostVocLvl, PostVocIndex] = min(Data.Full(:, :, VocStartFrame(i)+5:VocStartFrame(i)+15, i+4), [], 3);
        a = sqrt((MaxVocResp-PreVocLvl).^2+(VocStartFrame(i)-MaxVocIndex).^2);
        b = sqrt((PostVocIndex-VocStartFrame(i)).^2+(PostVocLvl-PreVocLvl).^2);
        c = sqrt((MaxVocResp-PostVocLvl).^2+(PostVocIndex-MaxVocIndex).^2);
        s = (a+b+c)./2;
        T.VocResp.Sil(:, :, i, 2) = 100*sqrt(s.*(s-a).*(s-b).*(s-c));
    end

   
   
   %% Vocalization response by correlations
   [T.VocResp.Corrs, Data.Corrs] = calcRespMaps(ImageSize, Parameters, 'Corrs', R, VocStartFrame, '0');
   %% Vocalization response by Realization
   [T.VocResp.Reals, Data.Reals] = calcRespMaps(ImageSize, Parameters, 'Reals', R, VocStartFrame, '0');
   %% Vocalization response by Variance
   [T.VocResp.Vars, Data.Vars] = calcRespMaps(ImageSize, Parameters, 'Vars', R, VocStartFrame, '0');
   %% Vocalization response by Vocalization Frequency
   [T.VocResp.VocFreqs, Data.VocFreqs] = calcRespMaps(ImageSize, Parameters, 'VocFreqs', R, VocStartFrame, '0');
   %% Vocalization response by Vocalization Frequency without texture
   [T.VocResp.VocFreqsSil, Data.VocFreqsSil] = calcRespMaps(ImageSize, Parameters, 'VocFreqs', R, VocStartFrame, '1');
   %% Summary picture
   
   % Maximum Texture Response
   
   TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, Parameters.PreTimes, Parameters.VocFreqs);
   Data.Summary(:, :, :, 1) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
   T.TexResp = 100*squeeze(max(Data.Summary(:, :, 2*P.FR:1:2.5*P.FR, 1), [], 3));
   % Sustained level using Pretimes 3 and 5
   
   TrialNums = GetTrialNums(Parameters.Corrs, Parameters.Vars, Parameters.Reals, R.General, 0, Parameters.NTrials, [3, 5], Parameters.VocFreqs);
   Data.Summary(:, :, :, 2) = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
   T.SusLvl = 100*squeeze(median(Data.Summary(:, :, 4*P.FR:1:5*P.FR, 2), 3));

    
    %% Calculate decay maps
    DataDims = size(Data.Summary(:, :, 2.21*P.FR:1:5*P.FR, 2));

    
    MovMedian = movmedian(squeeze(Data.Summary(:, :, 2.21*P.FR:1:5*P.FR, 2)), 25, 3);
    [MedianMin, MedIndices] = min(MovMedian, [], 3);
    a0 = [0, 5, 0];
    options = optimoptions('lsqnonlin', 'Display', 'off');
    As = zeros(DataDims(1), DataDims(2));
    for i = 1:DataDims(1)
        disp(i)
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
end




