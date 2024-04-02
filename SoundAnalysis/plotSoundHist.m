function plotSoundHist(varargin)
P = parsePairs(varargin);
checkField(P, 'Variables', [0.8, 0.4, 2])
checkField(P, 'NumReal', 3);
checkField(P, 'Corrs', [0, 0.8]);
checkField(P, 'Vars', [0.02, 0.2, 0.4]);
checkField(P, 'NumBins', 100)
checkField(P, 'Title', 'Histogram TORC');
checkField(P, 'dB', 0)
checkField(P, 'FIG', 6)

    for Corr = 1:numel(P.Corrs)
        for Var = 1:numel(P.Vars)
            for Real = 1:P.NumReal
                filename = ['TORCNoise_corr', num2str(P.Corrs(Corr)),'_var', num2str(P.Vars(Var)), '_real', num2str(Real), '.mat'];
                WaveandFS=load(['/home/experimenter/dnp-backup/2pTestingJanek/TORCNoise/', filename]);
                Stimuli.(['corr', num2str(P.Corrs(Corr)*10),'_var', num2str(P.Vars(Var)*100), '_real', num2str(Real)]) = WaveandFS.NoiseWaveform;
            end
        end
    end
    
    Waveform = Stimuli.(['corr', num2str(P.Variables(1)*10),'_var', num2str(P.Variables(2)*100), '_real', num2str(P.Variables(3))]);
    NumBins = P.NumBins;
    duration = 10; % Duration of the white noise signal (seconds)
    Fs = 250000; % Sampling frequency (samples per second)
    WhiteNoise = randn(duration * Fs, 1);% Generate white noise signal
    MaxWN = max(abs(WhiteNoise));
    WhiteNoise = (abs(WhiteNoise) / MaxWN);
    %% Set figure
    MP = get(0,'MonitorPositions');
    NY = MP(1,end); HPixels = 540;
    FigureName=P.Title;
    Fig = figure(P.FIG); clf; set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1250,HPixels]);
    annotation('textbox','String', FigureName,'Position',[0.4,0.96,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    [~, AH] = axesDivide(2,3,[0.1, 0.1, 0.8, 0.8],0.3,0.6, 'c');
    AH = AH';
    for i = 1:length(P.Corrs)
        for j= 1:length(P.Vars)
            cAH = AH(i+(j-1)*2);
            Waveform = Stimuli.(['corr', num2str(P.Corrs(i)*10),'_var', num2str(P.Vars(j)*100), '_real', num2str(P.Variables(3))]);
            if P.dB
                SoundLevels = 20*log10(abs(Waveform));
                Noise = 20 * log10(abs(WhiteNoise));
            else
                SoundLevels = abs(Waveform);
                Noise = abs(WhiteNoise);
            end
            histogram(cAH, SoundLevels, NumBins);
            hold(cAH, 'on')
            histogram(cAH, Noise, NumBins, 'FaceColor', 'r');
            if P.dB
                xlabel(cAH, 'Sound Level (dB)');
                ylim(cAH, [0, 2.5*10^5]); 
                xlim(cAH, [-100, 0])
            else
                xlabel(cAH, 'Amplitude');
                ylim(cAH, [0, 10*10^5]);
                xlim(cAH, [0, 0.6])
            end
            ylabel(cAH, 'Frequency');
            if P.Corrs(i) > 0
                title(cAH, ['HighCFC var ', num2str(P.Vars(j))]);
            else
                title(cAH, ['lowCFC var ', num2str(P.Vars(j))]);
            end
            
        end
    end
    if P.dB
        legend({'TORC', 'White Noise'}, 'Location', 'southwest');
    else
        legend({'TORC', 'White Noise'}, 'Location', 'northeast');
    end
    



    


    