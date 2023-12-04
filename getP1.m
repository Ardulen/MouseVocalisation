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