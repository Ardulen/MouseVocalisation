function plotVocFreqOnOffsetFigure(Plot, PlotSil, varargin)

P = parsePairs(varargin);
checkField(P, 'Save', 0)
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'VocFreqs', [4, 8, 32])
checkField(P, 'FIG', 1001)
checkField(P, 'Measures', {'SilVocResp'})
checkField(P, 'Zscore', [2])
checkField(P, 'Area', 'ACX')
checkField(P, 'ScaleBarSize', 7)
checkField(P, 'ScaleBarSep', 8)
checkField(P, 'Save', 0)

P.AnimalNum = numel(P.Animals);
P.VocFreqNum = numel(P.VocFreqs);
P.VioColors = [1, 1, 0;0.4, 0.4, 1;0.8, 0.3, 0.25];
P.Colors = [0, 0.5, 0];
Orange = [0.8, 0.3, 0;1, 0.5, 0;1, 0.6, 0.2];
Green = [0, 0.3, 0;0, 0.5, 0;0.2, 0.8, 0.2];
P.CombiColors = cat(3, Green, Orange);
P.GreyColors = [0.1, 0.1, 0.1;0.3, 0.3, 0.3;0.5, 0.5, 0.5];
P.AnimalColors = [0.9, 0.7, 0;0, 0.7, 0.5;0.6, 0.0, 0.1];
P.AnimalNum = numel(P.Animals);


MP = get(0,'MonitorPositions');
NY = MP(1,end); HPixels = 700;
Fig = figure(P.FIG);
clf(P.FIG)
FigureName = 'Vocalization On-, Offset per Frequency';
set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1300, HPixels]);
set(gcf, 'Color', 'w')

Letters = {'B','C', 'D','F','G'};

annotation('textbox', [0.05, 0.92, 0.1, 0.1], 'String', 'A', 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
annotation('textbox', [0.05, 0.41, 0.1, 0.1], 'String', 'E', 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')

for i = 1:3
    annotation('textbox', [0.05+0.33*(i-1), 0.68, 0.1, 0.1], 'String', Letters{i}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
end

for i = 1:2
    annotation('textbox', [0.05+0.47*(i-1), 0.2, 0.1, 0.1], 'String', Letters{i+3}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
end



[~,AHTop] = axesDivide(1,1,[0.1, 0.82, 0.8, 0.12],[],0.4, 'c');
[~,AHBot] = axesDivide(2,1,[0.1, 0.56, 0.55, 0.12],[],0.4, 'c');
[~,AHArea] = axesDivide(1,1,[0.65, 0.52, 0.3, 0.25],[],0.4, 'c');
[~,AHSilTop] = axesDivide(1,1,[0.1, 0.34, 0.8, 0.12],[],0.4, 'c');
[~,AHSilBot] = axesDivide(2,1,[0.1, 0.08, 0.8, 0.12],[],0.4, 'c');

AHTops = [AHTop;AHSilTop];

VioAndTrace(P, 1, 1, Plot, AHTops, AHBot, 'Average response Vocalization Area in Noise')
yloc = max(Plot.VocFreqs, [], 'all');
plotSignif(Plot, [1, 3], yloc*1.1, AHBot(1), 2, 'SignifTest', 1.1)
yloc = max(Plot.OnOffset, [], 'all');
plotSignif(Plot, [1, 3], yloc*1.1, AHBot(2), 2, 'OnOffset', 1.1)
plotSignif(Plot, [2, 3], yloc*1.5, AHBot(2), 3, 'OnOffset', 1.1)
VioAndTrace(P, 2, 1, PlotSil, AHTops, AHSilBot, 'Average response Vocalization Area in Silence')
%xlabel(AHSilBot(2), 'Vocalization Frequency (kHz)')
combs = nchoosek([1, 2, 3], 2);
yloc = max(PlotSil.VocFreqs, [], 'all');
for i = 1:3
    plotSignif(PlotSil, combs(i, :), yloc*(0.8+0.3*(i-1)), AHSilBot(1), i, 'SignifTest', 0.99)
end
yloc = max(PlotSil.OnOffset, [], 'all');
for i = 1:3
    plotSignif(PlotSil, combs(i, :), yloc*(0.8+0.3*(i-1)), AHSilBot(2), i, 'OnOffset', 1.1)
end
legend(AHTops(1), 'Location', 'northwest', 'FontSize', 6)

for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    load(['/mnt/data/Samuel/', Animal, '/Summary.mat'])
    Maps.(Animal) = Summary;
end

NoiseBurstRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R4', 'R4', 'R3'});
VocalizationRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R201', 'R130', 'R193'});

for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    load(['/home/experimenter/dnp-backup/ControllerData/',Animal, '/', VocalizationRecordings(Animal), '/Results/M.mat'])
    P.Background.(Animal) = M.Image.AnatomyFrame;
    P.PixelPerMM.(Animal) = M.Image.PixelPerMM;
end
ImageSize = size(P.Background.(P.Animals{1}));
P.Y = ImageSize(2);
P.PMM = P.PixelPerMM.(P.Animals{1});


Animal = P.Animals{1};
load(['/home/experimenter/dnp-backup/ControllerData/', Animal,'/', NoiseBurstRecordings(Animal), '/Results/evaluateNoiseBurst.mat']);
Mask = M.FilteredMetrics.SelPix.ACX;
ACX = imresize(Mask, ImageSize);

Map = zeros(ImageSize);
Mask = HF_SignFilterImage(Map', 'SelectionMethod','zscore', 'zscoreThresh', -1, 'ForceSingleRegion', 1, 'MaskExpand', 1);
LowLatency = imresize(Mask, ImageSize);


P.MaskGen = 1;
P.Legend = 1;
P.ScaleBar = 1;
P.DispNames = {'Vocalization'};
P.MaskSize = 0;
plotCombinedMaps(P, AHArea, Maps, ImageSize, ACX, LowLatency, [0.85, 0.5, 0.1, 0.1])

if P.Save
    set(Fig, 'PaperPositionMode', 'auto'); % Maintain on-screen size
    print(Fig, '/mnt/data/Samuel/ThesisPlots/VocalizationOnOffsetFreq.png', '-dpng', '-r300'); % Save as PNG with 300 DPI
end
end

function VioAndTrace(P, Ax, bAx, Plot, AHTops, AHBots, Title)

    axes(AHTops(Ax))
    hold on
    for i = 1:10
        % Calculate the x-coordinate of each rectangle
        xCenter = 0.2*(i-1);

        % Use the rectangle function to create each rectangle
        r = rectangle('Position', [xCenter, -10, 0.1, 20], 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end
    area(0, 0, 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'DisplayName', 'Vocalizations played')
    for i = 1:P.VocFreqNum
        plot(Plot.TimeVec-2.5, Plot.Trial(:, i), 'Color', P.VioColors(i, :), 'LineWidth', 1.7, 'DisplayName', [num2str(P.VocFreqs(i)), ' kHz'])
    end
    
    xlim([-0.5, 2])
    Lims = [min(Plot.Trial, [], 'all')*1.1, max(Plot.Trial, [], 'all')*1.1];
    ylim(Lims)
    ylabel('DF/F')
    set(AHTops(Ax), 'FontSize', 7)
    xlabel('Time (s)', 'FontSize', 7)
    TitleSpace(Title, 1.2)
    
    
    axes(AHBots(bAx))
    d = vioplot(Plot.VocFreqs, P.VocFreqs, 'MarkerSize', 6, 'ViolinColor', P.VioColors);
    ylabel('AUG DF/F')
    set(gca, 'FontSize', 7)
    xlabel('Vocalization Frequency (kHz)', 'FontSize', 7)
    TitleSpace('Reponse Strength', 1.6)
    Lims = [min(Plot.VocFreqs, [], 'all')*1.1, max(Plot.VocFreqs, [], 'all')*1.1];
    ylim(Lims)
    
    axes(AHBots(bAx+1))
    d = vioplot(Plot.OnOffset, P.VocFreqs, 'MarkerSize', 6, 'ViolinColor', P.VioColors);
    set(gca, 'FontSize', 7)
    xlabel('Vocalization Frequency (kHz)', 'FontSize', 7)
    TitleSpace('Onset-Offset', 1.6)
    Lims = [min(Plot.OnOffset, [], 'all')*1.1, max(Plot.OnOffset, [], 'all')*1.1];
    ylim(Lims)
        
end

function PValCheck(PVal, x, yloc, cAH)
    if (0.01 < PVal) && (PVal < 0.05)
        text(cAH, double(x), double(yloc+0.5), '*', 'HorizontalAlignment', 'center')
    elseif (0.001 < PVal) && (PVal < 0.01)
        text(cAH, double(x), double(yloc+0.5), '**', 'HorizontalAlignment', 'center')
    elseif PVal < 0.001
        text(cAH, double(x), double(yloc+0.5), '***', 'HorizontalAlignment', 'center' )
    end
end

function TitleSpace(Title, Mult)
    t = title(Title);
    currentPos = get(t, 'Position');
    set(t, 'Position', [currentPos(1), currentPos(2)*Mult, currentPos(3)]);
end

function plotSignif(Plot, x, yloc, AH, Sig, Var, Mult)
    plot(AH, [x(1) x(1) x(2) x(2)], [yloc*0.9 yloc yloc yloc*0.9], 'k', 'LineWidth', 0.5, 'Clipping', 'off')
    PVal = Plot.Comp.(Var)(Sig, 6);
    PValCheck(PVal, mean(x), double(yloc*Mult), AH)
end
