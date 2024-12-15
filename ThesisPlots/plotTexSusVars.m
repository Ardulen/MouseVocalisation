function plotTexSusVars(varargin)

P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Variable', {'MaxTexResp', 'SustainedLvlMap'})
checkField(P, 'Measures', {'MaxTexResp', 'SustainedLvlMap'})
checkField(P, 'FIG', 400)
checkField(P, 'Zscore', [2, -2])
checkField(P, 'Area', 'ACX')
checkField(P, 'ScaleBarSize', 6)
checkField(P, 'ScaleBarSep', 8)
checkField(P, 'Save', 0)
checkField(P, 'Vars', [0.02, 0.2, 0.4])
checkField(P, 'Corrs', [0, 0.8])

P.AnimalNum = numel(P.Animals);
VariableNum = numel(P.Variable);
TotVarNum = numel(P.Vars)*numel(P.Corrs);
VocalizationRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R201', 'R130', 'R193'});
NoiseBurstRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R4', 'R4', 'R3'});

P.Colors = [1, 0.5, 0;0, 0, 1];
Orange = [0.8, 0.3, 0;1, 0.5, 0;1, 0.6, 0.2];
Blue = [0, 0, 0.5;0, 0, 1;0.3, 0.3, 1];
P.CombiColors = cat(3, Orange, Blue);
P.GreyColors = [0.1, 0.1, 0.1;0.3, 0.3, 0.3;0.5, 0.5, 0.5];
P.AnimalColors = [0.7, 0.2, 0.4;0.6, 0.5, 0.7;0.6, 0.7, 0.3];
P.ViolinColors = [0.9, 0.6, 0.9;0.7, 0.9, 0.4];

VarNames = cell([6, 1]);
Titles = cell([6, 1]);
for j = 1:numel(P.Corrs)
    for i = 1:numel(P.Vars)
        if P.Corrs(j) == 0
            VarNames{i+(j-1)*3} = ['LowCFCVar', num2str(P.Vars(i)*100)];
            Titles{i+(j-1)*3} = ['Low CFC Var: ', num2str(P.Vars(i))];
        else
            VarNames{i+(j-1)*3} = ['HighCFCVar', num2str(P.Vars(i)*100)];
            Titles{i+(j-1)*3} = ['High CFC Var: ', num2str(P.Vars(i))];
        end
    end
end


MP = get(0,'MonitorPositions');
NY = MP(1,end); HPixels = 750;
Fig = figure(P.FIG);
clf(P.FIG)
FigureName = 'Vocalization versus Texture';
set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,700, HPixels]);
set(gcf, 'Color', 'w')

[~,AHTop] = axesDivide(3,2,[0.02, 0.59, 0.7, 0.38],[],0.3, 'c');
AHTop = AHTop';
[~, AHMiddle] = axesDivide(2,1,[0.07, 0.25, 0.9, 0.3], [], 0.5, 'c');
[~,AHBottom] = axesDivide(2,1,[0.07, 0.06, 0.9, 0.15], [], 0.5, 'c');

%% Calc Masks 

for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    load(['/mnt/data/Samuel/', (Animal), '/TexSusVarMaps.mat'])
    for j = 1:VariableNum
        Var = P.Variable{j};
        Mean = mean(T.(Var), 'all');
        STD = std(T.(Var), [], 'all');
        for k = 1:TotVarNum
            Z = (squeeze(T.(Var)(:, :, k))-Mean)/STD;
            if P.Zscore(j)<0
              Mask = logical(Z<P.Zscore(j));
            else
              Mask = logical(Z>P.Zscore(j));
            end
            Masks.(VarNames{k}).(Animal).(Var) = Mask;
        end
    end
end

%% Plot Masks

for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    load(['/home/experimenter/dnp-backup/ControllerData/',Animal, '/', VocalizationRecordings(Animal), '/Results/M.mat'])
    P.Background.(Animal) = M.Image.AnatomyFrame;
    P.PixelPerMM.(Animal) = M.Image.PixelPerMM;
end

ImageSize = size(Masks.(VarNames{1}).(Animal).(Var));
P.Y = ImageSize(2);
P.PMM = P.PixelPerMM.(P.Animals{1});
Animal = P.Animals{1};
load(['/home/experimenter/dnp-backup/ControllerData/', Animal,'/', NoiseBurstRecordings(Animal), '/Results/evaluateNoiseBurst.mat']);
Mask = M.FilteredMetrics.SelPix.ACX;
ACX = imresize(Mask, ImageSize);

Map = M.Metrics.Median.OnsetLatency;
Mask = HF_SignFilterImage(Map', 'SelectionMethod','zscore', 'zscoreThresh', -1, 'ForceSingleRegion', 1, 'MaskExpand', 1);
LowLatency = imresize(Mask, ImageSize);


P.MaskGen = 0;


P.ScaleBar = 0;
P.Legend = 1;
P.MaskSize = 1; 
P.DispNames = {'Texture', 'Sustained Level'};
for i = 1:TotVarNum
    cAH = AHTop(i);
    title(cAH, Titles{i})
    MaskSize.(VarNames{i}) = plotCombinedMaps(P, cAH, Masks.(VarNames{i}), ImageSize, ACX, LowLatency, [0.85, 0.75, 0.05, 0.05]);
    P.Legend = 0;
end
plotScaleBars(P, 'k', AHTop(1), 0, P.Y, 1.5)

%% plot Line Graphs
X = [2, 6, 10];
Titles = {'Low CFC', 'High CFC'};
for j = 1:numel(P.Corrs)
    cAH = AHMiddle(j);

    

    hold(cAH, 'on')
    for k = 1:numel(P.Variable)
        for i = 1:P.AnimalNum
            scatter(cAH, X, [MaskSize.(VarNames{1+(j-1)*3}).(P.Animals{i})(k), MaskSize.(VarNames{2+(j-1)*3}).(P.Animals{i})(k), MaskSize.(VarNames{3+(j-1)*3}).(P.Animals{i})(k)] , 50, P.CombiColors(i, :, k), 'filled', 'HandleVisibility', 'off')
            plot(cAH, X, [MaskSize.(VarNames{1+(j-1)*3}).(P.Animals{i})(k), MaskSize.(VarNames{2+(j-1)*3}).(P.Animals{i})(k), MaskSize.(VarNames{3+(j-1)*3}).(P.Animals{i})(k)], 'Color',  P.CombiColors(i, :, k), 'HandleVisibility', 'off', 'LineWidth', 1.5)
        end
    end
    xticks(cAH, X)
    xticklabels(cAH, [])
    xlim(cAH, [0, 12])
    
    title(cAH, Titles{j})
    cAH.FontSize = 8;
end
ylabel(AHMiddle(1), 'mm^2')

cAH = AHMiddle(1);

scatter(cAH, -10, -10, 50, P.Colors(1, :), 'filled', 'DisplayName', P.DispNames{1})
scatter(cAH, -10, -10, 50, P.Colors(2, :), 'filled', 'DisplayName', P.DispNames{2})
for i = 1:P.AnimalNum
    scatter(cAH, -10, -10, 50, P.GreyColors(i, :), 'filled', 'DisplayName', P.Animals{i}, 'MarkerFaceAlpha', 0.7)
end

legend(cAH, 'FontSize', 6, 'Position', [0.42, 0.50, 0.05, 0.05])

%% plot Violins

load(['/mnt/data/Samuel/', P.Animals{1}, '/SusLvls.mat'])
ViolinData = D.Signif;
TestData = D.AreaData;
Params = D.Params;

for i = 2:P.AnimalNum
    Animal = P.Animals{i};
    load(['/mnt/data/Samuel/', Animal, '/SusLvls.mat'])
    ViolinData = cellfun(@(x, y) [x,y], ViolinData, D.Signif, 'UniformOutput', false);
    TestData = cellfun(@(x, y) [x,y], TestData, D.AreaData, 'UniformOutput', false);
    Params = cellfun(@(x, y) [x;y], Params, D.Params, 'UniformOutput', false);
end
CompNames = {'LowCFC', 'HighCFC'};
for i = 1:numel(P.Corrs)
    [p, ~, stats] = anova1(TestData{i}, Params{i}, 'off');
    disp(p)
    Comp.(CompNames{i}) = multcompare(stats, 'Display', 'off');
end

for i = 1:numel(P.Corrs)
    cAH = AHBottom(i);
    y = max(TestData{i})*110;
    hold(cAH, 'on')
    for j = 1:numel(P.Vars)-1
        yloc = y+1*j;
        plot(cAH, [j j j+1 j+1], [yloc-0.5 yloc yloc yloc-0.5], 'k', 'LineWidth', 0.5, 'Clipping', 'Off')
        PVal = Comp.(CompNames{i})(j, 6);
        PValCheck(PVal, j+0.5, yloc, cAH)
    end
    plot(cAH, [1 1 3 3], [y-0.5+3.5 y+3.5 y+3.5 y-0.5+3.5], 'k', 'LineWidth', 0.5, 'Clipping', 'off')
    PValCheck(PVal, double(2), double(y+3.5), cAH)
    axes(cAH)
    violinplot(100.*vertcat(ViolinData{i, :})', arrayfun(@num2str, P.Vars, 'UniformOutput', false), 'ViolinColor', P.ViolinColors(i, :))
    xlabel('Variance')
    set(gca, 'FontSize', 8)
    ylim(cAH, [-7, 7])
end
ylabel(AHBottom(1), 'DF/F')
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