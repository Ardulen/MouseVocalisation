function finaltf = GradDescentCalcTrans(varargin)
P = parsePairs(varargin);
checkField(P,'FIG',1);
checkField(P, 'Source', 'VideoCalcium');
checkField(P, 'Animals', [193, 195, 196]);
checkField(P, 'Recordings', [201, 130, 193]);
checkField(P, 'Corr', 1);

PreTrans = struct;
%rescaling images
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

%Reference to map transformed images onto
Ref = imref2d(size(PreTrans.(['mouse', num2str(P.Animals(1))]).(MetricNames{1})));


% Initial guess for fminunc
initialGuess.(['mouse', num2str(P.Animals(2))]) = [1, 0.5, -0.5, 1, -1, -1];
initialGuess.(['mouse', num2str(P.Animals(3))]) = [1, 0.5, -0.5, 1, -1, 1];

% Options for fminunc
options = optimset('fminunc');
options.Display = 'iter';

% Optimize transformation using fminunc
for Animal = 2:AnimalNum
    OptimParams = fminunc(@costFunction, initialGuess.(['mouse', num2str(P.Animals(Animal))]), options);
    finaltf.(['m', num2str(P.Animals(Animal))]) = affine2d([OptimParams(1), OptimParams(2), 0; OptimParams(3), OptimParams(4), 0; OptimParams(5), OptimParams(6), 1]);
end



% Cost function to minimize using fminunc
function cost = costFunction(params)

    tform = affine2d([params(1), params(2), 0; params(3), params(4), 0; params(5), params(6), 1]);
        

    transformedMaps = cell(MetricNum, 1);
    for q = 1:MetricNum
        transformedMaps{q} = imwarp(PreTrans.(['mouse', num2str(P.Animals(Animal))]).(MetricNames{q}), tform, "OutputView", Ref);
    end
    
    % Compute misalignment cost
    cost = 0;
    for q = 1:MetricNum
        if P.Corr
            cost = cost -corr2(transformedMaps{q}, PreTrans.(['mouse', num2str(P.Animals(1))]).(MetricNames{q}));
        else
            cost = cost - mi(transformedMaps{q}, PreTrans.(['mouse', num2str(P.Animals(1))]).(MetricNames{q}));
        end 
    end
end



end