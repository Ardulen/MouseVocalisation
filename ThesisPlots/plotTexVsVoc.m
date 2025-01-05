function plotTexVsVoc(varargin)
P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Variable', {'Tex', 'Sil'})
checkField(P, 'FIG', 100)
checkField(P, 'Zscore', [2, 2])
checkField(P, 'Area', 'ACX')
checkField(P, 'ScaleBarSize', 8)
checkField(P, 'ScaleBarSep', 7)
checkField(P, 'Save', 0)
checkField(P, 'FigSave', 1)

P.Measures = {[P.Variable{1}, 'Resp'], [P.Variable{2}, 'VocResp']};%necassary because of slightly different naming in saved data

NoiseBurstRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R4', 'R4', 'R3'});
VocalizationRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R201', 'R130', 'R193'});

P.Colors = [1, 0.5, 0;0, 0.5, 0];
RectColors = [1, 0.6, 0.2, 0.5;0.2, 0.8, 0.2, 0.5];
Orange = [0.8, 0.3, 0;1, 0.5, 0;1, 0.6, 0.2];
Green = [0, 0.3, 0;0, 0.5, 0;0.2, 0.8, 0.2];
P.CombiColors = cat(3, Orange, Green);
P.GreyColors = [0.1, 0.1, 0.1;0.3, 0.3, 0.3;0.5, 0.5, 0.5];
P.AnimalColors = [0.9, 0.7, 0;0, 0.7, 0.5;0.6, 0.0, 0.1];
P.AnimalNum = numel(P.Animals);

MP = get(0,'MonitorPositions');
NY = MP(1,end); HPixels = 700;
Fig = figure(P.FIG);
clf(P.FIG)
FigureName = 'Vocalization versus Texture';
set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,700, HPixels]);
set(gcf, 'Color', 'w')

[~,AHTop] = axesDivide(1,1,[0.05, 0.75, 0.9, 0.15],[],0.5, 'c');
[~,AHMiddle] = axesDivide(3,1,[0.05, 0.38, 0.9, 0.3],[],0.5, 'c');
[~,AHBottom] = axesDivide(2,1,[0.05, 0.05, 0.9, 0.3], [], 0.5, 'c');

Letters = {'B','C','D','E','F'};

annotation('textbox', [0.005, 0.86, 0.1, 0.1], 'String', 'A', 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
for i = 1:3
    annotation('textbox', [0.005+0.33*(i-1), 0.62, 0.1, 0.1], 'String', Letters{i}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
end
for i = 1:2
    annotation('textbox', [0.005+0.5*(i-1), 0.31, 0.1, 0.1], 'String', Letters{i+3}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
end
%% plotTotalVocAreaResp

cAH = AHTop;

load('/mnt/data/Samuel/Global/TimeVec.mat')

for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    Data.(Animal) = load(['/mnt/data/Samuel/', Animal, '/TotMaskResp/TotResp', P.Area,'.mat']);
end

for j = 1:numel(P.Variable)
    Var = [P.Variable{j}, 'RespTrials'];
    TotVioData.(Var) = Data.(P.Animals{1}).D.(Var);
    for i = 2:P.AnimalNum
        TotVioData.(Var) = cat(2, TotVioData.(Var), Data.(P.Animals{i}).D.(Var));
        
    end
end
Leg = {'Texture response', 'Vocalization response'};

Lims = [-3, 3];

TRCenter = 0;
hold(cAH, 'on')
area(cAH, 0, 0, 'FaceColor', P.Colors(1, :), 'DisplayName', 'Texture', 'FaceAlpha', 0.5, 'EdgeColor', 'none')
area(cAH, 0, 0, 'FaceColor', P.Colors(2, :), 'DisplayName', 'Vocalizations', 'FaceAlpha', 0.5, 'EdgeColor', 'none')
TexRec = rectangle(cAH, 'Position', [TRCenter, -10, 5, 20], 'FaceColor', RectColors(1, :), 'EdgeColor', 'none');
for i = 1:10
    % Calculate the x-coordinate of each rectangle
    xCenter = 0.2*(i-1);

    % Use the rectangle function to create each rectangle
    r = rectangle(cAH, 'Position', [xCenter, -10, 0.1, 20], 'FaceColor', RectColors(2, :), 'EdgeColor', 'none');
end

for i = 1:numel(P.Variable)
    Var = [P.Variable{i}, 'RespTrials'];
    Resp = squeeze(nanmean(TotVioData.(Var), 2));
    SEM = std(TotVioData.(Var), 0, 2);
    %Plot.(Var) = errorhull(TimeVec-2, 100*Resp, 100*SEM, 'LineWidth', 1.5, 'Color', P.Color(i, :));
    plot(cAH, TimeVec-2, 100*Resp, 'LineWidth', 2, 'Color', P.Colors(i, :), 'DisplayName', Leg{i})
end

xlim(cAH, [-0.5, 2.5])
ylim(cAH, Lims)
ylabel(cAH, 'DF/F')
xlabel(cAH, 'Time (s)')
legend(cAH, 'FontSize', 6, 'Position', [0.82, 0.835, 0.05, 0.05])
title(cAH, 'Average response over ACX')
cAH.FontSize = 8;
%% Plot transformed Masks


for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    load(['/home/experimenter/dnp-backup/ControllerData/',Animal, '/', VocalizationRecordings(Animal), '/Results/M.mat'])
    P.Background.(Animal) = M.Image.AnatomyFrame;
    P.PixelPerMM.(Animal) = M.Image.PixelPerMM;
end
ImageSize = size(P.Background.(P.Animals{1}));
P.Y = ImageSize(2);
P.PMM = P.PixelPerMM.(P.Animals{1});

[MaskSize, ~] = plotContourMaps(P, AHMiddle);


%% plot Combination

Animal = P.Animals{1};
load(['/home/experimenter/dnp-backup/ControllerData/', Animal,'/', NoiseBurstRecordings(Animal), '/Results/evaluateNoiseBurst.mat']);
Mask = M.FilteredMetrics.SelPix.ACX;
ACX = imresize(Mask, ImageSize);

Map = M.Metrics.Median.OnsetLatency;
Mask = HF_SignFilterImage(Map', 'SelectionMethod','zscore', 'zscoreThresh', -1, 'ForceSingleRegion', 1, 'MaskExpand', 1);
LowLatency = imresize(Mask, ImageSize);

for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    load(['/mnt/data/Samuel/', Animal, '/Summary.mat'])
    Maps.(Animal) = Summary;
end

P.MaskGen = 1;
P.Legend = 1;
P.ScaleBar = 1;
P.DispNames = {'Texture', 'Vocalization'};
P.MaskSize = 1;
plotCombinedMaps(P, AHBottom(1), Maps, ImageSize, ACX, LowLatency, [0.35, 0.05, 0.1, 0.1])



%% Plot Sizes

Labels = {'Texture', 'Vocalization', 'Overlap'};
plotLineGraph(P, AHBottom(2), Labels, MaskSize)
  
if P.Save
    save('/mnt/data/Samuel/Global/TexSilMaskSize.mat', 'MaskSize')
end

if P.FigSave
    set(Fig, 'PaperPositionMode', 'auto'); % Maintain on-screen size
    print(Fig, '/mnt/data/Samuel/ThesisPlots/VocvsTex.png', '-dpng', '-r300'); % Save as PNG with 300 DPI
end
