function plotRespTexVoc(T,R, varargin)

P = parsePairs(varargin);
checkField(P, 'Animal', 'mouse196')

Time = R.Frames.TimeAvg;
load("/mnt/data/Samuel/Global/Masks.mat");
Mask = Masks.(P.Animal).TexResp;

AreaOnly = T.Data.Full(:, :, :, 3) .* Mask;

AreaOnly(AreaOnly == 0) = NaN;

AreaMean = squeeze(nanmean(nanmean(AreaOnly, 2), 1));

figure;
set(gcf, 'Color', 'w')

plot(Time-2, AreaMean, 'Color', [0.600, 0.250, 0], 'LineWidth', 2)
hold on

Mask = Masks.(P.Animal).SilVocResp;

AreaOnly = T.Data.VocFreqsSil(:, :, :, 1) .* Mask;

AreaOnly(AreaOnly == 0) = NaN;

AreaMean = squeeze(nanmean(nanmean(AreaOnly, 2), 1));
plot(Time-2.5, AreaMean, 'Color', [0, 0.5, 0], 'LineWidth', 2)

xlim([-0.5, 2])
legend({'Texture Response', 'Vocalization Response'})