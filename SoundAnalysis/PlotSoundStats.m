function PlotSoundStats(Stats, P, Sound)


Headers = {'Low CFC Low Variance', 'High CFC High Variacnce'};
MP = get(0,'MonitorPositions');
NY = MP(1,end); HPixels = 600;
figure(P.FIG); clf; set(P.FIG,'Color',[1,1,1],'Position',[5,NY-HPixels-100,1500,HPixels]);

[~,AH] = axesDivide(4, 2, [0.02, 0.1, 0.9, 0.7], [], 1, 'c');
AH = AH';


for i = 1:2
    
    annotation('textbox','String',Headers{i},'Position',[0.4,0.85-((i-1)*0.45),0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);

    S = Stats{i};
    Waveform = Sound{i};
    
    
    %% subplot 1: Envelope mean & variance
    axes(AH(1+4*(i-1)));
    plot(S.audio_cutoffs_Hz(11:end), S.env_mean(11:end),'LineWidth',2);
    % ylabel('Envelope mean','FontSize',12);
    % yticks([0:max(S.env_mean)/4:max(S.env_mean)]);
    % yticklabels(round([0:max(S.env_mean)/4:max(S.env_mean)],2));
    % ylim([0, max(S.env_mean)*1.1])

    hold on
    % yyaxis right
    plot(S.audio_cutoffs_Hz(11:end),S.env_var(11:end),'LineWidth',2);
    %ylabel('Envelope variance','FontSize',12);
    yticks([0.02, 0.2, 0.4, 0.6]);
    %yticklabels(round([0:max(S.env_var)/4:max(S.env_var)],2));
    ylim([0, max([S.env_var(11:end), S.env_mean(11:end)])*1.5])

    xticks([4000, 16000, 32000, 48000, 64000])

    xticklabels([4, 16, 32, 48, 64]);
    xlabel('Cochlear channel (kHz)','FontSize',10,'FontName','Arial');
    %set(gca, 'XScale', 'log')
    xlim([2000, 64000])
    title('Envelope statistics'); axis square
    legend({'Mean', 'Variance'})

    %% subplot 2: Envelope correlations (C)
    axes(AH(2+4*(i-1)));
    colormap jet;
    EnvelopeCorr = S.env_C(11:end, 11:end);
    pcolor(EnvelopeCorr); caxis([-1,1]); axis ij; colorbar;
    xticks([1:5:length(S.audio_cutoffs_Hz(11:end))]);
    yticks([1:5:length(S.audio_cutoffs_Hz(11:end))]);
    xticklabels(S.audio_cutoffs_Hz(11:5:end)/1000);
    yticklabels(S.audio_cutoffs_Hz(11:5:end)/1000);

    h = colorbar;
    ylabel(h, 'Correlation')
    xlabel('Cochlear channel (kHz)','FontSize',10,'FontName','Arial');
    ylabel('Cochlear channel (kHz)','FontSize',10,'FontName','Arial');
    set(gca, 'YDir','normal');
    
    %b = get(gca,'XTickLabel');
    %set(gca,'XTickLabel',b,'FontName','Arial','fontsize',15);

    %b = get(gca,'YTickLabel');
    %set(gca,'YTickLabel',b,'FontName','Arial','fontsize',15);

    title('Envelope correlations across bands'); axis square
    %%
    axes(AH(3+4*(i-1)));
    Spect = C_generateSpectrogram(Waveform, 'SR', P.audio_sr, 'SRAnalysis', 250,'FreqRange',[0,80000]);
    selEnd = find(Spect.Time>=2,1);
    im = imagesc(Spect.Time(1:selEnd),Spect.Frequency/1000, Spect.Spectrogram(:,1:selEnd));
    xlabel('Time (s)'); ylabel('Frequency (kHz)'); title('Stimulus Spectrogram')
    set(gca, 'YDir','normal');
    
    caxis([0, 100])
    h = colorbar;
    ylabel(h, 'Power')
    drawnow;

    %%
    axes(AH(4+4*(i-1)));
    y = 1:size(S.mod_power(11:end), 1);
    im2 = imagesc(S.Hz_mod_cfreqs, y, S.mod_power(11:end, :));
    ylabel('Cochlear Channel (kHz)'); xlabel('Modulation Frequency (Hz)'); 
    title('Modulation power')
    set(gca, 'YDir','normal')
    yticks([1:5:length(S.audio_cutoffs_Hz(11:end))]);
    yticklabels(S.audio_cutoffs_Hz(11:5:end)/1000);
    b = colorbar;
    ylabel(b, 'Power')
end