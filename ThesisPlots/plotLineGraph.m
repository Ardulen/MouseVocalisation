function plotLineGraph(P, AH, Labels, MaskSize)

cAH = AH;

X = [2, 6, 10];

hold(cAH, 'on')
for i = 1:P.AnimalNum
    scatter(cAH, X, MaskSize.(P.Animals{i}), 50, P.AnimalColors(i, :), 'filled', 'MarkerFaceAlpha', 0.8)
    plot(cAH, X, MaskSize.(P.Animals{i}), 'Color',  [P.AnimalColors(i, :), 0.8], 'HandleVisibility', 'off', 'LineWidth', 1.5)
end
ylabel(cAH, 'mm^2')
xticks(cAH, [2, 6, 10]);
xlim(cAH, [0, 12])
ylim(cAH, [0, 1.3])
xticklabels(cAH, Labels)
title(cAH, 'Area Sizes')
legend(cAH, P.Animals, 'FontSize', 6, 'Location', 'southwest')
cAH.FontSize = 8;