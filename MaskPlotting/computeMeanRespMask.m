function D = computeMeanRespMask(R, varargin)
P = parsePairs(varargin);
checkField(P, 'Area', 'ACX') %TexResp, TexVocResp, SilVocResp, SusLvl, ACX
checkField(P, 'FR', 100)
checkField(P, 'Save', 0)


Animal = R.Parameters.Animal;
P.Corrs = R.General.Paradigm.Stimulus.Parameters.Correlations.Value;
P.Vars = R.General.Paradigm.Stimulus.Parameters.Variances.Value;
P.Reals = 1:R.General.Paradigm.Stimulus.Parameters.NRealizations.Value;
P.NTrials = R.General.Paradigm.Trial;
P.PreTimes = R.General.Paradigm.Stimulus.Parameters.DurContext.Value;
P.VocFreqs = R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value;
P.Reps = numel(R.General.Paradigm.Repetitions);
P.ImageSize = [size(R.Frames.AvgTime, 1), size(R.Frames.AvgTime, 2)]; 


NoiseBurstRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R4', 'R4', 'R3'});
if strcmp(P.Area, 'ACX')
    load(['/home/experimenter/dnp-backup/ControllerData/', Animal,'/', NoiseBurstRecordings(Animal), '/Results/evaluateNoiseBurst.mat']);
    Mask = M.FilteredMetrics.SelPix.ACX;
    P.Mask = imresize(Mask, P.ImageSize);
else
    load("/mnt/data/Samuel/Global/Masks.mat");
    P.Mask = Masks.(Animal).(P.Area);
end

D.TexRespTrials = [];
D.SilRespTrials = [];


for i = 3:numel(P.PreTimes)
    TrialNums = GetTrialNums(P.Corrs, P.Vars, P.Reals, R.General, 0, P.NTrials, P.PreTimes(i), P.VocFreqs);
    MaskTrial = CalcMaskTrial(R, TrialNums, i, P, 0);

    %MaskTrial = reshape(MaskTrial, [P.ImageSize, numel(Time), NumTexTrials*2]);
    % Compute the response for the current set of trials and accumulate the mean
    D.TexRespTrials = [D.TexRespTrials, squeeze(nanmean(nanmean(MaskTrial, 1), 2))];

end



for i = 1:numel(P.PreTimes)
    SilTrialNums = GetTrialNums(0, 0, 0, R.General, 1, P.NTrials, P.PreTimes(i), P.VocFreqs);
    MaskTrial = CalcMaskTrial(R, SilTrialNums, i, P, 1);
    D.SilRespTrials = [D.SilRespTrials, squeeze(nanmean(nanmean(MaskTrial, 1), 2))];

end


if P.Save
    name = ['TotResp', P.Area, '.mat'];
    save(['/mnt/data/Samuel/', Animal, '/TotMaskResp/', name], 'D', '-v7.3')
end

end

function MaskTrials = CalcMaskTrial(R, TrialNums, Num, P, Sil)    
    MaskTrials = R.Frames.AvgTime(:, :, :, TrialNums).*P.Mask;
    MaskTrials(MaskTrials ==0) = NaN;
    if Sil
        Start = round(P.PreTimes(Num)*P.FR);
        MaskTrials = cat(3, MaskTrials(:, :, Start+1:end, :), zeros([P.ImageSize, Start, size(MaskTrials, 4)]));
    end
    
end

