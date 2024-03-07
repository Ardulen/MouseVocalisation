function tform = CalcOptimalTrans(Met, varargin)

P = parsePairs(varargin);
checkField(P, 'Animals', [193, 195, 196]);
checkField(P, 'Recordings', [201, 130, 193]);

PreTrans = struct;
%rescale images
tform =  struct;
AnimalNum = length(P.Animals);
for Animal = 1:AnimalNum
    Data = load(['/home/experimenter/dnp-backup/ControllerData/mouse', num2str(P.Animals(Animal)), '/R', num2str(P.Recordings(Animal)), '/Results/M.mat']);
    if Animal == 1
        MetricNames = fieldnames(Data.M.Metrics.Mean);
        CraniotomyMask = Data.M.Image.CraniotomyMask;
    end
    for k = 1:length(MetricNames)
        MinValue = min(Data.M.Metrics.Mean.(MetricNames{k}), [], 'all');
        NonNegative = Data.M.Metrics.Mean.(MetricNames{k}) + abs(MinValue);
        NonNegative(isnan(NonNegative)) = 0;
        RescaledImages.(MetricNames{k}) = (NonNegative/max(NonNegative, [], 'all'));
    end
    PreTrans.(['mouse', num2str(P.Animals(Animal))]) = RescaledImages;
end
MetricNum = length(MetricNames);
    

fixed = PreTrans.(['mouse', num2str(P.Animals(1))]).(MetricNames{Met});

figure;
colormap('jet')
colorbar
subplot(2, 3, 1);
imagesc(fixed);
title('M193');
daspect([1, 1, 1]);



subplot(2, 3, 4);
imagesc(fixed);
title('M193');
daspect([1, 1, 1]);


[optimizer,metric] = imregconfig("monomodal");
optimizer.MaximumIterations = 500;
optimizer.GradientMagnitudeTolerance = 1.0e-05;
optimizer.RelaxationFactor = 0.5;
optimizer.MaximumStepLength = 0.1;
Titles = {'m195', 'm196'};
for i = 1:2
    moving = PreTrans.(['mouse', num2str(P.Animals(i+1))]).(MetricNames{Met});
    subplot(2, 3, i+1)
    imagesc(moving);
    title(Titles{i});
    daspect([1, 1, 1]);

    tform.(Titles{i}) = imregtform(moving,fixed,"affine",optimizer,metric);

    movingRegistered = imwarp(moving,tform.(Titles{i}),"OutputView",imref2d(size(fixed)));
    subplot(2, 3, i+4);
    imagesc(movingRegistered);
    title(Titles{i})
    daspect([1, 1, 1]);
end
suptitle('Transformation Texture Response');
end