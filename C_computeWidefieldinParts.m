function R = C_computeWidefieldinParts(n, animal, Rec, Trialnum, scale)

R = C_computeWidefield('Animal', animal, 'Recording', Rec, 'FIG', 0, 'Trials', [1:1:n], 'Scale', scale);
for i = n+1:n:Trialnum
    Rtemp = C_computeWidefield('Animal', animal, 'Recording', Rec, 'FIG', 0, 'Trials', [i:1:i+n-1], 'Scale', scale);
    R.Frames.AvgTime = cat(4, R.Frames.AvgTime, Rtemp.Frames.AvgTime);
end