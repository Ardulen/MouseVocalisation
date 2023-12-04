function PlotAvgTexResp(ParFrames, Corrs, Vars, R, minpretime, pl, NoiseWaveform, varargin)
    
    P = parsePairs(varargin);
    checkField(P,'ROI',[1.3, 1.2, 0.2]); % [centerX centerY radius] in mm
    checkField(P,'FIG',1);
    checkField(P,'Lens','Nikon4X') % Usually set automatically by the Setup
    checkField(P,'Source','VideoCalcium'); % Choose the Source of the Data
    checkField(P,'FigSavePath',[]);
    checkField(P,'Trials',[]); 
    checkField(P, 'Animal');
    checkField(P, 'Recording');
    checkField(P, 'FR', 100);
    checkField(P, 'MaxFrame', 0) % if set to 1 displays the Frame at which response is maximal, 
                                    %if set to 0 displays the maximum value each pixel reaches 0.5 sec after texture onset
    
    VarNum = length(Corrs)*length(Vars);
    CorrVar = {};
    for i = 1:length(Corrs)
        for j = 1:length(Vars)
        % Concatenate elements from both vectors into a string
            combination = ['Corr', num2str(Corrs(i)), ' Var', num2str(Vars(j))];
        % Add the combination to the cell array
            CorrVar = [CorrVar, combination];
        end
    end
    
    function ROIMask = findROIMask(Y, X, P)
      [YGrid, XGrid] = meshgrid(Y,X);
      ROIMask = sqrt((XGrid - P.ROI(1) ).^2 + (YGrid - P.ROI(2) ).^2) <= P.ROI(3);
      if strcmp(P.Source,'VideoCalcium')
        ROIMask = ROIMask';
      end
    end

    function redrawCircle(P)
      Steps = linspace(0,2*pi,100);
      CircleC = P.ROI(3) * exp(Steps*sqrt(-1));
      CircleX = real(CircleC) + P.ROI(1);
      CircleY = imag(CircleC) + P.ROI(2);
      plot(CircleX,CircleY,'Color','k','LineWidth',1.5);
    end

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

    
    MP = get(0,'MonitorPositions');
    NY = MP(1,end); HPixels = 525;
    FigureName=[P.Animal,' R',num2str(P.Recording),' Texture Response'];
    figure(P.FIG); clf; set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1350,HPixels]);
    
    line_colors = [0.5, 0.5, 1; 0, 0, 1; 1, 0.5, 0.5; 1, 0, 0];
    line_styles = [':', "-", ':', "-"];
    CM = HF_colormap({[0,0,1],[1,1,1],[1,0,0]});
    
    AH(1)=axes('position',[0.02,0.60,0.20,0.25]);
    AH(2)=axes('position',[0.02,0.10,0.20,0.25]);
    AH(3)=axes('position',[0.20,0.60,0.20,0.25]);
    AH(4)=axes('position',[0.20,0.10,0.20,0.25]);
    AH(5)=axes('position',[0.42,0.60,0.20,0.30]);
    AH(6)=axes('position',[0.42,0.10,0.20,0.30]); 
    AH(7)=axes('position',[0.69,0.60,0.20,0.30]);
    AH(8)=axes('position',[0.69,0.10,0.20,0.30]);
    annotation('textbox','String',FigureName,'Position',[0.3,0.95,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    %% pixels to mm transformation  
    [X, Y, PixelPerMM] = C_pixelToMM(P,R,R.Frames);
    %O.PixelPerMM = PixelPerMM;
    %O.X = X; O.Y = Y;

    
    %% plot largest Text response map
    if P.MaxFrame == 1        
        TrialAvg = squeeze(nanmean(ParFrames, 4));
        TrialImageAvg = squeeze(nanmean(nanmean(TrialAvg, 1), 2));
        [MaxResp, MaxTime] = max(TrialImageAvg(200:1:250, :));
        MaxTexResp = TrialAvg(:, :, 200+MaxTime, :);  
    for i = 1:4
        axes(AH(i));
        hold on;
        CMax = imagesc(X, Y,100*MaxTexResp(:, :, pl(i), pl(i)));
        CMax.AlphaData = R.Frames.CraniotomyMask.*1; 
        set(gca,'YDir','reverse','DataAspectRatio',[1,1,1])
        Clim = 100*max(MaxTexResp, [], 'all');
        caxis([-2, Clim]);
        colormap(jet)
        colorbar;
        ylabel(colorbar, 'Change norm. (%)');
        ylabel('Mediolateral (mm)'); xlabel('Anteroposterior (mm)');
        title(CorrVar(pl(i)));
        redrawCircle(P);
        ylim([min(Y), max(Y)]);
        xlim([min(X), max(X)]);
        hold off;

    end
    end
    %% plot largest dip after tex response map
    if P.MaxFrame == 0        
        TrialAvg = squeeze(nanmean(ParFrames, 4));
        TexResp = TrialAvg(:, :, 200:1:250, :);
        MaxTexResp = squeeze(max(TexResp, [], 3));
    for i =1:4
        axes(AH(i));
        hold on;
        CMax = imagesc(X, Y,100*MaxTexResp(:, :, pl(i)));
        CMax.AlphaData = R.Frames.CraniotomyMask.*1; 
        set(gca, 'Ydir', 'reverse')
        Clim = 100*max(MaxTexResp, [], 'all');
        caxis([-2, Clim]);
        colormap(jet);
        colorbar;
        ylabel(colorbar, 'Change norm. (%)');
        axis square;
        ylabel('Mediolateral (mm)'); xlabel('Anteroposterior (mm)');
        title(CorrVar(pl(i)));
        redrawCircle(P);
        ylim([min(Y), max(Y)]);
        xlim([min(X), max(X)]);
        hold off;
    end
    end
    %% plot Traces
    axes(AH(5));
    Time = R.Frames.TimeAvg;
    ROIMask = findROIMask(X, Y, P);
    ROIAll = TrialAvg.*ROIMask;
    ROIAll(ROIAll==0) = NaN;
    AvgImage = squeeze(nanmean(nanmean(ROIAll,2),1));
    Xshade = 2.2:0.1:3;
    Yshade = 100*ones(size(Xshade));
    hold on;
    area(Xshade,Yshade, -100,'FaceColor',[0.9,0.9,1],'EdgeColor','None','HitTest','Off', 'HandleVisibility', 'Off');
    for i =1:length(pl)
        plot(Time, 100*AvgImage(:, pl(i)), 'Color', line_colors(i, :), 'Linewidth', 1.5, 'Linestyle', line_styles(i));
    end
    plot([2, 2],[-1000,1000],'-','Color','k');
    hold off;
    xlim([1.8, minpretime+2]);
    ylim([-8, 6]);
    xlabel('time (s)');
    ylabel('Change norm. (%)')
    title('Averages over ROI')
    
    %% plot fft
    axes(AH(6))
    [P1, frequencies] = getP1(AvgImage(220:1:300, :), P.FR);
    hold on;
    Area = zeros(1, length(pl));
    for i =1:length(pl)
        plot(frequencies, P1(:, pl(i)), 'Color', line_colors(i, :), 'Linestyle', line_styles(i), 'Linewidth', 1.5);
        Area(i) = trapz(frequencies, P1(:, pl(i)));
        targetArea = 0.8 * Area(i);
        cumulativeSum = cumtrapz(frequencies, P1(:, pl(i)));
        xThreshold = interp1(cumulativeSum, frequencies, targetArea);
        disp(Area(i));
        %plot([xThreshold, xThreshold], [-1000, 1000], 'Color', line_colors(i, :), 'Linestyle', line_styles(i), 'HandleVisibility', 'off', 'Linewidth', 1.5);
    end
    xlim([0, 20]);
    xlabel('f (Hz)');
    ylabel('Relative P');
    title('FFTs over shaded area');
    lgd = legend(CorrVar(pl), 'Location', 'NorthEast');
    hold off;
    lgd.FontSize = 6;
    
    %% plot FFT sound envelope vs FFT signal
    
    axes(AH(8));
    [audio_filts, audio_cutoffs_Hz] = make_constQ_cos_filters(length(NoiseWaveform), 250000, 30, 2000, 64000, 8);
    subbands = generate_subbands(NoiseWaveform, audio_filts);
    subband_envs = abs(hilbert(subbands));
    [SubbandP1, SubbandFreqs] = getP1(subband_envs, 250000);
    SubbandP1Avg = squeeze(mean(SubbandP1, 2));
    % Define the threshold for peak detection
    threshold = 0.002;
    % Identify peaks above the threshold
    peaks = SubbandP1Avg > threshold;
    % Set values below the threshold to zero
    SubbandP1Avg(~peaks) = 0;
    plot(frequencies, P1(:, pl(4)), 'Color', line_colors(4, :), 'Linewidth', 1.5);
    ylabel('Relative P');
    
    yyaxis right
    set(gca, 'YColor', [0 0.5 0]);
    ylabel('Envelope')
    plot(SubbandFreqs, SubbandP1Avg(:, 1), 'Color', [0 0.5 0]);
    xlim([0, 20]);
    xlabel('f (Hz)');
    title('Stimulus FFT vs Response FFT')
    
    %% Plot preTex FFT vs PostTex FFT
    
    axes(AH(7));
    
    [PresignalP1, PresignalFreqs] = getP1(AvgImage(1:1:199, :), P.FR);
    hold on;
    plot(PresignalFreqs, PresignalP1(:, pl(4)), 'Color', 'k', 'Linewidth', 1.5);
    plot(frequencies, P1(:, pl(4)), 'Color', line_colors(4, :), 'Linewidth', 1.5);
    ylabel('Relative P');
    title([CorrVar(pl(4)), ' pre and post Texture FFT'])
    xlim([0, 50]);
    xlabel('f (Hz)');
    hold off;
end