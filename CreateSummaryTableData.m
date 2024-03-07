function [Data, h] = CreateSummaryTableData(T, varargin)

P = parsePairs(varargin);
checkField(P,'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P,'Recordings',[201, 130, 193]) 



Data = struct;
Measures = fieldnames(T{1}.Summary);
DataSize = size(T{1}.Summary.(Measures{1}));
%Calc Mean response within each area for each animal relative to the max
%response for each measure
for i = 1:numel(P.Animals)
    [~, ~, ~, ~, TuningR] = C_showCortexRegionsTuningWF('Animal', P.Animals{i}, 'FIG', 0);
    Data.(P.Animals{i}) = zeros([length(TuningR.AreaNames), length(Measures)]);
    for j = 1:length(TuningR.AreaNames)
        for k = 1:length(Measures)
            Mask = imresize(TuningR.Areas(:, :, j), DataSize);
            Map = T{i}.Summary.(Measures{k});
            AreaData = Map.*Mask;
            AreaData(AreaData == 0) = NaN;
            Data.(P.Animals{i})(j, k) = nanmean(AreaData, 'all')/max(Map, [], 'all');
        end
    end
end
%Averaging and determining variability
Data.Average = zeros([length(TuningR.AreaNames), length(Measures), 2]);
for j = 1:length(TuningR.AreaNames)
    for k = 1:length(Measures)
        results = zeros(1, 3);
        for i = 1:numel(P.Animals)
            results(i) = Data.(P.Animals{i})(j, k);
        end
        Data.Average(j, k, 1) = mean(results);
        Data.Average(j, k, 2) = var(results);
    end
end


figure;

for i = 1:numel(P.Animals)
    subplot(numel(P.Animals)+1, 1, i);
    h{i} = heatmap(Measures, TuningR.AreaNames, Data.(P.Animals{i}));
    colormap(jet);
    caxis([-1, 1]);
    title(P.Animals{i});
    h{i}.FontSize = 8;
end

Alphavalues = 1-Data.Average(:, :, 2)*5;

subplot(numel(P.Animals)+1, 1, 4);
h{4} = imagesc(Data.Average(:, :, 1));
colormap(jet);
caxis([-1, 1]);
title('Average');
colorbar
set(h{4}, 'AlphaData', Alphavalues);
xticks(1:length(Measures));
yticks(1:length(TuningR.AreaNames));
xticklabels(Measures);
yticklabels(TuningR.AreaNames);
for i = 1:size(Data.Average(:, :, 1), 1)
    for j = 1:size(Data.Average(:, :, 1), 2)
        text(j, i, sprintf('%.2f', Data.Average(i, j, 1)), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'Color', 'k');
    end
end

figTitle = suptitle('Vocalization Response per Area');
% Adjust the position of the overall title
newTitlePosition = get(figTitle, 'Position');
newTitlePosition(2) = newTitlePosition(2) + 0.02; % Adjust the value as needed
set(figTitle, 'Position', newTitlePosition);

figure; 

h{5} = heatmap(Measures, TuningR.AreaNames, Data.Average(:, :, 2));
colormap(jet);
title('Variance');
h{5}.FontSize = 8;
caxis([-0.15, 0.15]);

end