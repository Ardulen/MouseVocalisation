function plotVocvsSilent(varargin)
P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Variable', {'Tex', 'Sil'})
checkField(P, 'FIG', 100)
checkField(P, 'Zscore', 2)
checkField(P, 'Area', 'ACX')
checkField(P, 'ScaleBarSize', 8)
checkField(P, 'ScaleBarSep', 7)


Measures = {[P.Variable{1}, 'Resp'], [P.Variable{2}, 'VocResp']};%necassary because of slightly different naming in saved data

NoiseBurstRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R4', 'R4', 'R3'});
VocalizationRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R201', 'R130', 'R193'});

Colors = [1, 0.5, 0;0, 0.5, 0];
RectColors = [1, 0.6, 0.2, 0.5;0.2, 0.8, 0.2, 0.5];
Orange = [0.8, 0.3, 0;1, 0.5, 0;1, 0.6, 0.2];
Green = [0, 0.3, 0;0, 0.5, 0;0.2, 0.8, 0.2];
CombiColors = cat(3, Orange, Green);
GreyColors = [0.1, 0.1, 0.1;0.3, 0.3, 0.3;0.5, 0.5, 0.5];
AnimalColors = [0.7, 0.2, 0.4;0.6, 0.5, 0.7;0.6, 0.7, 0.3];
AnimalNum = numel(P.Animals);

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

annotation('textbox', [0.005, 0.85, 0.1, 0.1], 'String', 'A', 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
for i = 1:3
    annotation('textbox', [0.005+0.33*(i-1), 0.6, 0.1, 0.1], 'String', Letters{i}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
end
for i = 1:2
    annotation('textbox', [0.005+0.5*(i-1), 0.29, 0.1, 0.1], 'String', Letters{i+3}, 'FontSize', 14, 'FontWeight', 'bold', 'EdgeColor', 'none')
end
%% plotTotalVocAreaResp

cAH = AHTop;

load('/mnt/data/Samuel/Global/TimeVec.mat')

for i = 1:AnimalNum
    Animal = P.Animals{i};
    Data.(Animal) = load(['/mnt/data/Samuel/', Animal, '/TotMaskResp/TotResp', P.Area,'.mat']);
end

for j = 1:numel(P.Variable)
    Var = [P.Variable{j}, 'RespTrials'];
    TotVioData.(Var) = Data.(P.Animals{1}).D.(Var);
    for i = 2:AnimalNum
        TotVioData.(Var) = cat(2, TotVioData.(Var), Data.(P.Animals{i}).D.(Var));
        
    end
end
Leg = {'Texture response', 'Vocalization response'};

Lims = [-3, 3];

TRCenter = 0;
hold(cAH, 'on')
area(cAH, 0, 0, 'FaceColor', Colors(1, :), 'DisplayName', 'Texture', 'FaceAlpha', 0.5, 'EdgeColor', 'none')
area(cAH, 0, 0, 'FaceColor', Colors(2, :), 'DisplayName', 'Vocalizations', 'FaceAlpha', 0.5, 'EdgeColor', 'none')
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
    plot(cAH, TimeVec-2, 100*Resp, 'LineWidth', 2, 'Color', Colors(i, :), 'DisplayName', Leg{i})
end

xlim(cAH, [-0.5, 3])
ylim(cAH, Lims)
ylabel(cAH, 'DF/F')
xlabel(cAH, 'Time(s)')
legend(cAH, 'FontSize', 7, 'Location', 'East')
title(cAH, 'Average response over ACX')
%% Plot transformed Masks

load('/mnt/data/Samuel/Global/Transformed.mat')

Animal = P.Animals{1};
ImageSize = size(TransImages.(Animal).TexResp);
for i = 1:AnimalNum
    Animal = P.Animals{i};
    load(['/home/experimenter/dnp-backup/ControllerData/',Animal, '/', VocalizationRecordings(Animal), '/Results/M.mat'])
    Background.(Animal) = M.Image.AnatomyFrame;
    PixelPerMM.(Animal) = M.Image.PixelPerMM;
end

for j = 1:AnimalNum
    cAH = AHMiddle(j);
    Animal = P.Animals{j};
    imagesc(cAH, Background.(Animal)')
    colormap('bone')
    hold(cAH, 'on')
    for i = 1:numel(P.Variable)
        Variable = Measures{i};
        Map = TransImages.(Animal).(Variable);
        Mask = HF_SignFilterImage(Map', 'SelectionMethod','zscore', 'zscoreThresh',P.Zscore);
        Masks.(P.Variable{i}) = Mask;
        bounds = bwboundaries(Mask);
        MaskSize.(Animal)(i) = sum(Mask(:))/(PixelPerMM.(Animal)^2);
        for q = 1:length(bounds)
            bound = bounds{q};
            patch(cAH, bound(:, 2), bound(:, 1), Colors(i, :), 'FaceAlpha', 0.5, 'EdgeColor', 'none')
        end
    end
    OverlapMask = Masks.(P.Variable{1}) & Masks.(P.Variable{2});
    MaskSize.(Animal)(i+1) = sum(OverlapMask(:))/(PixelPerMM.(Animal) ^ 2);
    axis(cAH, 'off')
    set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
    title(cAH, Animal)
end

%% plot Combination

Animal = P.Animals{1};
load(['/home/experimenter/dnp-backup/ControllerData/', Animal,'/', NoiseBurstRecordings(Animal), '/Results/evaluateNoiseBurst.mat']);
Mask = M.FilteredMetrics.SelPix.ACX;
ACX = imresize(Mask, ImageSize);

Map = M.Metrics.Median.OnsetLatency;
Mask = HF_SignFilterImage(Map', 'SelectionMethod','zscore', 'zscoreThresh', -1, 'ForceSingleRegion', 1, 'MaskExpand', 1);
LowLatency = imresize(Mask, ImageSize);

X = ImageSize(1);
Y = ImageSize(2);
PMM = PixelPerMM.(Animal);

cAH = AHBottom(1);  
ACBounds = bwboundaries(ACX');
bound = ACBounds{1};
patch(cAH, bound(:, 2), bound(:, 1), [0.6, 0.8, 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off')
hold(cAH, 'on')
area(cAH, 0, 0, 'FaceColor', [0.6, 0.8, 0.8], 'EdgeColor', 'none', 'DisplayName', 'ACX', 'ShowBaseLine', 'off')
area(cAH, 0, 0, 'FaceColor', Colors(1, :), 'EdgeColor', 'none', 'DisplayName', 'Vocalization', 'ShowBaseLine', 'off', 'FaceAlpha', 0.5)
area(cAH, 0, 0, 'FaceColor', Colors(2, :), 'EdgeColor', 'none', 'DisplayName', 'Texture', 'ShowBaseLine', 'off', 'FaceAlpha', 0.5)
for j = 1:AnimalNum
    Animal = P.Animals{j};
    area(cAH, -10, -10, 'FaceColor', GreyColors(j, :), 'EdgeColor', 'none', 'DisplayName', Animal, 'ShowBaseLine', 'off', 'FaceAlpha', 0.5)
    for i = 1:numel(P.Variable)
        Variable = Measures{i};
        Map = TransImages.(Animal).(Variable);
        Mask = HF_SignFilterImage(Map', 'SelectionMethod','zscore', 'zscoreThresh',P.Zscore);
        bounds = bwboundaries(Mask);
        for q = 1:length(bounds)
            bound = bounds{q};
            patch(cAH, bound(:, 2), bound(:, 1), CombiColors(j, :, i), 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'HandleVisibility', 'off')
        end
    end
end
xlim(cAH, [0, ImageSize(1)])
ylim(cAH, [10, ImageSize(2)])
LLBounds = bwboundaries(LowLatency);
boundary = LLBounds{1};
plot(cAH, boundary(:, 2), boundary(:, 1), 'r', 'LineWidth', 2, 'DisplayName', 'Low Latency Area')


  plot(cAH,[0,0+PMM],[Y,Y],'k','LineWidth',1, 'HandleVisibility', 'off');
    text(cAH,0-P.ScaleBarSep,Y-5,'L','Rotation',90,'horiz','center',...
      'FontSize',P.ScaleBarSize)
    text(cAH,0-P.ScaleBarSep,Y-30,'M','Rotation',90,'horiz','center',...
      'FontSize',P.ScaleBarSize)

  plot(cAH,[0,0],[Y,Y-PMM],'k','LineWidth',1.5, 'HandleVisibility', 'off')
    text(cAH,0+5,Y+P.ScaleBarSep,'A','horiz','center',...
      'FontSize',P.ScaleBarSize)
    text(cAH,0+30,Y+P.ScaleBarSep,'P','horiz','center',...
      'FontSize',P.ScaleBarSize)
    text(cAH,0+16,Y-P.ScaleBarSep,'1mm','horiz','center',...
      'FontSize',P.ScaleBarSize)


set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
axis(cAH, 'off') 
legend(cAH, 'FontSize', 7, 'Position', [0.35, 0.05, 0.1, 0.1])
%% Plot Sizes

cAH = AHBottom(2);

X = [2, 6, 10];
Labels = {'Texture', 'Vocalization', 'Overlap'};

hold(cAH, 'on')
for i = 1:AnimalNum
    scatter(cAH, X, MaskSize.(P.Animals{i}), 100, AnimalColors(i, :), 'filled')
    plot(cAH, X, MaskSize.(P.Animals{i}), 'Color',  AnimalColors(i, :), 'HandleVisibility', 'off', 'LineWidth', 2)
end
ylabel(cAH, 'mm^2')
xticks(cAH, [2, 6, 10]);
xlim(cAH, [0, 11])
ylim(cAH, [0, 1.3])
xticklabels(cAH, Labels)
legend(cAH, P.Animals, 'FontSize', 7)   



