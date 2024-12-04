function CalcLineGraph(varargin)

P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Params', {'SilVocResp', 'SusLvl', 'TexVocResp'})
checkField(P, 'Zscore', [2, -2, 2])
checkField(P, 'FIG', 200)
checkField(P, 'Color', 'Turq')


AnimalNum = numel(P.Animals);
D = struct;

Blue = [0.6, 0.8, 1.0;  % Light Blue
          0.3, 0.5, 1.0;  % Medium Blue
          0.1, 0.2, 0.9]; % Dark Blue

P.Turq = [0.75, 1, 1;
        0.25, 0.88, 0.82;
        0, 0.65, 0.65];
    
P.Grurple = [0.5, 0.65, 0.7;
       0.29, 0.45, 0.51;
       0.1, 0.15, 0.3];
   
P.Violet =  [0.8, 0.6, 0.9;
           0.4, 0.2, 0.61;
           0.2, 0.2, 0.6];

    
MaskCol = [0, 0.5, 0;
           0.1, 0.2, 0.7;
           0.3, 0, 0.3];
      
figure(P.FIG)
set(gcf, 'Color', 'w')
clf;
for i = 1:AnimalNum
    subplot(2, 3, i)    
    axis equal
    set(gca, 'Ydir', 'reverse')
    axis off
    load(['/mnt/data/Samuel/', P.Animals{i}, '/Summary.mat'])
    Average = load(['/mnt/data/Samuel/', P.Animals{i}, '/AverageRaw.mat']);
    if i>1
        load(['mnt/data/Samuel/', P.Animals{i}, '/Tf.mat']);
    end
    D.(P.Animals{i}) = Summary;
    imagesc(Average.D')
    colormap('bone')
    hold on
    for j = 1:numel(P.Params)
        Mask = HF_SignFilterImage(Summary.(P.Params{j}), 'SelectionMethod','zscore', 'zscoreThresh',P.Zscore(j));
        %TransMask = imwarp(Moving,tfs.(P.Animals{Animal}),"OutputView",Ref);
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
Labels = {'Vocalization', 'Sustained Level', 'Overlap'};

subplot(2, 3, 1)
hold on
for i = 1:AnimalNum
    scatter(X, MaskSize.(P.Animals{i}), 100, P.(P.Color)(i, :), 'filled')
    plot(X, MaskSize.(P.Animals{i}), 'Color',  P.(P.Color)(i, :), 'HandleVisibility', 'off', 'LineWidth', 2)
end
ylabel('mm^2')
xticks([1, 2, 3]);
xlim([0, 4])
ylim([0, 1.5])
xticklabels(Labels)
legend(P.Animals)    