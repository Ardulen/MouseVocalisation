function plotVocFreqsMasks(varargin)

P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'FIG', 20)
checkField(P, 'PreTimes', [0.5, 1, 3])

AnimalNum = numel(P.Animals);

Colors = [0.5, 0, 0.5;0.7, 0.3, 0.7;0.85, 0.6, 0.85];

for i =1:AnimalNum
    load(['/mnt/data/Samuel/', P.Animals{i}, '/VocFreqsMasks.mat'])
    Masks.(P.Animals{i}) = Mas.(P.Animals{i});
end

figure(P.FIG)
clf(P.FIG)
set(gcf, 'Color', 'w')

for j = 1:numel(P.PreTimes)
    subplot(1, 4, j)
    axis equal
    set(gca, 'Ydir', 'reverse')
    axis off
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
end


subplot(1, 4, 4)
X = [0.5, 1, 3];
hold on
for i = 1:AnimalNum
    scatter(X, MaskSize.(P.Animals{i}), 100, Colors(i, :), 'filled')
    plot(X, MaskSize.(P.Animals{i}), 'Color',  Colors(i, :), 'HandleVisibility', 'off', 'LineWidth', 2)
end
xlabel('PreTime (s)')
ylabel('mm^2')
legend(P.Animals)    
    
    