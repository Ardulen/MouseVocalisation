function [Time, Frequency, Plot]= PlotViolins(varargin)

P = parsePairs(varargin);
checkField(P, 'Save', 0)
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Area', 'ACX')
checkField(P, 'AllVocs', 1)
checkField(P, 'FIG', 10)
checkField(P, 'Variables', {'SignifTest', 'OnOffsetAvg', 'ResponseRegionSize'})
checkField(P, 'VocFreqs', [4000, 8000, 32000])
checkField(P, 'Threshold', 1.5)
checkField(P, 'Silence', 0)


P.Blue = [0.6784, 0.8471, 0.9020;0.0000, 0.4471, 0.7412;0.0000, 0.2000, 0.4000;0, 0.1, 0.2];
P.Orange = [1.0000, 0.55000, 0.000;0.8, 0.35, 0.0000;0.600, 0.250, 0;0.4, 0.2, 0];
P.Yellow = [1.0000, 1.0000, 0.6000;1.0000, 0.8500, 0.2000;0.8500, 0.6500, 0.1250;0.75, 0.55, 0.05];
P.ColMat = cat(3, P.Blue, P.Orange, P.Yellow);


P.AnimalNum = numel(P.Animals);
VariableNum = numel(P.Variables);



if P.Silence
    EndPhrase = 'Sil';
    Location = 'Silent/';
    ReshapedSize = [150, 144, 10, 4, 3];
else
    EndPhrase = '';
    Location = '';
    ReshapedSize = [150, 144, 36, 3, 3];
end


if P.Silence
    Data = DataLoad(P, EndPhrase, Location);
else
    for i = 1:P.AnimalNum
        Animal = P.Animals{i};
        if P.AllVocs
            Data.(Animal) = load(['/mnt/data/Samuel/', Animal, '/NewDs/D', P.Area,'All.mat']);
        else
            Data.(Animal) = load(['/mnt/data/Samuel/', Animal, '/NewDs/D', P.Area,'First.mat']);
        end
    end
end

load('/mnt/data/Samuel/Global/TimeVec.mat')


for j = 1:VariableNum
    Var = P.Variables{j};
    P.TotVioData.(Var) = Data.(P.Animals{1}).D.(Var);
    for i = 2:P.AnimalNum
        P.TotVioData.(Var) = cat(1, P.TotVioData.(Var), Data.(P.Animals{i}).D.(Var));
    end
end

if P.Silence
    Reshaped = Data.(P.Animals{1}).D.SilResp;
    for i = 2:P.AnimalNum
        Reshaped = cat(3, Reshaped, Data.(P.Animals{i}).D.SilResp);
    end
    P.Params = [0.5, 1, 3, 5];
else
    P.Params = Data.(P.Animals{1}).D.Params;
    Reshaped = reshape(Data.(P.Animals{1}).D.WholeVocResp, ReshapedSize);
    for i = 2:P.AnimalNum
        Reshaped = cat(3, Reshaped, reshape(Data.(P.Animals{i}).D.WholeVocResp, ReshapedSize));
    end
end
VocFreqNum = numel(P.VocFreqs);

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
    annotation('textbox','String', ['AUG Vocalization Response in ', P.Area, '', EndPhrase],'Position',[0.25,0.96,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    Time.SifnifTest.(Freq{i}) = multplots(P, i, i, 'SignifTest', '', 'Pixels');
    annotation('textbox','String', ['Size of area containing pixels with values at least 2 std from mean', '', EndPhrase],'Position',[0.25,0.66,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    Time.ResponseRegionSize.(Freq{i}) = multplots(P, i+3, i, 'ResponseRegionSize', '', 'Pixels');
    annotation('textbox','String', ['Size of area containing pixels above ', num2str(P.Threshold), ' DF/F', '', EndPhrase],'Position',[0.25,0.36,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    Time.Threshold.(Freq{i}) = multplots(P, i+6, i, 'Threshold', 'PreTime', 'Pixels');
end

Methods = fieldnames(P.TotVioData);

if P.Silence
    for i = 1:numel(Methods)
        P.TotVioData.Freqs(:, :, i) = reshape(P.TotVioData.(Methods{i}), [120, 3]);
    end
else
    for i = 1:numel(Methods)
        P.TotVioData.Freqs(:, :, i) = reshape(P.TotVioData.(Methods{i}), [324, 3]);
    end
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

if P.Silence
    P.TotVioData.OnOff = reshape(P.TotVioData.OnOffsetAvg, [120, 3]);
else
    P.TotVioData.OnOff = reshape(P.TotVioData.OnOffsetAvg, [324, 3]);
end

figure(P.FIG+2)
set(gcf, 'Color', 'w')
clf


for i = 1:VocFreqNum
    annotation('textbox','String', ['AUG Vocalization Response - Offset Response in ', P.Area],'Position',[0.25,0.96,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    Time.OnOffset.(Freq{i}) = multplots(P, i, i, 'OnOffsetAvg', '', 'Pixels');
end

Frequency.OnOffset =  SinglePlot(P, 2, P.TotVioData.OnOff, 'frequency (kHz)', 'AUG DF/F', [4, 8, 32], ['AUG Vocalization Response - offset response in ', P.Area]);
text(2.985, 160, '*', 'FontSize', 20, 'Color', 'k');

if P.Silence
    PerAnimalTrial = zeros([size(Data.(P.Animals{1}).D.TrialAvg, 1), numel(P.Params), VocFreqNum, P.AnimalNum]);
else
    PerAnimalTrial = zeros([size(Data.(P.Animals{1}).D.TrialAvg, 1), numel(P.Params), VocFreqNum, P.AnimalNum]);
end
for i = 1:P.AnimalNum
    PerAnimalTrial(:, :, :, i) = Data.(P.Animals{i}).D.TrialAvg;
end
AllAnimalTrials = squeeze(nanmean(PerAnimalTrial, 4));
AllAnimalTrials(:, 2, :) = [AllAnimalTrials(51:end, 2, :); zeros(50, 1, 3)];
AllAnimalTrials(:, 3, :) = [AllAnimalTrials(251:end, 3, :); zeros(250, 1, 3)];
P.TotVioData.TrialAvg = squeeze(nanmean(AllAnimalTrials, 2));


subplot(3, 1, 3)
hold on
for i = 1:10
    % Calculate the x-coordinate of each rectangle
    xCenter = 0.2*(i-1);

    % Use the rectangle function to create each rectangle
    r = rectangle('Position', [xCenter, -10, 0.1, 20], 'FaceColor', [0.8, 0.8, 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
end
for i = 1:VocFreqNum
    plot(TimeVec-2.5, P.TotVioData.TrialAvg(:, i), 'LineWidth', 2)
end
StrVocFreqs = arrayfun(@num2str, P.VocFreqs, 'UniformOutput', false);
legend(StrVocFreqs)
xlim([-0.5, 2])
Lims = [min(P.TotVioData.TrialAvg, [], 'all'), max(P.TotVioData.TrialAvg, [], 'all')*1.1];
ylim(Lims)
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
Lims = [min(Data.(P.Animals{1}).D.TrialAvg(:, :, 2), [], 'all'), max(Data.(P.Animals{1}).D.TrialAvg(:, :, 2), [], 'all')*1.1];
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
Lims = [min(Data.(P.Animals{1}).D.TrialAvg(:, :, 2), [], 'all'), max(Data.(P.Animals{1}).D.TrialAvg(:, :, 2), [], 'all')*1.1];
ylim(Lims)
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


Plot.Strength = P.TotVioData.SignifTest(:, :, 3);
Plot.Size = P.TotVioData.Threshold(:, :, 3);
Plot.VocFreqs = P.TotVioData.Freqs(:, :, 1);
Plot.OnOffset = P.TotVioData.OnOff;
Plot.Trial = P.TotVioData.TrialAvg;
Plot.TimeVec = TimeVec;
end




function MultComp = multplots(P, PlotNum, DatNum, Dat, xlab, ylab)    
    subplot(3, 3, PlotNum)
    d = violinplot(squeeze(P.TotVioData.(Dat)(:, :, DatNum)), P.Params, 'ViolinColor', P.ColMat(1, :, DatNum));
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
    d = violinplot(Dat, Params);
    title(Title)
    xlabel(xlab)
    ylabel(ylab)
    [p, tbl, stats] = anova1(Dat, Params, 'off');
    disp(p)
    Comp = multcompare(stats, 'Display', 'off');
end


function Data = DataLoad(P, EndPhrase, Location)
    for i = 1:P.AnimalNum
        Animal = P.Animals{i};
        if P.AllVocs
            Data.(Animal) = load(['/mnt/data/Samuel/', Animal, '/NewDs/', Location, 'D', P.Area,'All', EndPhrase, '.mat']);
        else
            Data.(Animal) = load(['/mnt/data/Samuel/', Animal, '/NewDs/', Location, 'D', P.Area,'First', EndPhrase, '.mat']);
        end
    end
end     
        
        