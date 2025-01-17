function [Stim, Resp] = STRFPrep(R, varargin)
P = parsePairs(varargin);
checkField(P, 'Corr', 0);
checkField(P, 'Var', 0.02);
checkField(P, 'Reals', [1, 2, 3]);
checkField(P, 'PreTimes', [3, 5]);
checkField(P, 'VocFreqs', [4000, 8000, 32000])
checkField(P, 'Lag', 0.3:0.01:0.01);
checkField(P, 'AudioSR', 250000);
checkField(P, 'Animal', 'mouse193');
checkField(P, 'Recording', 201);
checkField(P, 'Source', 'VideoCalcium');
checkField(P, 'ROI', [1.8, 2.1, 0.05]);
checkField(P, 'RespSR', 100);
checkField(P, 'Circle', 1);
checkField(P, 'OnsetDelay', 50);
checkField(P, 'Frames', [200, 400]);
checkField(P, 'NumBins', 26);
checkField(P, 'CrossCorr', 1);
checkField(P, 'TORC', 1);
checkField(P, 'Fig', 1);

%     for Corr = 1:numel(P.Corrs)
%         for Var = 1:numel(P.Vars)
%             for Real = 1:P.NumReal
%                 filename = ['TORCNoise_corr', num2str(P.Corrs(Corr)),'_var', num2str(P.Vars(Var)), '_real', num2str(Real), '.mat'];
%                 WaveandFS=load(['/home/experimenter/dnp-backup/2pTestingJanek/TORCNoise/', filename]);
%                 Stimuli.(['corr', num2str(P.Corrs(Corr)*10),'_var', num2str(P.Vars(Var)*100), '_real', num2str(Real)]) = WaveandFS.NoiseWaveform;
%             end
%         end
%     end

    
    % create concatenated response
    %R = C_computeWidefield('Animal', P.Animal, 'Recording', P.Recording, 'FIG', 0);
    [X, Y, ~] = C_pixelToMM(P,R,R.Frames);
    
    
    [Ygrid, Xgrid] = meshgrid(Y,X);
    ROIMask = sqrt((Xgrid - P.ROI(1) ).^2 + (Ygrid - P.ROI(2) ).^2) <= P.ROI(3);
    OnsetFrame = find(R.Frames.TimeAvg >= R.General.Paradigm.Stimulus.Parameters.PreDuration.Value, 1, 'first');
    %OffsetFrame = find(R.Frames.TimeAvg >=R.Frames.TimeAvg(end)-R.General.Paradigm.Stimulus.Parameters.PreDuration.Value, 1, 'first');
    if P.TORC
        X = 5;
        Y = 5;
        Resp = [];
        Stim = [];
        for j = 1:length(P.PreTimes)
            TrialNums = GetTrialNums(P.Corr, P.Var, P.Reals, R.General, 0, size(R.Frames.AvgTime, 4), P.PreTimes(j), P.VocFreqs);
            MeasureFrame = P.OnsetDelay+1+OnsetFrame;
            EndFrame = OnsetFrame + P.Frames(j)+P.OnsetDelay;

            RespAll = zeros((EndFrame-MeasureFrame+1), numel(TrialNums));
            for i = 1:numel(TrialNums)
                Trial = R.Frames.AvgTime(:, :, :, TrialNums(i));
                ROI = Trial.*ROIMask;
                ROI(ROI == 0) = NaN;
                ROIAvg = squeeze(nanmean(nanmean(ROI,2),1)); 

                if P.Circle
                    RespAll(:, i) = ROIAvg(MeasureFrame:EndFrame);
                else
                    RespAll(:, i) = squeeze(Trial(80, 80, MeasureFrame:EndFrame));
                end
            end
            RespPart = NaN*zeros(size(RespAll));
            RespPart(:,1) = RespAll(:,1);
            for i=2:numel(TrialNums)
                RespPart(:,i) = RespAll(:,i) + (RespPart(end,i-1)-RespAll(1,i));
            end
            RespPart = RespPart- RespPart(1,1);
            StimPart = zeros(P.NumBins, numel(RespPart));
            for i = 1:numel(P.Reals)
                    filename = ['TORCNoise_corr', num2str(P.Corr),'_var', num2str(P.Var), '_real', num2str(P.Reals(i)), '.mat'];
                    WaveandFS=load(['/home/experimenter/dnp-backup/2pTestingJanek/TORCNoise/', filename]);
                    Waveform = WaveandFS.NoiseWaveform;
                    [Spect, PartTime]  = plotSpectrogram(Waveform', P.AudioSR, 'NumBins', P.NumBins);
                    RealPart = Spect(:, P.OnsetDelay+1:P.OnsetDelay+P.Frames(j));
                    %RealTime = PartTime(P.OnsetDelay+1:P.OnsetDelay+P.Frames);
                    StimPart(:, (i-1)*numel(RespPart)/numel(P.Reals)+1:i*numel(RespPart)/numel(P.Reals)) = repmat(RealPart, 1, numel(TrialNums)/numel(P.Reals));
                    %Time(1, (i-1)*numel(Resp)/3+1:i*numel(Resp)/numel(P.Reals)) = repmat(RealTime, 1, numel(TrialNums)/numel(P.Reals));
                    StimPart =  StimPart - mean(StimPart, 2);
            end
            Stim = [Stim, StimPart];
            Resp = [Resp; RespPart(:)];
        end
    else
        X = 5;
        Y = 2;
        TrialNums = 1:R.Frames.NTrials;
        WaveReps = cell2mat(struct2cell(R.General.Paradigm.Repetitions));
        WaveReps = WaveReps(:);
        RespAll = zeros([size(R.Frames.AvgTime, 3)-2, length(WaveReps)]);
        for i = 1:length(TrialNums)
            Trial = R.Frames.AvgTime(:, :, :, WaveReps(i));
            ROI = Trial.*ROIMask;
            ROI(ROI == 0) = NaN;
            ROIAvg = squeeze(nanmean(nanmean(ROI,2),1)); 

            if P.Circle
                RespAll(:, i) = ROIAvg(1:end-2);
            else
                RespAll(:, i) = squeeze(Trial(80, 80, :));
            end
        end
        Resp = NaN*zeros(size(RespAll));
        Resp(:,1) = RespAll(:,1);
        for i=2:numel(TrialNums)
            Resp(:,i) = RespAll(:,i) + (Resp(end,i-1)-RespAll(1,i));
        end
        Resp = Resp - Resp(1,1);
        Resp = Resp(:);
        %Resp = RespAll(:);
        Stim = zeros(P.NumBins, numel(Resp));
        for i=1:length(TrialNums)
            StimObject = R.General.Paradigm.Stimulus;
            StimObject.Update;
            Waveform = StimObject.Waveform(WaveReps(i));
            [Spect, PartTime]  = plotSpect(Waveform, P.AudioSR, 'NumBins', P.NumBins);
            Stim(:, (i-1)*(size(R.Frames.AvgTime, 3)-2)+1:i*(size(R.Frames.AvgTime, 3)-2)) = Spect;
        end
    end
    

    
    [bHigh,aHigh] = butter(2,[1]/(P.RespSR/2),'high');
    Resp = filter(bHigh,aHigh,Resp);
    Resp = Resp-mean(Resp);   
    
    
    if P.Fig
        figure;
        im = imagesc(1:numel(Resp), [0:0.2:5], Stim);
        set(gca, 'Ydir', 'normal');
        ylabel('Octaves');
        yticks([0:1:5]);
        %xticks(Time);
    end

    
    MP = get(0,'MonitorPositions');
    NY = MP(1,end); HPixels = 540;
    FigureName=' ';
    Fig = figure(1); clf; set(1,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1250,HPixels]);
    [~, AH] = axesDivide(X,Y,[0.1, 0.1, 0.8, 0.8],0.3,0.7, 'c');
    if P.CrossCorr
        for iF = 1:P.NumBins-1
            Corr = xcorr(Stim(iF,:)', Resp, 30, 'unbiased');
            plot(AH(iF), -300:10:300, Corr, 'LineWidth', 2)
            %ylim(AH(iF), [-0.15, 0.15])
            title(AH(iF), num2str(iF))
        end
    end

end

    