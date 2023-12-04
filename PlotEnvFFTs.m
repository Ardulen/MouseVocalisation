function PlotEnvFFTs(Real)
    filename = {['TORCNoise_corr0_var0.02_real', Real, '.mat'], ['TORCNoise_corr0_var0.4_real', Real, '.mat'], ['TORCNoise_corr0.8_var0.02_real', Real, '.mat'], ['TORCNoise_corr0.8_var0.4_real', Real, '.mat']};
    CorrVar = GetCorrVar([0, 0.8], [0.02, 0.4]);
    figure;
    line_colors = [0, 1, 0; 0, 0, 1; 0, 0, 0; 1, 0, 0];
    hold on;
    for it = 1:4
        WaveandFS=load(['/home/experimenter/dnp-backup/2pTestingJanek/TORCNoise/', filename{it}]);
        NoiseWaveform = WaveandFS.NoiseWaveform;
        [audio_filts, audio_cutoffs_Hz] = make_constQ_cos_filters(length(NoiseWaveform), 250000, 30, 2000, 64000, 8);
        subbands = generate_subbands(NoiseWaveform, audio_filts);
        subband_envs = abs(hilbert(subbands));
        [SubbandP1, SubbandFreqs] = getP1(subband_envs, 250000);
        SubbandP1Avg = squeeze(mean(SubbandP1, 2));
        plot(SubbandFreqs, SubbandP1Avg(:, 1), 'Color', line_colors(it, :), 'LineWidth', 1.5);
    end
    ylabel('Relative P');
    ylim([0, 0.014])
    xlim([0, 50]);
    xlabel('f (Hz)');
    legend(CorrVar);
    title(['Average Envelop FFTs Real ', Real])
    
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
    function CorrVar = GetCorrVar(Corrs, Vars)
        VarNum = length(Corrs)*length(Vars);
        CorrVar = {};
        for i = 1:length(Corrs)
            for j = 1:length(Vars)
                % Concatenate elements from both vectors into a string
                combination = ['Corr', num2str(Corrs(i)), 'Var', num2str(Vars(j))];
                % Add the combination to the cell array
                CorrVar = [CorrVar, combination];
            end
        end
    end

end