function [MaskSize, Masks] = plotContourMaps(P, AH)

for j = 1:P.AnimalNum
    cAH = AH(j);
    Animal = P.Animals{j};
    load(['/mnt/data/Samuel/', Animal, '/Summary.mat'])
    ImageSize = size(Summary.(P.Measures{1}));
    Ref = imref2d(ImageSize);
    load(['mnt/data/Samuel/', Animal, '/Tf.mat']);
    imagesc(cAH, P.Background.(Animal)')
    colormap('bone')
    hold(cAH, 'on')
    for i = 1:numel(P.Measures)
        Variable = P.Measures{i};
        TransMap = imwarp(Summary.(Variable),Tf,"OutputView",Ref);
        Mask = HF_SignFilterImage(TransMap', 'SelectionMethod','zscore', 'zscoreThresh',P.Zscore(i));
        Masks.(Animal).(P.Measures{i}) = Mask;
        bounds = bwboundaries(Mask);
        MaskSize.(Animal)(i) = sum(Mask(:))/(P.PixelPerMM.(Animal)^2);
        for q = 1:length(bounds)
            bound = bounds{q};
            patch(cAH, bound(:, 2), bound(:, 1), P.Colors(i, :), 'FaceAlpha', 0.5, 'EdgeColor', 'none')
        end
    end
    OverlapMask = Masks.(Animal).(P.Measures{1}) & Masks.(Animal).(P.Measures{2});
    MaskSize.(Animal)(i+1) = sum(OverlapMask(:))/(P.PixelPerMM.(Animal) ^ 2);
    axis(cAH, 'off')
    set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
    title(cAH, Animal)
end