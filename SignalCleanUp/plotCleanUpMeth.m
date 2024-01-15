function plotCleanUpMeth(R, varargin)
    P = parsePairs(varargin);
    checkField(P, 'Pixel', [87, 93])
    checkField(P, 'Trial', 1)
    checkField(P, 'FIG', 1)
    checkField(P, 'FilterOrder', 1)
    checkField(P, 'CutoffFreq', 1)
    checkField(P, 'WindowSize', 20)
    checkField(P, 'Corrs', 0.8)
    checkField(P, 'Vars', 0.4)
    %% Time Points
    Time=R.Frames.TimeAvg-2;
    PreTime = R.General.Paradigm.Trials(P.Trial).Stimulus.ParSequence.PreTime;
    PreTimes = R.General.Paradigm.Stimulus.Parameters.DurContext.Value;
    %% Data
    Data = 100*squeeze(R.Frames.AvgTime(P.Pixel(2), P.Pixel(1), :, P.Trial));
    %% Set figure
    MP = get(0,'MonitorPositions');
    NY = MP(1,end); HPixels = 540;
    FigureName=[R.Parameters.Animal,' R',num2str(R.Parameters.Recording),' Signal clean up methods'];
    Fig = figure(P.FIG); clf; set(Fig,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1250,HPixels]);
    [~,AH] = axesDivide(1,2,[0.05, 0.1, 0.9, 0.8],[],0.4, 'c');
    annotation('textbox','String', ['Pixel [', num2str(P.Pixel(1)),',' num2str(P.Pixel(2)), ']', ' Corr ', num2str(P.Corrs), ' Var ', num2str(P.Vars), ' PreTime ', num2str(PreTime)],'Position',[0.3,0.97,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    %% plot Stims
    for i=1:2
        cAH = AH(i);
        for j = 1:4
            for k = 1:10
                % Calculate the x-coordinate of each rectangle
                xCenter = PreTime+0.2*(k-1);

                % Use the rectangle function to create each rectangle
                VocStims(k) = rectangle(cAH, 'Position', [xCenter, -10, 0.1, 20], 'FaceColor', 'g', 'EdgeColor', 'none', 'Visible', 'on', 'HandleVisibility', 'off');
            end
        end
        hold(cAH, 'on')
        plot(cAH, [0, 0],[-1000,1000],'-','Color','k', 'HandleVisibility', 'Off', 'LineWidth', 1.5);
    end
    %% plot pixel
%     cAH = AH(1);
%     plot(cAH, Time, Data, "LineWidth", 1.5, 'HandleVisibility', 'off', 'Color', [0, 0, 1])
%     YLims = [min(Data)*1.1, max(Data)*1.1];
%     ylim(cAH, YLims)
    
    %% Plot average over VocFreq, Rep, Reals
    if strcmp(R.General.Paradigm.Trials(P.Trial).Stimulus.ParSequence.BaseTexture, 'Silence')
        TrialNums = GetTrialNums(0, 0, 0, R.General, 1, R.General.Paradigm.Trial, PreTime, R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value);
    else
        TrialNums = GetTrialNums(P.Corrs, P.Vars, [1, 2, 3], R.General, 0, R.General.Paradigm.Trial, PreTime, R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value);
        
    end
    TrialDat = squeeze(R.Frames.AvgTime(P.Pixel(2), P.Pixel(1), :, TrialNums));
    AvgDat = 100*mean(TrialDat, 2);
    SEM  = 2*nanstd(TrialDat,[],2)/sqrt(size(TrialDat,2));
    axes(AH(1));
    errorhull(Time, AvgDat, 100*SEM, 'LineWidth',1.5)
    YLims = [min(AvgDat)*1.1, max(AvgDat)*1.1];
    ylim(YLims)
    
    %% plot freq filter
    fc = P.CutoffFreq;
    fs = 100;
    order = P.FilterOrder;
    [b, a] = butter(order, fc/(fs/2));
    FiltDat = filter(b, a, Data);
    FiltAvgDat = filter(b, a, AvgDat);
%     cAH = AH(1);
%     FreqFil1 = plot(cAH, Time, FiltDat, 'LineWidth', 2);
    cAH = AH(1);
    hold(cAH, 'on')
    FreqFil2 = plot(cAH, Time, FiltAvgDat, 'LineWidth', 2);
    
    %% add moving median
    MovMed = medfilt1(Data, P.WindowSize);
    AvgMovMed = medfilt1(AvgDat, P.WindowSize);
%     cAH = AH(1);
%     MovMed1 = plot(cAH, Time, MovMed, 'LineWidth', 2, 'Color', [1, 0, 0]);
%     title(cAH, ['Trial ', num2str(P.Trial), ' Texture: ', R.General.Paradigm.Trials(P.Trial).Stimulus.ParSequence.BaseTexture])
    cAH = AH(1);
    MovMed2 = plot(cAH, Time, AvgMovMed, 'LineWidth', 2, 'Color', [1, 0, 0]);
    if strcmp(R.General.Paradigm.Trials(P.Trial).Stimulus.ParSequence.BaseTexture, 'Silence')
        title(cAH, ['Avg over all Silence Texs with Pretime ', num2str(PreTime)])
    else    
        title(cAH, 'Avg over VocFreqs, Reps and Reals')
    end
    title(AH(2), 'Texture Average seperated by Realization')
    
    %% further specified minima
    RangeStart = (PreTime+2)*100;
    RangeEnd = (PreTime+3.9)*100;
    Dats = {Data, AvgDat};
    
%    for j = 1:2
        for i = 1:10
            [PreMinVs(i), PreMinIs(i)] = min(squeeze(Dats{2}(RangeStart-20+i*20:RangeStart-16+i*20, 1)));
            [PostMinVs(i), PostMinIs(i)] = min(squeeze(Dats{2}(RangeStart-14+i*20:RangeStart-9+i*20, 1)));
        end
        MergedMinVs = zeros(1, length(PreMinVs)*2);
        MergedMinIs = zeros(1, length(PreMinIs)*2);
        % Use a loop to fill in the merged list
        for i = 1:length(PreMinVs)
            MergedMinVs(2 * i - 1) = PreMinVs(i);
            MergedMinVs(2 * i) = PostMinVs(i);
            MergedMinIs(2 * i - 1) = PreMinIs(i)+RangeStart-20+i*20;
            MergedMinIs(2 * i) = PostMinIs(i)+RangeStart-14+i*20;       
        end

        InterpRange = linspace(RangeStart, RangeEnd, 190);
        InterpMin = interp1(MergedMinIs, MergedMinVs, InterpRange, 'pchip');

        plot(AH(1), Time(MergedMinIs), MergedMinVs, '*', 'MarkerSize', 8, 'Color', 'c');
        plot(AH(1), (InterpRange-200)/100, InterpMin, 'LineWidth', 1.5, 'Color', 'c');
%    end
    %% Previous Texture Avg
    if ~strcmp(R.General.Paradigm.Trials(P.Trial).Stimulus.ParSequence.BaseTexture, 'Silence')

        % Find the indices of entries before the current pretime
        indicesBeforeValue = find(PreTimes > PreTime);

        % Select entries before the current pretime
        PreTimesToAvg = PreTimes(indicesBeforeValue);
        TrialNums = GetTrialNums(P.Corrs, P.Vars, [1, 2, 3], R.General, 0, R.General.Paradigm.Trial, PreTimesToAvg, R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value);
        TrialDat = squeeze(R.Frames.AvgTime(P.Pixel(2), P.Pixel(1), :, TrialNums));
        AvgDat = 100*mean(TrialDat, 2);
        plot(AH(1), Time, AvgDat, 'LineWidth', 1.5, 'Color', 'm')

    
        % different Realizations seperated
        LineColors = [0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980; 0.9290, 0.6940, 0.1250];
        axes(AH(2));
        for i = 1:3
            TrialNums = GetTrialNums(P.Corrs, P.Vars, i, R.General, 0, R.General.Paradigm.Trial, PreTime, R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value);
            TrialDat = squeeze(R.Frames.AvgTime(P.Pixel(2), P.Pixel(1), :, TrialNums));
            AvgDat = 100*mean(TrialDat, 2);
            SEM  = 2*nanstd(TrialDat,[],2)/sqrt(size(TrialDat,2));
            errorhull(Time, AvgDat, 100*SEM, 'LineWidth',1.5, 'Color', LineColors(i, :))
            hold on;
            ylim(YLims)
            TrialNums = GetTrialNums(P.Corrs, P.Vars, i, R.General, 0, R.General.Paradigm.Trial, PreTimesToAvg, R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value);
            TrialDat = squeeze(R.Frames.AvgTime(P.Pixel(2), P.Pixel(1), :, TrialNums));
            AvgDat = 100*mean(TrialDat, 2);
            plot(Time, AvgDat, 'LineWidth', 1.5, 'Color', LineColors(i, :), 'LineStyle', ':')

        end
        % legends
        %lgd(1) = legend(AH(1), ['ButterWorth filter: order ', num2str(order),', cutoff ', num2str(fc), ' hz'], ['Movingmedian: WindowSize ', num2str(P.WindowSize)], ['Selected minima'], 'Interpolated selected minima', 'FontSize', 6);
        lgd(1) = legend(AH(1), 'SEM', 'Average', ['ButterWorth filter: order ', num2str(order),', cutoff ', num2str(fc), ' hz'], ['Movingmedian: WindowSize ', num2str(P.WindowSize)], 'Selected minima', 'Interpolated selected minima', 'Texture Average', 'FontSize', 6);
        Leg = {};
        for i = 1:3
            Leg = [Leg, {['SEM Realization ', num2str(i)], ['Average Realization', num2str(i)], ['Texture Average Realization ', num2str(i)]}];
        end
        lgd(2) = legend(AH(2), Leg, 'FontSize', 6);

        %% visibility
        for i = 1:2
            set(lgd(i), 'ItemHitFcn', @(src, event) toggleVisibility(event));
        end
        % Function to toggle the visibility of the clicked line

    end
    function toggleVisibility(event)
        % Toggle the visibility of the corresponding plot
        if strcmpi(event.Peer.Visible, 'on')
            event.Peer.Visible = 'off';
        else
            event.Peer.Visible = 'on';
        end
    end
end