function CalcLineGraph(varargin)

P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Params', {'TexVocResp', 'SusLvl'})
checkField(P, 'Zscore', [2, -2])
checkField(P, 'FIG', 200)


AnimalNum = numel(P.Animals);

D = struct;

Blue = [0.6, 0.8, 1.0;  % Light Blue
          0.3, 0.5, 1.0;  % Medium Blue
          0.1, 0.2, 0.9]; % Dark Blue

MaskCol = [0.7, 0.3, 0.7;
           0.1, 0.2, 0.9];
      
figure(P.FIG)
clf;
for i = 1:AnimalNum
    subplot(1, 3, i)    
    axis equal
    set(gca, 'Ydir', 'reverse')
    axis off
    load(['/mnt/data/Samuel/', P.Animals{i}, '/Summary.mat'])
    D.(P.Animals{i}) = Summary;
    for j = 1:numel(P.Params)
        Mask = HF_SignFilterImage(Summary.(P.Params{j}), 'SelectionMethod','zscore', 'zscoreThresh',P.Zscore(j));
        Masks.(P.Params{j}) = Mask;
        bounds = bwboundaries(Mask');
        MaskSize.(P.Animals{i})(j) = sum(Mask(:))/(35.3 ^ 2);
        for q = 1:length(bounds)
            bound = bounds{q};
            patch(bound(:, 2), bound(:, 1), MaskCol(j, :), 'FaceAlpha', 0.5, 'EdgeColor', 'none')
        end
    end
    OverlapMask = Masks.(P.Params{1}) & Masks.(P.Params{2});
    MaskSize.(P.Animals{i})(j+1) = sum(OverlapMask(:))/(35.3 ^ 2);
end

X = [1, 2, 3];

figure(P.FIG+1);
clf
hold on
for i = 1:AnimalNum
    scatter(X, MaskSize.(P.Animals{i}), 100, Blue(i, :), 'filled')
    plot(X, MaskSize.(P.Animals{i}), 'Color',  Blue(i, :), 'HandleVisibility', 'off', 'LineWidth', 2)
end
xlabel('PreTime (s)')
ylabel('mm^2')
legend(P.Animals)    