function [TrialAvg, TORCNoiseSignal, T] = C_computeTORCWidefield(R, varargin)
    P = parsePairs(varargin);
    checkField(P,'CLim','Auto')
    checkField(P,'ROI',[1.14, 1.77, 0.2]); % [centerX centerY radius] in mm
    checkField(P,'Threshold',100)
    checkField(P,'FIG',1);
    checkField(P,'Lens','Nikon4X') % Usually set automatically by the Setup
    checkField(P,'FOV2PAngle',38); % Set the  Angle at which the 2P Field-Of-View is rotated
    checkField(P,'FOV2PSize',[0.8,0.8]); % Set the Size of the 2P Field-Of-View
    checkField(P,'Source','VideoCalcium'); % Choose the Source of the Data
    checkField(P, 'FR', 100);
    checkField(P,'Trials',[]); % Choose the Source of the Data
    checkField(P, 'Pl', [1, 3, 4, 6]); %dicides which parameters are shown
    checkField(P, 'Corrs', [0, 0.8]);
    checkField(P, 'Vars', [0.02, 0.2, 0.4]);
    checkField(P, 'Pretimes', [3, 5]);
    checkField(P, 'Scale', 2);
    checkField(P, 'Freq', 6);
    checkField(P, 'FreqLim', 3);

    T = struct;
    %% Create 5D matrix containing X x Y x time x Trial x CorrVar
    [TrialIndices, RecindexSil] = getTrialIndices(P.Corrs, P.Vars, R, P.Pretimes);
    ParFrames = GetParFrames(TrialIndices, R.Frames.AvgTime);
    load('/home/experimenter/dnp-backup/2pTestingJanek/TORCNoise/TORCNoise_corr0.8_var0.4_real3.mat');
    TORCNoiseSignal = NoiseWaveform;
    TrialAvg = squeeze(nanmean(ParFrames, 4));
    %% Calculate decay maps
    DataDims = size(TrialAvg(:, :, 2.21*P.FR:1:5*P.FR, :));

    
    MovMedian = movmedian(TrialAvg(:, :, 2.21*P.FR:1:5*P.FR, :), 25, 3);
    [MedianMin, MedIndices] = min(MovMedian, [], 3);
    MedIndices = squeeze(MedIndices);
    %P1t=prctile(O.TrialAvg(:, :, 2.21*O.P.FR:(2+O.minpretime)*O.P.FR, :),1, 3);
    %im = O.TrialAvg(:, :, 2.21*O.P.FR:(2+O.minpretime)*O.P.FR, :) <= P1t(:, :, 1, :);
    %dtime = zeros(length(im(:, 1, 1, 1)), length(im(1, :, 1, 1)), 1, length(im(1, 1, 1, :)));
    a0 = [0, 5, 0];
    options = optimoptions('lsqnonlin', 'Display', 'off');
    As = zeros(DataDims(1), DataDims(2), DataDims(4));
    for i = 1:DataDims(1)
        disp(i)
        for j = 1:DataDims(2)
            for k = 1:DataDims(4)
                %TimeIndex = find(im(i, j, :, k) == 1);
                %DecayTimeStop = TimeIndex(1);
                DecayTimeStop = MedIndices(i, j, k);
                if DecayTimeStop > 4
                    x=(1:(DecayTimeStop+1))'./P.FR;
                    y = squeeze(TrialAvg(i, j, 2.21*P.FR:2.21*P.FR+DecayTimeStop, k));
                    fun=@(a)a(1)*exp(-a(2)*x)+a(3) - y;
                    a = lsqnonlin(fun, a0, [], [], options);
                    As(i, j, k) = 1./a(2);
                    %dtime(i, j, 1, k) = TimeIndex(1);
                else 
                    As(i, j, k) = NaN;
                end
            end
        end
    end
    %dtime = squeeze(dtime);
    T.FitDecMap = As;
    %O.DecayMap = 0.2+dtime./O.P.FR;
    T.DecayMap = 0.2+MedIndices./P.FR;
    
    
end