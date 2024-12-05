function plotCombinedMaps(P, AH, ImageSize, ACX, LowLatency)


P.Y = ImageSize(2);
P.PMM = P.PixelPerMM.(P.Animals{1});

cAH = AH;  
ACBounds = bwboundaries(ACX');
bound = ACBounds{1};
patch(cAH, bound(:, 2), bound(:, 1), [0.8, 0.9, 0.9], 'EdgeColor', 'none', 'HandleVisibility', 'off')
hold(cAH, 'on')
area(cAH, 0, 0, 'FaceColor', [0.8, 0.9, 0.9], 'EdgeColor', 'none', 'DisplayName', 'ACX', 'ShowBaseLine', 'off')
area(cAH, 0, 0, 'FaceColor', P.Colors(1, :), 'EdgeColor', 'none', 'DisplayName', 'Texture', 'ShowBaseLine', 'off', 'FaceAlpha', 0.5)
area(cAH, 0, 0, 'FaceColor', P.Colors(2, :), 'EdgeColor', 'none', 'DisplayName', 'Vocalization', 'ShowBaseLine', 'off', 'FaceAlpha', 0.5)
for j = 1:P.AnimalNum
    Animal = P.Animals{j};
    load(['/mnt/data/Samuel/', Animal, '/Summary.mat'])
    ImageSize = size(Summary.(P.Measures{1}));
    Ref = imref2d(ImageSize);
    load(['mnt/data/Samuel/', Animal, '/Tf.mat']);
    area(cAH, -10, -10, 'FaceColor', P.GreyColors(j, :), 'EdgeColor', 'none', 'DisplayName', Animal, 'ShowBaseLine', 'off', 'FaceAlpha', 0.5)
    for i = 1:numel(P.Variable)
        Variable = P.Measures{i};
        TransMap = imwarp(Summary.(Variable),Tf,"OutputView",Ref);
        Mask = HF_SignFilterImage(TransMap', 'SelectionMethod','zscore', 'zscoreThresh',P.Zscore(i));
        bounds = bwboundaries(Mask);
        for q = 1:length(bounds)
            bound = bounds{q};
            patch(cAH, bound(:, 2), bound(:, 1), P.CombiColors(j, :, i), 'FaceAlpha', 0.5, 'EdgeColor', 'none', 'HandleVisibility', 'off')
        end
    end
end
xlim(cAH, [0, ImageSize(1)])
ylim(cAH, [10, ImageSize(2)])
LLBounds = bwboundaries(LowLatency);
boundary = LLBounds{1};
plot(cAH, boundary(:, 2), boundary(:, 1), 'r', 'LineWidth', 2, 'DisplayName', 'Low Latency Area')

plotScaleBars(P, 'k', AH, 0, P.Y, 1.5)

%   plot(cAH,[0,0+PMM],[Y,Y],'k','LineWidth',1, 'HandleVisibility', 'off');
%     text(cAH,0-P.ScaleBarSep,Y-5,'L','Rotation',90,'horiz','center',...
%       'FontSize',P.ScaleBarSize)
%     text(cAH,0-P.ScaleBarSep,Y-30,'M','Rotation',90,'horiz','center',...
%       'FontSize',P.ScaleBarSize)
% 
%   plot(cAH,[0,0],[Y,Y-PMM],'k','LineWidth',1.5, 'HandleVisibility', 'off')
%     text(cAH,0+5,Y+P.ScaleBarSep,'A','horiz','center',...
%       'FontSize',P.ScaleBarSize)
%     text(cAH,0+30,Y+P.ScaleBarSep,'P','horiz','center',...
%       'FontSize',P.ScaleBarSize)
%     text(cAH,0+16,Y-P.ScaleBarSep,'1mm','horiz','center',...
%       'FontSize',P.ScaleBarSize)


set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
axis(cAH, 'off') 
cAH.XAxis.FontSize = 8;
legend(cAH, 'FontSize', 7, 'Position', [0.35, 0.05, 0.1, 0.1])