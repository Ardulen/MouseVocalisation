function PlotRandomPeaksDecay()
% Parameters
numPeaks = 50;
numPoints = 100;
decayRate = 0.15;

Peaks = zeros(30, numPoints);
convolvedSignals = zeros(30, numPoints);
for j =1:30
    % Generate random peak positions and heights
    peakPositions = sort(randi([1, numPoints-1], 1, numPeaks));
    peakHeights = rand(1, numPeaks) * 0.5 + 0.5;

    % Generate random peaks
    peaks = zeros(1, numPoints);
    for i = 1:numPeaks
        peaks = peaks + peakHeights(i) * exp(-(1/(2*(0.1^2)))*(linspace(1, numPoints, numPoints)-peakPositions(i)).^2);
    end
    Peaks(j, :) = peaks;
    % Generate exponential decay
    exponentialDecay = exp(-decayRate * (1:numPoints));

    % Convolve peaks with exponential decay
    convolvedSignal = conv(peaks, exponentialDecay);
    convolvedSignals(j, :) = convolvedSignal(1:numPoints);
end
MeanPeaks = mean(Peaks, 1);
MeanConv = mean(convolvedSignals, 1);
[PeaksP1, PeakFreqs] = getP1(MeanPeaks', numPoints);
[ConvP1, ConvFreqs] = getP1(MeanConv', numPoints);

% Plot the results
figure(2);
subplot(5, 1, 1);
plot(MeanPeaks);
title('Random Peaks');

subplot(5, 1, 2);
plot(exponentialDecay);
title('Exponential Decay');

subplot(5, 1, 3);
plot(MeanConv);
title('Convolved Signal');
xlim([0, 100])


subplot(5, 1, 4);
plot(PeakFreqs, PeaksP1)
title('FFT peaks')

subplot(5, 1, 5);
plot(ConvFreqs, ConvP1);
title('FFT convolved')
    
    
    function [P1, frequencies] = getP1(Signal, Fs)
        WindowedSignal = Signal .* hann(length(Signal));
        fftImage = fft(WindowedSignal);
        N = length(WindowedSignal(:, 1));
        P2 = abs(fftImage/N);
        P1 = P2(1:N/2+1, :);
        P1(2:end-1, :) = 2*P1(2:end-1, :);
        TotalP = sum(P1);
        P1 = P1./TotalP;
        frequencies = linspace(0, Fs/2, N/2+1);
    end


end