function D = CalcVocRespPerTrial(R, varargin)
% Graph 
% Input: R which is the output of computewidefield
% Output: -D.WholeVocResp the area under the graph during either all 10
% Vocalization periods or the first (AllVocs) 

P = parsePairs(varargin);
checkField(P, 'Mean', 1)
checkField(P, 'VocFreqs', [])
checkField(P, 'Area', 'SilVocResp') %TexResp, TexVocResp, SilVocResp, SusLvl, ACX
checkField(P, 'FR', 100)
checkField(P, 'AllVocs', 1)
checkField(P, 'Zscore', 2)
checkField(P, 'Save', 0)
checkField(P, 'D', [])
    
    D = P.D;
    NoiseBurstRecordings = containers.Map({'mouse193', 'mouse195', 'mouse196'}, {'R4', 'R4', 'R3'});
    CraniotomyMask = R.Frames.CraniotomyMask;
    Animal = R.Parameters.Animal;
    Parameters.Corrs = R.General.Paradigm.Stimulus.Parameters.Correlations.Value;
    Parameters.Vars = R.General.Paradigm.Stimulus.Parameters.Variances.Value;
    Parameters.Reals = 1:R.General.Paradigm.Stimulus.Parameters.NRealizations.Value;
    Parameters.NTrials = R.General.Paradigm.Trial;
    Parameters.PreTimes = R.General.Paradigm.Stimulus.Parameters.DurContext.Value;
    if isempty(P.VocFreqs)
        Parameters.VocFreqs = R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value;
    else
        Parameters.VocFreqs = P.VocFreqs;
    end
    Parameters.VocFreqsSil = Parameters.VocFreqs;
    Parameters.Reps = numel(R.General.Paradigm.Repetitions);
    ImageSize = [size(R.Frames.AvgTime, 1), size(R.Frames.AvgTime, 2)]; 
    StartFrame = find(R.Frames.TimeAvg == 2)/P.FR;
    
    if strcmp(P.Area, 'ACX')
        load(['/home/experimenter/dnp-backup/ControllerData/', Animal,'/', NoiseBurstRecordings(Animal), '/Results/evaluateNoiseBurst.mat']);
        Mask = M.FilteredMetrics.SelPix.ACX;
        Mask = imresize(Mask, ImageSize);
    else
        load("/mnt/data/Samuel/Global/Masks.mat");
        Mask = Masks.(Animal).(P.Area);
    end
    
    ReshapeSize = numel(Parameters.Corrs) * numel(Parameters.Vars) * numel(Parameters.Reals) * Parameters.Reps;

    
    VocStartFrame = zeros(1, length(Parameters.PreTimes)); 
    for i =1:length(Parameters.PreTimes)-1
        VocStartFrame(i) = (StartFrame+Parameters.PreTimes(i))*P.FR;
    end
    %Onset/Offset Index per VocFreq
    if isempty(P.D)
        D.AllVocs = P.AllVocs;
        %D.DiffAvg = zeros([size(R.Frames.AvgTime, 3), numel(Parameters.Corrs), numel(Parameters.Vars), numel(Parameters.Reals), Parameters.Reps, numel(Parameters.PreTimes)-1, numel(Parameters.VocFreqs)]);
        D.WholeVocResp = zeros([ImageSize, numel(Parameters.Corrs), numel(Parameters.Vars), numel(Parameters.Reals), Parameters.Reps, numel(Parameters.PreTimes)-1, numel(Parameters.VocFreqs)]);
        D.OnOffset = zeros([ImageSize, numel(Parameters.Corrs), numel(Parameters.Vars), numel(Parameters.Reals), Parameters.Reps, numel(Parameters.PreTimes)-1, numel(Parameters.VocFreqs)]);
        for j = 1:numel(Parameters.Corrs)
            for k = 1:numel(Parameters.Vars)
                for q = 1:numel(Parameters.Reals)
                    BaseTrialNums = GetTrialNums(Parameters.Corrs(j), Parameters.Vars(k), Parameters.Reals(q), R.General, 0, Parameters.NTrials, Parameters.PreTimes(end), Parameters.VocFreqs);
                    for p = 1:numel(Parameters.VocFreqs)
                        fprintf(['Calculating Corr: ', num2str(Parameters.Corrs(j)), ', Var: ', num2str(Parameters.Vars(k)), ', Realization: ', num2str(Parameters.Reals(q)), ', VocFreq: ', num2str(Parameters.VocFreqs(p)), ', Pretime: ']);
                        for i =1:length(Parameters.PreTimes)-1
                            printupdate(i,length(Parameters.PreTimes)-1,i==1);
                            VocStartFrame(i) = (2+Parameters.PreTimes(i))*P.FR;
                            TrialNums = GetTrialNums(Parameters.Corrs(j), Parameters.Vars(k), Parameters.Reals(q), R.General, 0, Parameters.NTrials, Parameters.PreTimes(i), Parameters.VocFreqs(p));
                            PixelDiff = zeros([ImageSize, size(R.Frames.AvgTime, 3)]);
                            for t = 1:ImageSize(1)
                                for y = 1:ImageSize(2)
                                    if CraniotomyMask(t, y) == 0
                                        D.WholeVocResp(t, y, j, k, q, :, i, p) = NaN;
                                        %D.DiffAvg(t, y, :, j, k, q, :, i, p) = NaN;
                                        D.OnOffset(t, y, j, k, q, :, i, p) = NaN;
                                        continue
                                    else
                                        for u = 1:numel(TrialNums)
                                            Diffs = zeros([size(R.Frames.AvgTime, 3), numel(BaseTrialNums)]);
                                            for o = 1:numel(BaseTrialNums)
                                                Data = squeeze(R.Frames.AvgTime(t, y, :, TrialNums(u)));
                                                Baseline = squeeze(R.Frames.AvgTime(t, y, :, BaseTrialNums(o)));
                                                Diffs(:, o) = 100*(Data-Baseline);
                                            end
                                            MeanDiffs = mean(Diffs, 2);
                                            if P.AllVocs
                                                StartFrames = VocStartFrame(i):20:VocStartFrame(i)+180;
                                                OffsetFrames = VocStartFrame(i)+10:20:VocStartFrame(i)+170;
                                                OffsetArea = 0;
                                                Area = 0;
                                                for frame = 1:numel(StartFrames)
                                                    dat = StartFrames(frame):StartFrames(frame)+9;                           
                                                    Area = Area + trapz(dat, MeanDiffs(dat));
                                                end
                                                D.WholeVocResp(t, y, j, k, q, u, i, p) = Area/10;
                                                for OffsetFrame = 1:numel(OffsetFrames)
                                                    dat = OffsetFrames(OffsetFrame):OffsetFrames(OffsetFrame)+9;
                                                    OffsetArea = OffsetArea + trapz(dat, MeanDiffs(dat));
                                                end
                                                D.OnOffset(t, y, j, k, q, u, i, p) = Area - OffsetArea;
                                            else
                                                dat = VocStartFrame(i):VocStartFrame(i)+9;
                                                FirstVocArea = trapz(dat, MeanDiffs(dat));
                                                D.WholeVocResp(t, y, j, k, q, u, i, p) = FirstVocArea;
                                                dat = VocStartFrame(i)+10:VocStartFrame(i)+19;
                                                FirstOffsetArea = trapz(dat, MeanDiffs(dat));
                                                D.OnOffset(t, y, j, k, q, u, i, p) = FirstVocArea-FirstOffsetArea;
                                            end
                                            %D.DiffAvg(t, y, :, j, k, q, u, i, p) = MeanDiffs;
                                            PixelDiff(t, y, :) = MeanDiffs;
                                        end
                                    end
                                end
                            end
                            PixelArea = PixelDiff.*Mask;
                            PixelArea(PixelArea == 0) = NaN;
                            D.DiffAreaAvg(:, j, k, q, u, i, p) = squeeze(nanmean(nanmean(PixelArea, 1), 2));
                        end
                        fprintf(repmat('\b', 1, numel(['Calculating Corr: ', num2str(Parameters.Corrs(j)), ', Var: ', num2str(Parameters.Vars(k)), ', Realization: ', num2str(Parameters.Reals(q)), ', VocFreq: ', num2str(Parameters.VocFreqs(p)), ', Pretime: i / i'])));
                    end
                end
            end
        end
        ReshapeTrial = reshape(D.DiffAreaAvg, [size(R.Frames.AvgTime, 3), ReshapeSize, numel(Parameters.PreTimes)-1, numel(Parameters.VocFreqs)]);
        D.TrialAvg = squeeze(nanmean(ReshapeTrial, 2));
    else
        if D.AllVocs~=P.AllVocs
            error('Number of Vocalizations does not match, please recalculate D with correct number of vocalizations')
        end
        D.DiffAreaAvg = 'Not Calculated yet';
        D.TrialAvg = 'Not Calculated yet';
        
    end
        
    
    ReshapedResp = reshape(D.WholeVocResp, [ImageSize, ReshapeSize, numel(Parameters.PreTimes)-1, numel(Parameters.VocFreqs)]);
    ReshapedOnOffset = reshape(D.OnOffset, [ImageSize, ReshapeSize, numel(Parameters.PreTimes)-1, numel(Parameters.VocFreqs)]);
    D.Params = Parameters.PreTimes(1:3);
    RegionSpecificResponse = ReshapedResp.*Mask;
    RegionSpecificResponse(RegionSpecificResponse == 0) = NaN;
    D.SignifTest = squeeze(nanmean(nanmean(RegionSpecificResponse, 1), 2));
    
    RegionSpecificOnOffset = ReshapedOnOffset .* Mask;
    RegionSpecificOnOffset(RegionSpecificOnOffset == 0) = NaN;
    D.OnOffsetAvg = squeeze(nanmean(nanmean(RegionSpecificOnOffset, 1), 2));
    D.RegionMasks = zeros([size(ReshapedResp)]);
    D.ResponseRegionSize = zeros([ReshapeSize, numel(Parameters.PreTimes)-1, numel(Parameters.VocFreqs)]);
    for q = 1:numel(Parameters.VocFreqs)
        for j = 1:numel(Parameters.PreTimes)-1
            for i = 1:ReshapeSize
                RegionMask = HF_SignFilterImage(ReshapedResp(:, :, i, j, q), 'SelectionMethod','zscore', 'zscoreThresh',P.Zscore);
                D.RegionMasks(:, :, i, j, q) = RegionMask;
                D.ResponseRegionSize(i, j, q) = sum(RegionMask(:));
            end
        end
    end
     
    if P.Save
        if P.AllVocs
            name = ['D', P.Area, 'All.mat'];
        else
            name = ['D', P.Area, 'First.mat'];
        end
        save(['/mnt/data/Samuel/', Animal, '/NewDs/', name], 'D', '-v7.3')
    end
    
    
    