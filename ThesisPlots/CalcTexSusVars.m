function T = CalcTexSusVars(R, varargin)
P = parsePairs(varargin);
checkField(P, 'FR', 100);
checkField(P, 'Corrs', [0, 0.8]);
checkField(P, 'Vars', [0.02, 0.2, 0.4]);
checkField(P, 'Pretimes', [3, 5]);
checkField(P, 'Save', 0)

P.Animal = R.General.Parameters.General.Animal;
[TrialIndices, ~] = getTrialIndices(P.Corrs, P.Vars, R, P.Pretimes);
ParFrames = GetParFrames(TrialIndices, R.Frames.AvgTime);
TrialAvg = squeeze(nanmean(ParFrames, 4));


TexResp = TrialAvg(:, :, 2*P.FR:1:2.5*P.FR, :);
T.MaxTexResp = squeeze(max(TexResp, [], 3));
MedTexResp = squeeze(median(TrialAvg(:, :, 4*P.FR:1:5*P.FR, :), 3));
T.AdaptMap = MedTexResp./T.MaxTexResp;
T.SustainedLvlMap = 100*MedTexResp;

if P.Save
    save(['/mnt/data/Samuel/',(P.Animal), '/TexSusVarMaps.mat'], 'T')
end