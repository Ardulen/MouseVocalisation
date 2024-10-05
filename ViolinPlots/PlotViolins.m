function [Time, Frequency]= PlotViolins(TimeVec, varargin)

P = parsePairs(varargin);
checkField(P, 'Save', 0)
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Area', 'ACX')
checkField(P, 'AllVocs', 1)
checkField(P, 'FIG', 10)
checkField(P, 'Variables', {'SignifTest', 'OnOffsetAvg', 'ResponseRegionSize'})
checkField(P, 'VocFreqs', [4000, 8000, 32000])
checkField(P, 'Threshold', 1.5)


P.Blue = [0.6784, 0.8471, 0.9020;0.0000, 0.4471, 0.7412;0.0000, 0.2000, 0.4000];
P.Orange = [1.0000, 0.55000, 0.000;0.8, 0.35, 0.0000;0.600, 0.250, 0];
P.Yellow = [1.0000, 1.0000, 0.6000;1.0000, 0.8500, 0.2000;0.8500, 0.6500, 0.1250];
P.ColMat = cat(3, P.Blue, P.Orange, P.Yellow);


AnimalNum = numel(P.Animals);
VariableNum = numel(P.Variables);
ReshapedSize = [150, 144, 36, 3, 3];

for i = 1:AnimalNum
    Animal = P.Animals{i};
    if P.AllVocs
        Data.(Animal) = load(['/mnt/data/Samuel/', Animal, '/NewDs/D', P.Area,'All.mat']);
    else
        Data.(Animal) = load(['/mnt/data/Samuel/', Animal, '/NewDs/D', P.Area,'First.mat']);
    end
end
P.Params = Data.(Animal).D.Params;
VocFreqNum = numel(P.Params);


for j = 1:VariableNum
    Var = P.Variables{j};
    P.TotVioData.(Var) = Data.(P.Animals{1}).D.(Var);
    for i = 2:AnimalNum
        P.TotVioData.(Var) = cat(1, P.TotVioData.(Var), Data.(P.Animals{i}).D.(Var));
    end
end

Reshaped = reshape(Data.(P.Animals{1}).D.WholeVocResp, ReshapedSize);
for i = 2:AnimalNum
    Reshaped = cat(3, Reshaped, reshape(Data.(P.Animals{i}).D.WholeVocResp, ReshapedSize));
end


for q = 1:ReshapedSize(5)
    for j = 1:ReshapedSize(4)
        for i = 1:ReshapedSize(3)*3
            Map = Reshaped(:, :, i, j, q);
            P.TotVioData.Threshold(i, j, q) = sum(Map(:) > P.Threshold);
        end
    end
end



Freq = {'FourkHz', 'EightkHz', 'ThirtyTwokHz'};
figure(P.FIG)
set(gcf, 'Color', 'w')
clf


for i = 1:VocFreqNum
    annotation('textbox','String', ['AUG Vocalization Response in ', P.Area],'Position',[0.25,0.96,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    Time.SifnifTest.(Freq{i}) = multplots(P, i, i, 'SignifTest', '', 'Pixels');
    annotation('textbox','String', ['Size of area containing pixels with values at least 2 std from mean'],'Position',[0.25,0.66,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    Time.ResponseRegionSize.(Freq{i}) = multplots(P, i+3, i, 'ResponseRegionSize', '', 'Pixels');
    annotation('textbox','String', ['Size of area containing pixels above ', num2str(P.Threshold), ' DF/F'],'Position',[0.25,0.36,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    Time.Threshold.(Freq{i}) = multplots(P, i+6, i, 'Threshold', 'PreTime', 'Pixels');
end

Methods = fieldnames(P.TotVioData);

for i = 1:numel(Methods)
    P.TotVioData.Freqs(:, :, i) = reshape(P.TotVioData.(Methods{i}), [324, 3]);
end

figure(P.FIG+1)
set(gcf, 'Color', 'w')
clf



Frequency.SignifTest =  SinglePlot(P, 1, squeeze(P.TotVioData.Freqs(:, :, 1)), '', 'AUG DF/F', P.VocFreqs, ['AUG Vocalization Response in ', P.Area]);
text(2.985, 73, '*', 'FontSize', 20, 'Color', 'k');
Frequency.ResponseRegionSize =  SinglePlot(P, 2, squeeze(P.TotVioData.Freqs(:, :, 2)), '', 'Pixels', P.VocFreqs, ['Size of area containing pixels with values at least 2 std from mean']);
text(2.985, 130, '*', 'FontSize', 20, 'Color', 'k');
Frequency.Threshold =  SinglePlot(P, 3, squeeze(P.TotVioData.Freqs(:, :, 3)), '', 'Pixels', P.VocFreqs, ['Size of area containing pixels above ', num2str(P.Threshold), ' DF/F']);
text(0.985, 1022, '*', 'FontSize', 20, 'Color', 'k');


P.TotVioData.OnOff = reshape(P.TotVioData.OnOffsetAvg, [324, 3]);


figure(P.FIG+2)
set(gcf, 'Color', 'w')
clf


for i = 1:VocFreqNum
    annotation('textbox','String', ['AUG Vocalization Response - Offset Response in ', P.Area],'Position',[0.25,0.96,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    Time.OnOffset.(Freq{i}) = multplots(P, i, i, 'OnOffsetAvg', '', 'Pixels');
end

Frequency.OnOffset =  SinglePlot(P, 2, P.TotVioData.OnOff, '', 'AUG DF/F', P.VocFreqs, ['AUG Vocalization Response - offset response in ', P.Area]);
text(2.985, 160, '*', 'FontSize', 20, 'Color', 'k');


subplot(3, 1, 3)
hold on
for i = 1:10
    % Calculate the x-coordinate of each rectangle
    xCenter = 3+0.2*(i-1);

    % Use the rectangle function to create each rectangle
    r = rectangle('Position', [xCenter, -10, 0.1, 20], 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
end
for i = 1:VocFreqNum
    plot(TimeVec-2, Data.(P.Animals{2}).D.TrialAvg(:, 3, i), 'LineWidth', 2)
end
StrVocFreqs = arrayfun(@num2str, P.VocFreqs, 'UniformOutput', false);
legend(StrVocFreqs)
xlim([2.5, 5])
ylim([-1, 2])
ylabel('DF/F')
xlabel('Time (s)')

figure(P.FIG+3)
clf
hold on
for i = 1:10
    % Calculate the x-coordinate of each rectangle
    xCenter = 0.2*(i-1);

    % Use the rectangle function to create each rectangle
    r = rectangle('Position', [xCenter, -10, 0.1, 20], 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
end
for i = 1:3
    plot(TimeVec-P.Params(i)-2, Data.(P.Animals{1}).D.TrialAvg(:, i, 3), 'LineWidth', 2, 'Color', P.Yellow(i, :))
end
legend({'0.5 s', '1 s', '3 s'})
xlim([-0.5, 2])
ylim([-1, 2])
ylabel('DF/F')
xlabel('Time (s)')

figure(P.FIG+4)
clf
hold on
for i = 1:10
    % Calculate the x-coordinate of each rectangle
    xCenter = 0.2*(i-1);

    % Use the rectangle function to create each rectangle
    r = rectangle('Position', [xCenter, -10, 0.1, 20], 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
end
for i = 1:3
    plot(TimeVec-P.Params(i)-2, Data.(P.Animals{2}).D.TrialAvg(:, i, 2), 'LineWidth', 2, 'Color', P.Orange(i, :))
end
legend({'0.5 s', '1 s', '3 s'})
xlim([-0.5, 2])
ylim([-1, 2])
ylabel('DF/F')
xlabel('Time (s)')

figure(P.FIG+5)
clf
hold on
for i = 1:10
    % Calculate the x-coordinate of each rectangle
    xCenter = 0.2*(i-1);

    % Use the rectangle function to create each rectangle
    r = rectangle('Position', [xCenter, -10, 0.1, 20], 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
end
for i = 1:3
    plot(TimeVec-P.Params(i)-2, Data.(P.Animals{1}).D.TrialAvg(:, i, 1), 'LineWidth', 2, 'Color', P.Blue(i, :))
end
legend({'0.5 s', '1 s', '3 s'})
xlim([-0.5, 2])
ylim([-1, 2])
ylabel('DF/F')
xlabel('Time (s)')
end




function MultComp = multplots(P, PlotNum, DatNum, Dat, xlab, ylab)    
    subplot(3, 3, PlotNum)
    d = violinplots(squeeze(P.TotVioData.(Dat)(:, :, DatNum)), P.Params, 'ViolinColor', P.ColMat(:, :, DatNum));
    title([num2str(P.VocFreqs(DatNum)), ' Hz'])
    xlabel(xlab)
    ylabel(ylab)
    Lims = [min(P.TotVioData.(Dat), [], 'all'), max(P.TotVioData.(Dat), [], 'all')*1.1];
    ylim(Lims)
    [p, tbl, stats] = anova1(squeeze(P.TotVioData.(Dat)(:, :, DatNum)), P.Params, 'off');
    disp(p)
    MultComp = multcompare(stats, 'Display', 'off');
end


function Comp = SinglePlot(P, PlotNum, Dat, xlab, ylab, Params, Title)
    subplot(3, 1, PlotNum)
    d = violinplots(Dat, Params);
    title(Title)
    xlabel(xlab)
    ylabel(ylab)
    [p, tbl, stats] = anova1(Dat, P.Params, 'off');
    disp(p)
    Comp = multcompare(stats, 'Display', 'off');
end
    
