function MaskSize = plotCombinedMaps(P, AH, Maps, ImageSize, ACX, LowLatency, Pos)

cAH = AH;  
ACBounds = bwboundaries(ACX');
bound = ACBounds{1};
patch(cAH, bound(:, 2), bound(:, 1), [0.8, 0.9, 0.9], 'EdgeColor', 'none', 'HandleVisibility', 'off')
hold(cAH, 'on')
for i = 1:numel(P.DispNames)
    area(cAH, 0, 0, 'FaceColor', P.Colors(i, :), 'EdgeColor', 'none', 'DisplayName', P.DispNames{i}, 'ShowBaseLine', 'off', 'FaceAlpha', 0.5)
end
for j = 1:P.AnimalNum
    Animal = P.Animals{j};
    Ref = imref2d(ImageSize);
    load(['/mnt/data/Samuel/', Animal, '/Tf.mat']);
    area(cAH, -10, -10, 'FaceColor', P.GreyColors(j, :), 'EdgeColor', 'none', 'DisplayName', Animal, 'ShowBaseLine', 'off', 'FaceAlpha', 0.5)
    for i = 1:numel(P.Measures)
        Variable = P.Measures{i};
        TransMap = imwarp(Maps.(Animal).(Variable),Tf,"OutputView",Ref);
        if P.MaskGen
            Mask = HF_SignFilterImage(TransMap, 'SelectionMethod','zscore', 'zscoreThresh',P.Zscore(i));
        else
            Mask = TransMap;
        end
        if P.MaskSize
            MaskSize.(Animal)(i) = sum(Mask(:))/(P.PixelPerMM.(Animal)^2);
        end
        bounds = bwboundaries(Mask');
        for q = 1:length(bounds)
            bound = bounds{q};
            patch(cAH, bound(:, 2), bound(:, 1), P.CombiColors(j, :, i), 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'HandleVisibility', 'off')
        end
    end
end
xlim(cAH, [0, ImageSize(1)])
ylim(cAH, [10, ImageSize(2)])
LLBounds = bwboundaries(LowLatency);
if ~isempty(LLBounds)
    boundary = LLBounds{1};
    plot(cAH, boundary(:, 2), boundary(:, 1), 'r', 'LineWidth', 2, 'DisplayName', 'Low Latency Area')
end
    
if P.ScaleBar
    plotScaleBars(P, 'k', AH, 0, P.Y, 1.5)
end
area(cAH, 0, 0, 'FaceColor', [0.8, 0.9, 0.9], 'EdgeColor', 'none', 'DisplayName', 'ACX', 'ShowBaseLine', 'off')
set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
axis(cAH, 'off') 
cAH.XAxis.FontSize = 8;
if P.Legend
    legend(cAH, 'FontSize', 6, 'Position', Pos)%[0.35, 0.05, 0.1, 0.1])
end