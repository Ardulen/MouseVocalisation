function plotVocvsSilvsSus(varargin)

P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Measures', {'SilVocResp', 'SusLvl', 'TexVocResp'})
checkField(P, 'LabelNames', {'Vocalization', 'Sustained Level', 'Vocalization in Noise'})
checkField(P, 'FIG', 300)
checkField(P, 'Zscore', [2, -2, 2])
checkField(P, 'Area', 'ACX')
checkField(P, 'ScaleBarSize', 8)
checkField(P, 'ScaleBarSep', 7)

VocalizationRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R201', 'R130', 'R193'});

P.Colors = [0, 0.5, 0;0, 0, 1;0.5, 0, 0.5];
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
set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60, 1100, HPixels]);
set(gcf, 'Color', 'w')

[~,AHTop] = axesDivide([0.2, 0.2, 0.2, 0.3],1,[0.05, 0.6, 0.9, 0.35],[0.1, 0.1, 0.1],[], 'c');
[~,AHBottom] = axesDivide(3,1,[0.05, 0.05, 1, 0.5],[0.2, 0.2, 0.2],[], 'c');


Letters = {'A','B','C','D','E', 'F', 'G'};

for i = 1:3
    annotation('textbox', [0.005+0.225*(i-1), 0.9, 0.1, 0.1], 'String', Letters{i}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
end
annotation('textbox', [0.67, 0.9, 0.1, 0.1], 'String', Letters{4}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
for i = 1:3
    annotation('textbox', [0.005+0.33*(i-1), 0.5, 0.1, 0.1], 'String', Letters{i+4}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
end

%% Plot transformed Masks

load('/mnt/data/Samuel/Global/Transformed.mat')



Animal = P.Animals{1};
ImageSize = size(TransImages.(Animal).TexResp);
for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    load(['/home/experimenter/dnp-backup/ControllerData/',Animal, '/', VocalizationRecordings(Animal), '/Results/M.mat'])
    P.Background.(Animal) = M.Image.AnatomyFrame;
    P.PixelPerMM.(Animal) = M.Image.PixelPerMM;
end

P.PMM = P.PixelPerMM.(P.Animals{1});
P.Y = size(P.Background.(P.Animals{1}), 2);


[MaskSize, Masks] = plotContourMaps(P, AHTop);
plotScaleBars(P, 'w', AHTop(1), 20, P.Y-18, 1)

%% Plot Sizes

NamesWithoutOverlap = nchoosek(P.LabelNames, 2);

AllLabels = cell(size(NamesWithoutOverlap, 1), 1);
for i = 1:size(NamesWithoutOverlap, 1)
    AllLabels{i} = [NamesWithoutOverlap(i, :) 'Overlap'];
end

for q = 1:P.AnimalNum
    id = 1;
    Animal = P.Animals{q};
    for i = 1:numel(P.Measures)
        for j = i+1:numel(P.Measures)

            Sizes.(Animal)(1, id) = MaskSize.(Animal)(i);
            Sizes.(Animal)(2, id) = MaskSize.(Animal)(j);
            Sizes.(Animal)(3, id) = sum(Masks.(Animal).(P.Measures{i}) & Masks.(Animal).(P.Measures{j}), 'all')/(P.PixelPerMM.(Animal)^2);
            id = id+1;
        end
    end
end

X = [2, 6, 10];

for i = 1:numel(P.Measures)
    cAH = AHBottom(i);
    hold(cAH, 'on')
    Labels = AllLabels{i};
    for q = 1:P.AnimalNum
        Animal = P.Animals{q};
        scatter(cAH, X, Sizes.(Animal)(:, i), 50, P.AnimalColors(q, :), 'filled', 'MarkerFaceAlpha', 0.8)
        plot(cAH, X, Sizes.(Animal)(:, i), 'Color',  [P.AnimalColors(q, :), 0.8], 'HandleVisibility', 'off', 'LineWidth', 1.5)
 
    end
    

   
    ylabel(cAH, 'mm^2')
    xticks(cAH, [2, 6, 10]);
    xlim(cAH, [0, 12])
    ylim(cAH, [0, 1.3])
    xticklabels(cAH, Labels)
    cAH.FontSize = 8;
    cAH.XAxis.FontSize = 7;
end
legend(AHBottom(1), P.Animals, 'FontSize', 6, 'Location', 'SouthWest')

%% plot overlap bar plot


load('/mnt/data/Samuel/Global/TexSilMaskSize.mat');
D.TexRespSilVocResp = MaskSize;
load('/mnt/data/Samuel/Global/TexSusMaskSize.mat');
D.TexRespSusLvL = MaskSize;
Meas = nchoosek(P.Measures, 2);
for j = 1:numel(P.Measures)
    for i = 1:P.AnimalNum
        D.([Meas{j, 1}, Meas{j, 2}]).(P.Animals{i}) = Sizes.(P.Animals{i})(:, j);
    end
end

Names = fieldnames(D);
for j = 1:numel(Names)
    for i = 1:P.AnimalNum
        Bars.(Names{j})(i) = 100*D.(Names{j}).(P.Animals{i})(3)/mean(D.(Names{j}).(P.Animals{i})(1:2));
    end
    Bars.(Names{j})(i+1) = mean(Bars.(Names{j})); 
end

Combs = {'T-V', 'T-S', 'V-S', 'V-VN', 'S-VN'};

cAH = AHTop(4);
hold(cAH, 'on')
BPos = 1:numel(Names);
SmallBarOffset = [-0.2, 0, 0.2];
for i = 1:P.AnimalNum
    bar(cAH, 1, 0, 'FaceColor', P.AnimalColors(i, :), 'BarWidth', 0.1, 'DisplayName', P.Animals{i}, 'FaceAlpha', 0.8)
end
bar(cAH, 1, 0, 'FaceColor', [0.7, 0.7, 0.7], 'FaceAlpha', 0.3, 'BarWidth', 0.5, 'DisplayName', 'Mean')
for j = 1:numel(Names)
    for i = 1:P.AnimalNum
        bar(cAH, BPos(j) + SmallBarOffset(i), Bars.(Names{j})(i), 'FaceColor', P.AnimalColors(i, :), 'BarWidth', 0.1, 'HandleVisibility', 'off', 'FaceAlpha', 0.8)
    end
    bar(cAH, BPos(j), Bars.(Names{j})(i+1), 'FaceColor', [0.7, 0.7, 0.7], 'FaceAlpha', 0.3, 'BarWidth', 0.5, 'HandleVisibility', 'off')
end
ylabel(cAH, 'Overlap (%)')
legend(cAH, 'FontSize', 6, 'Location', 'northwest')
xticks(cAH, BPos);
xticklabels(cAH, Combs)
cAH.FontSize = 8;
