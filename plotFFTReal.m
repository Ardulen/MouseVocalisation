function plotFFTReal(Corr, Var)
    figure;
    hold on
    for i = 1:2
        WaveandFS=load(['/home/experimenter/dnp-backup/2pTestingJanek/TORCNoise/TORCNoise_corr', num2str(Corr), '_var', num2str(Var), '_real', num2str(i), '.mat']);
        Signal = WaveandFS.NoiseWaveform;
        Fs = WaveandFS.Fs;
        fftImage = fft(Signal);
        N = length(Signal);
        P2 = abs(fftImage/N);
        P1 = P2(1:N/2+1);
        P1(2:end-1) = 2*P1(2:end-1);
        TotalP = sum(P1);
        P1 = P1./TotalP;
        frequencies = linspace(0, Fs/2, N/2+1);

        plot(frequencies, P1);
    end
end