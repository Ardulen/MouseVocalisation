function plotVocFreqsMasks(Plot, varargin)

P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'FIG', 20)
checkField(P, 'PreTimes', [0.5, 1, 3])
checkField(P, 'ScaleBarSize', 6)
checkField(P, 'ScaleBarSep', 8)
checkField(P, 'VocFreqs', [4000, 8000, 32000])
checkField(P, 'Zscore', [1])

for i = 1:numel(P.PreTimes)
    P.PreTimeNames{i} = ['PreTime', num2str(P.PreTimes(i)*10), 's'];
end
for i = 1:numel(P.VocFreqs)
    P.Variables{i} = ['PreTime', num2str(P.VocFreqs(i)), 'Hz'];
end
P.Variable{1} = P.Variables{3};
P.Measures = P.Variable;
P.AnimalNum = numel(P.Animals);
NoiseBurstRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R4', 'R4', 'R3'});
VocalizationRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R201', 'R130', 'R193'});


P.Colors = [0.5, 0, 0.5;0.7, 0.3, 0.7;0.85, 0.6, 0.85];
P.Yellow = [1.0000, 0.85, 0.2]; %;1.0000, 0.8500, 0.2000;0.8500, 0.6500, 0.1250;0.75, 0.55, 0.05];
P.GreyColors = [0.1, 0.1, 0.1;0.3, 0.3, 0.3;0.5, 0.5, 0.5];
P.AnimalColors = [0.7, 0.2, 0.4;0.6, 0.5, 0.7;0.6, 0.7, 0.3];
P.CombiColors = [0.5, 0, 0.5;0.7, 0.3, 0.7;0.85, 0.6, 0.85];
Orange = [0.8, 0.3, 0;1, 0.5, 0;1, 0.6, 0.2];
Blue = [0, 0, 0.5;0, 0, 1;0.3, 0.3, 1];
P.VocColors = cat(3, Orange, Blue);


for i =1:P.AnimalNum
    load(['/mnt/data/Samuel/', P.Animals{i}, '/VocFreqsAllVoc.mat'])
    for j = 1:numel(P.PreTimeNames)
        Maps.(P.Animals{i}) = VocFreqs;
    end
end

ImageSize = size(Maps.(P.Animals{1})(:, :, 1, 1));

Animal = P.Animals{1};
load(['/home/experimenter/dnp-backup/ControllerData/', Animal,'/', NoiseBurstRecordings(Animal), '/Results/evaluateNoiseBurst.mat']);
Mask = M.FilteredMetrics.SelPix.ACX;
ACX = imresize(Mask, ImageSize);

Map = M.Metrics.Median.OnsetLatency;
Mask = HF_SignFilterImage(Map', 'SelectionMethod','zscore', 'zscoreThresh', -1, 'ForceSingleRegion', 1, 'MaskExpand', 1);
LowLatency = imresize(Mask, ImageSize);

for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    load(['/home/experimenter/dnp-backup/ControllerData/',Animal, '/', VocalizationRecordings(Animal), '/Results/M.mat'])
    P.Background.(Animal) = M.Image.AnatomyFrame;
    P.PixelPerMM.(Animal) = M.Image.PixelPerMM;
end
P.Y = ImageSize(2);
P.PMM = P.PixelPerMM.(P.Animals{1});

for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    PreTimeMaps = squeeze(Maps.(Animal)(:, :, 3, :));
    Mean = mean(PreTimeMaps, 'all');
    STD = std(PreTimeMaps, [], 'all');
    for k = 1:numel(P.PreTimes)
        Z = (squeeze(PreTimeMaps(:, :, k))-Mean)/STD;
        if P.Zscore<0
          Mask = logical(Z<P.Zscore);
        else
          Mask = logical(Z>P.Zscore);
        end
        Masks.(P.PreTimeNames{k}).(Animal).(P.Variable{1}) = Mask;
    end
end

MP = get(0,'MonitorPositions');
NY = MP(1,end); HPixels = 500;
Fig = figure(P.FIG);
clf(P.FIG)
FigureName = 'Vocalization Frequency Response';
set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1000, HPixels]);
set(gcf, 'Color', 'w')

P.DispNames = {'32 kHz'};
P.MaskGen = 0;
P.ScaleBar = 0;
P.Legend = 1;
P.MaskSize = 1; 
for i = 1:numel(P.PreTimes)
    cAH = subplot(2, 4, i);
    title(cAH, [num2str(P.PreTimes(i)), ' s'])
    MaskSize.(P.PreTimeNames{i}) = plotCombinedMaps(P, cAH, Masks.(P.PreTimeNames{i}), ImageSize, ACX, LowLatency, [0.05, 0.75, 0.05, 0.05]);
    P.Legend = 0;
end

cAH = subplot(2, 4, 1);
plotScaleBars(P, 'k', cAH, 1, P.Y, 1.5)



%% plot Line Graphs
X = [2, 6, 10];

cAH = subplot(2, 4, 4);
hold(cAH, 'on')
for i = 1:P.AnimalNum
    scatter(cAH, X, [MaskSize.(P.PreTimeNames{1}).(P.Animals{i}), MaskSize.(P.PreTimeNames{2}).(P.Animals{i}), MaskSize.(P.PreTimeNames{3}).(P.Animals{i})] , 50, P.CombiColors(i, :, 1), 'filled', 'DisplayName', P.Animals{i})
    plot(cAH, X, [MaskSize.(P.PreTimeNames{1}).(P.Animals{i}), MaskSize.(P.PreTimeNames{2}).(P.Animals{i}), MaskSize.(P.PreTimeNames{3}).(P.Animals{i})], 'Color',  P.CombiColors(i, :, 1), 'HandleVisibility', 'off', 'LineWidth', 1.5)
end
xticks(cAH, X)
xticklabels(cAH, P.PreTimes)
xlim(cAH, [0, 12])

title(cAH, 'Area Sizes') 
ylabel(cAH, 'mm^2')
xlabel(cAH, 'Pretime')
cAH.FontSize = 8;


subplot(2, 4, 5)
d = violinplot(Plot.Strength, P.PreTimes, 'ViolinColor', P.Yellow);
title(['Response Strength'])
xlabel('PreTime (s)')
ylabel('AUG DF/F')
cAH.FontSize = 8;

subplot(2, 4, 6)
d = violinplot(Plot.Size./(35.3 ^ 2), P.PreTimes, 'ViolinColor', P.Yellow);
title('Response Size')
xlabel('PreTime (s)')
ylabel('mm²')
cAH.FontSize = 8;

for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    PreTimeMaps = squeeze(Maps.(Animal));
    Mean = mean(PreTimeMaps, 'all');
    STD = std(PreTimeMaps, [], 'all');
    for j = 1:numel(P.VocFreqs)-1
        for k = 1:numel(P.PreTimes)
            Z = (squeeze(PreTimeMaps(:, :, j, k))-Mean)/STD;
            if P.Zscore<0
              Mask = logical(Z<P.Zscore);
            else
              Mask = logical(Z>P.Zscore);
            end
            Masks.(P.PreTimeNames{k}).(Animal).(P.Variables{j}) = Mask;
            MaskSizes.(P.PreTimeNames{k}).(Animal).(P.Variables{j}) = sum(Mask(:))/(P.PixelPerMM.(Animal)^2);
        end
    end
end

for j = 1:numel(P.VocFreqs)-1
    cAH = subplot(2, 4, j+6);
    hold(cAH, 'on')
    for i = 1:P.AnimalNum
        y = [MaskSizes.(P.PreTimeNames{1}).(P.Animals{i}).(P.Variables{j}), MaskSizes.(P.PreTimeNames{2}).(P.Animals{i}).(P.Variables{j}), MaskSizes.(P.PreTimeNames{3}).(P.Animals{i}).(P.Variables{j})];
        scatter(cAH, X, y , 50, P.VocColors(i, :, j), 'filled', 'DisplayName', P.Animals{i})
        plot(cAH, X, y, 'Color',  P.VocColors(i, :, j), 'HandleVisibility', 'off', 'LineWidth', 1.5)
    end
    xticks(cAH, X)
    xticklabels(cAH, P.PreTimes)
    xlim(cAH, [0, 12])
end


    
    