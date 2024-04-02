function [Spectrogram, Time] = plotSpect(x, fs, varargin)
P = parsePairs(varargin);
checkField(P, 'NumBins', 26);
checkField(P, 'FreqRange', [2000, 64000]);
checkField(P, 'TimeStep', 0.02);
checkField(P, 'Plot', 0);
checkField(P, 'FreqAdjust', 100);
checkField(P, 'Octaves', 0)
 
WindowSize = P.TimeStep*fs;
Overlap = WindowSize/2;
% Generate logarithmically spaced frequency bins
logFreqs = logspace(log10(P.FreqRange(1)), log10(P.FreqRange(2)), P.NumBins);

% Extend list by one logarithmic entry to serve as Bin limit
ratio = logFreqs(2) / logFreqs(1);
ExtraLogEntry = logFreqs(end) * ratio;
logFreqs = [logFreqs, ExtraLogEntry];

% Generate frequency axis
FRes = fs / WindowSize;
FAxis = (0:WindowSize-1) * FRes;

% Compute spectrogram
Spectrogram = zeros(P.NumBins, length(x)/WindowSize);
for i = 1:length(x)/Overlap-2
    %Start = i;
    Start = (i - 1) * Overlap + 1;
    End = Start+WindowSize-1;
    WindowedSignal = x(Start:End) .* hamming(WindowSize);
    fftResult = fft(WindowedSignal);
    for j = 1:length(logFreqs)-1
        BottomFreq = find(FAxis >= logFreqs(j)-P.FreqAdjust,1,'first');
        TopFreq = find(FAxis >= logFreqs(j+1)-P.FreqAdjust,1,'first');
        %BottomFreq = find(FAxis < round(logFreqs(j), -log10(100))-100, 1, 'last');
        %TopFreq = find(FAxis > round(logFreqs(j), -log10(100))+100, 1, 'first');
        Spectrogram(j, i) = sum(abs(fftResult(BottomFreq:TopFreq)));
    end
end

%MeanSpec = mean(Spectrogram, 2);
%Spectrogram = Spectrogram-MeanSpec;

Time = (WindowSize / 2 : Overlap : length(x) - WindowSize) / fs;
%Time = TimeStep:TimeStep:(length(x)/WindowSize*TimeStep);

% Plot spectrogram
if P.Plot
    

    YTicks = 0:0.2:5;
    figure;
    imagesc(Time, YTicks, Spectrogram);
    colormap('bone')
    axis xy;
    colorbar;


    % Labeling and title
    xlabel('Time (s)');
    ylabel('Octaves');
    if P.Octaves
        yticks(0:5);
    else
        yticks(0:5);
        Labels = num2cell(logFreqs(1:5:end-1));
        yticklabels(Labels)
    end
    title('Logarithmic Spectrogram');
end    
end