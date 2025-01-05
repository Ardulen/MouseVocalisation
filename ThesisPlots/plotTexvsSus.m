function plotTexvsSus(varargin)

P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Variable', {'Tex', 'Sus'})
checkField(P, 'FIG', 200)
checkField(P, 'Zscore', [2, -2])
checkField(P, 'Area', 'ACX')
checkField(P, 'ScaleBarSize', 8)
checkField(P, 'ScaleBarSep', 7)
checkField(P, 'Save', 0)
checkField(P, 'FigSave', 0)

P.Measures = {[P.Variable{1}, 'Resp'], [P.Variable{2}, 'Lvl']};%necassary because of slightly different naming in saved data

NoiseBurstRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R4', 'R4', 'R3'});
VocalizationRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R201', 'R130', 'R193'});

P.Colors = [1, 0.5, 0;0, 0, 1];
Orange = [0.8, 0.3, 0;1, 0.5, 0;1, 0.6, 0.2];
Blue = [0, 0, 0.7;0, 0, 1;0.3, 0.3, 1];
P.CombiColors = cat(3, Orange, Blue);
P.GreyColors = [0.1, 0.1, 0.1;0.3, 0.3, 0.3;0.5, 0.5, 0.5];
P.AnimalColors = [0.9, 0.7, 0;0, 0.7, 0.5;0.6, 0.0, 0.1];
P.AnimalNum = numel(P.Animals);

MP = get(0,'MonitorPositions');
NY = MP(1,end); HPixels = 500;
Fig = figure(P.FIG);
clf(P.FIG)
FigureName = 'Vocalization versus Texture';
set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,700, HPixels]);
set(gcf, 'Color', 'w')

[~,AHTop] = axesDivide(3,1,[0.05, 0.58, 0.9, 0.35],[],0.5, 'c');
[~,AHBottom] = axesDivide(2,1,[0.05, 0.05, 0.9, 0.45], [], 0.5, 'c');

Letters = {'A','B','C','D','E'};

for i = 1:3
    annotation('textbox', [0.005+0.33*(i-1), 0.91, 0.1, 0.1], 'String', Letters{i}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
end
for i = 1:2
    annotation('textbox', [0.005+0.5*(i-1), 0.48, 0.1, 0.1], 'String', Letters{i+3}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
end
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

[MaskSize, ~] = plotContourMaps(P, AHTop);


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
P.DispNames = {'Texture', 'Sustained Level'};
P.MaskSize = 1;
plotCombinedMaps(P, AHBottom(1), Maps, ImageSize, ACX, LowLatency, [0.35, 0.07, 0.1, 0.1])



%% Plot Sizes

Labels = {'Texture', 'Sustained Level', 'Overlap'};
plotLineGraph(P, AHBottom(2), Labels, MaskSize)

if P.Save
    save('/mnt/data/Samuel/Global/TexSusMaskSize.mat', 'MaskSize')
end

if P.FigSave
    set(Fig, 'PaperPositionMode', 'auto'); % Maintain on-screen size
    print(Fig, '/mnt/data/Samuel/ThesisPlots/TexvsSus.png', '-dpng', '-r300'); % Save as PNG with 300 DPI
end
