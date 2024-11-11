function plotVocFreqsMasks(Plot, varargin)

P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'FIG', 20)
checkField(P, 'PreTimes', [0.5, 1, 3])

AnimalNum = numel(P.Animals);
NoiseBurstRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R4', 'R4', 'R3'});

Colors = [0.5, 0, 0.5;0.7, 0.3, 0.7;0.85, 0.6, 0.85];
Yellow = [1.0000, 1.0000, 0.6000;1.0000, 0.8500, 0.2000;0.8500, 0.6500, 0.1250;0.75, 0.55, 0.05];


for i =1:AnimalNum
    load(['/mnt/data/Samuel/', P.Animals{i}, '/VocFreqsMasks.mat'])
    Masks.(P.Animals{i}) = Mas.(P.Animals{i});

end

ImageSize = size(squeeze(Masks.(P.Animals{1}).VocFreqs(:, :, 1)));

Animal = P.Animals{1};
load(['/home/experimenter/dnp-backup/ControllerData/', Animal,'/', NoiseBurstRecordings(Animal), '/Results/evaluateNoiseBurst.mat']);
Mask = M.FilteredMetrics.SelPix.ACX;
ACX = imresize(Mask, ImageSize);


figure(P.FIG)
clf(P.FIG)
set(gcf, 'Color', 'w')

for j = 1:numel(P.PreTimes)
    subplot(2, 3, j)
    set(gca, 'Ydir', 'reverse')
    imagesc(ACX')
    colormap([1, 1, 1; 0.9, 0.9, 0.9])
    hold on
    title([num2str(P.PreTimes(j)), ' s'])
    for i = 1:AnimalNum
        Mask = squeeze(Masks.(P.Animals{i}).VocFreqs(:, :, j));
        bounds = bwboundaries(Mask);
        MaskSize.(P.Animals{i})(j) = sum(Mask(:))/(35.3 ^ 2);
        for q = 1:length(bounds)
            bound = bounds{q};
            patch(bound(:, 2), bound(:, 1), Colors(i, :), 'FaceAlpha', 0.3, 'EdgeColor', 'none')
        end
    end
    axis off
    axis equal
end


subplot(2, 3, 4)
X = [0.5, 1, 3];
hold on
area(0, 0, 'FaceColor', [0.9, 0.9, 0.9], 'EdgeColor', 'none', 'DisplayName', 'ACX')
for i = 1:AnimalNum
    scatter(X, MaskSize.(P.Animals{i}), 100, Colors(i, :), 'filled', 'DisplayName', P.Animals{i})
    plot(X, MaskSize.(P.Animals{i}), 'Color',  Colors(i, :), 'HandleVisibility', 'off', 'LineWidth', 2)
end
xlabel('PreTime (s)')
ylabel('mm^2')
title('Area sizes')
legend('Position', [0.18, 0.52, 0.1, 0.1], 'FontSize', 6)


subplot(2, 3, 5)
d = violinplots(Plot.Strength, P.PreTimes, 'ViolinColor', Yellow);
title(['Response Strength'])
xlabel('PreTime (s)')
ylabel('AUG DF/F')

subplot(2, 3, 6)
d = violinplots(Plot.Size./(35.3 ^ 2), P.PreTimes, 'ViolinColor', Yellow);
title('Response Size')
xlabel('PreTime (s)')
ylabel('mm²')





    
    