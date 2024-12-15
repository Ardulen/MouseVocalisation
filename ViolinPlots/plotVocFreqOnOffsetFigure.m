function plotVocFreqOnOffsetFigure(Plot, PlotSil, varargin)

P = parsePairs(varargin);
checkField(P, 'Save', 0)
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'VocFreqs', [4, 8, 32])
checkField(P, 'FIG', 1001)

P.VocFreqNum = numel(P.VocFreqs);

figure(P.FIG);
set(gcf, 'Color', 'w')
clf

[~,AHTop] = axesDivide(1,1,[0.1, 0.75, 0.8, 0.12],[],0.4, 'c');
[~,AHBot] = axesDivide(2,1,[0.1, 0.55, 0.8, 0.12],[],0.4, 'c');
[~,AHSilTop] = axesDivide(1,1,[0.1, 0.35, 0.8, 0.12],[],0.4, 'c');
[~,AHSilBot] = axesDivide(2,1,[0.1, 0.15, 0.8, 0.12],[],0.4, 'c');

AHTops = [AHTop;AHSilTop];
AHBots = [AHBot; AHSilBot]';

VioAndTrace(P, 1, 1, Plot, AHTops, AHBots)
VioAndTrace(P, 2, 3, PlotSil, AHTops, AHBots)
legend(AHTops(1), 'Location', 'northwest', 'FontSize', 6)

end

function VioAndTrace(P, Ax, bAx, Plot, AHTops, AHBots)

    axes(AHTops(Ax))
    hold on
    for i = 1:10
        % Calculate the x-coordinate of each rectangle
        xCenter = 0.2*(i-1);

        % Use the rectangle function to create each rectangle
        r = rectangle('Position', [xCenter, -10, 0.1, 20], 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    end
    area(0, 0, 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'DisplayName', 'Vocalizations played')
    for i = 1:P.VocFreqNum
        plot(Plot.TimeVec-2.5, Plot.Trial(:, i), 'LineWidth', 2, 'DisplayName', [num2str(P.VocFreqs(i)), ' KHz'])
    end
    
    xlim([-0.5, 2])
    Lims = [min(Plot.Trial, [], 'all'), max(Plot.Trial, [], 'all')*1.1];
    ylim(Lims)
    ylabel('DF/F')
    xlabel('Time (s)')

    axes(AHBots(bAx))
    d = violinplot(Plot.VocFreqs, P.VocFreqs);
    title(['Response Strength'])
    xlabel('Vocalization Frequency (Hz)')
    ylabel('AUG DF/F')

    axes(AHBots(bAx+1))
    d = violinplot(Plot.OnOffset, P.VocFreqs);
    title('Onset-Offset')
    xlabel('Vocalization Frequency (Hz)')
    ylabel('AUG DF/F')
end


