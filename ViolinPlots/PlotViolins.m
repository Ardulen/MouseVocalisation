function S = PlotViolins(varargin)

P = parsePairs(varargin);
checkField(P, 'Save', 0)
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Area', 'ACX')
checkField(P, 'AllVocs', 1)
checkField(P, 'FIG', 10)
checkField(P, 'Variables', {'SignifTest', 'OnOffsetAvg', 'ResponseRegionSize'})
checkField(P, 'VocFreqs', [4000, 8000, 32000])
checkField(P, 'Threshold', 1.5)


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
S = struct;
figure(P.FIG)
set(gcf, 'Color', 'w')
clf


for i = 1:VocFreqNum
    annotation('textbox','String', ['AUG Vocalization Response in ', P.Area],'Position',[0.25,0.96,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    S.SifnifTest.(Freq{i}) = multplots(P, i, i, 'SignifTest', '', 'AUG DF/F');
    annotation('textbox','String', ['Size of area containing pixels with values at least 2 std from mean'],'Position',[0.25,0.66,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    S.ResponseRegionSize.(Freq{i}) = multplots(P, i+3, i, 'ResponseRegionSize', '', 'Pixels');
    annotation('textbox','String', ['Size of area containing pixels above ', num2str(P.Threshold), ' DF/F'],'Position',[0.25,0.36,0.7,0.03],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    S.Threshold.(Freq{i}) = multplots(P, i+6, i, 'Threshold', 'PreTime', 'Pixels');
end

figure(P.FIG+1)
set(gcf, 'Color', 'w')
clf


end






function MultComp = multplots(P, PlotNum, DatNum, Dat, xlab, ylab)    
    subplot(3, 3, PlotNum)
    violinplots(squeeze(P.TotVioData.(Dat)(:, :, DatNum)), P.Params)
    title([num2str(P.VocFreqs(DatNum)), ' Hz'])
    xlabel(xlab)
    ylabel(ylab)
    Lims = [min(P.TotVioData.SignifTest, [], 'all')*1.1, max(P.TotVioData.(Dat), [], 'all')*1.1];
    ylim(Lims)
    [p, tbl, stats] = anova1(squeeze(P.TotVioData.(Dat)(:, :, DatNum)), P.Params, 'off');
    MultComp = multcompare(stats, 'Display', 'off');
end
