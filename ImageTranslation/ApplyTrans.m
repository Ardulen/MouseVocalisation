function ApplyTrans(tfs, varargin)

P = parsePairs(varargin);
checkField(P,'FIG',1);
checkField(P, 'Source', 'VideoCalcium');
checkField(P, 'Animals', [193, 195, 196]);
checkField(P, 'Recordings', [201, 130, 193]);
checkField(P, 'Title', '');


PreTrans = struct;

AnimalNum = length(P.Animals);
for Animal = 1:AnimalNum
    Data = load(['/home/experimenter/dnp-backup/ControllerData/mouse', num2str(P.Animals(Animal)), '/R', num2str(P.Recordings(Animal)), '/Results/M.mat']);
    if Animal == 1
        MetricNames = fieldnames(Data.M.Metrics.Mean);

    end
    CraniotomyMask.(['mouse', num2str(P.Animals(Animal))]) = Data.M.Image.CraniotomyMask;
    for i = 1:length(MetricNames)
        MinValue = min(Data.M.Metrics.Mean.(MetricNames{i}), [], 'all');
        NonNegative = Data.M.Metrics.Mean.(MetricNames{i}) + abs(MinValue);
        RescaledImages.(MetricNames{i}) = (NonNegative/max(NonNegative, [], 'all'));
    end
    PreTrans.(['mouse', num2str(P.Animals(Animal))]) = RescaledImages;
end
MetricNum = length(MetricNames);
Ref = imref2d(size(PreTrans.(['mouse', num2str(P.Animals(1))]).(MetricNames{1})));

%% Set figure
MP = get(0,'MonitorPositions');
NY = MP(1,end); HPixels = 540;
FigureName=P.Title;
Fig = figure(P.FIG); clf; set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1250,HPixels]);
annotation('textbox','String', FigureName,'Position',[0.25,0.96,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
for Animal = 1:AnimalNum
    annotation('textbox','String', ['mouse', num2str(P.Animals(Animal))],'Position',[0.05,0.93-((Animal-1)*0.31),0.1,0.05],'Horiz','l','FontSize',8,'FontW','b','EdgeColor',[1,1,1]);
end
[~, AH] = axesDivide(MetricNum,AnimalNum,[0.02, 0.02, 1, 0.9],0.05,0.05, 'c');
AH = AH';
[~, AHArea] = axesDivide(MetricNum,AnimalNum,[0.02, 0.02, 1, 0.9],0.05,0.05, 'c');
AHArea = AHArea';


for Metric = 1:MetricNum
    [~,~,~] = HF_imagescCraniotomy(Fig,AH(Metric),AHArea(Metric), Data.M.Image.Xmm', Data.M.Image.Ymm', PreTrans.(['mouse', num2str(P.Animals(1))]).(MetricNames{Metric}), zeros(size(PreTrans.(['mouse', num2str(P.Animals(1))]).(MetricNames{1}))),CraniotomyMask.(['mouse', num2str(P.Animals(1))]), 'AlphaF', 1, 'AlphaB', 1, 'drawScaleBar', 0);
    title(AH(Metric), MetricNames{Metric}, 'FontSize', 6);
end

MITotal = 0;
CorrTotal = 0;
for Animal = 2:AnimalNum
    MITotal = 0;
    CorrTotal = 0;
    for Metric = 1:MetricNum
        moving = PreTrans.(['mouse', num2str(P.Animals(Animal))]).(MetricNames{Metric});
        moving(isnan(moving)) = 0;
        Fixed = PreTrans.(['mouse', num2str(P.Animals(1))]).(MetricNames{Metric});
        Fixed(isnan(Fixed)) = 0;
        TransImage = imwarp(moving,tfs.(['m', num2str(P.Animals(Animal))]),"OutputView",Ref);
        Corr = corr2(Fixed, TransImage);
        MI = mi(Fixed, TransImage);
        CorrTotal = CorrTotal + Corr;
        MITotal = MITotal + MI;
        cAH = AH((Metric)+(Animal-1)*MetricNum);
        cAHArea = AHArea((Metric)+(Animal-1)*MetricNum);
        [~,~,~] = HF_imagescCraniotomy(Fig,cAH,cAHArea,Data.M.Image.Xmm,Data.M.Image.Ymm, TransImage, zeros(size(TransImage)),CraniotomyMask.(['mouse', num2str(P.Animals(1))]), 'AlphaF', 1, 'AlphaB', 1, 'drawScaleBar', 0);
        hold(cAH, 'on');
        TransCranMask = imwarp(CraniotomyMask.(['mouse', num2str(P.Animals(Animal))]), tfs.(['m', num2str(P.Animals(Animal))]),"OutputView",Ref);
        Perimeter = bwperim(TransCranMask);
        Outline = bwboundaries(Perimeter');
        Outline = Outline{1}/Data.M.Image.PixelPerMM;
        plot(cAH, Outline(:,2), Outline(:,1), 'w', 'LineWidth', 1.5);
        title(cAH, [MetricNames{Metric}, ' Corr: ', sprintf('%.2f', Corr)], 'FontSize', 6);
    end
    annotation('textbox','String', ['TotalCorr: ', num2str(CorrTotal)],'Position',[0.15,0.93-((Animal-1)*0.31),0.1,0.05],'Horiz','l','FontSize',7,'FontW','b','EdgeColor',[1,1,1]);
    annotation('textbox','String', ['TotalMI: ', num2str(MITotal)],'Position',[0.25,0.93-((Animal-1)*0.31),0.1,0.05],'Horiz','l','FontSize',7,'FontW','b','EdgeColor',[1,1,1]);
end

end