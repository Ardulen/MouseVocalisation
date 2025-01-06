function Motherscript(varargin)
% Not a true function, meant to be executed in parts to evaluate different
% parts of the code

P = parsePairs(varargin);
checkField(P, 'Animal')
checkField(P, 'Recording')
checkField(P, 'Scale', 4)


%% Plot Sound Stats
% Uses part of McDermott pipeline to calculate the properties of the
% difference TORC noises

[S, P, WaveForm] = CalcSoundStats;
PlotSoundStats(S, P, WaveForm);


%First C_computewidefield is used to get R, for mouse 196 the resolution is
%so twice as high which causes it to be to large for the amount of RAM to
%be loaded in one go. I created a very crude solution by loading it in 50
%trials at a time and just concatinating R.Frames.AvgTime (using C_computeWidefieldinParts) since that is the
%only part I really need. (I think this conflitcs with the newsest version
%of computeWidefield so a better solution is necassary)

if strcmp(P.Animal, 'mouse196') 
     R = C_computeWidefieldinParts(50, 'mouse196', 193, 552, 8, 1);
else
    R = C_computeWidefield('Animal', P.Animal, 'Recording', P.Recording, 'FIG', 0, 'Scale', P.Scale);
end

%% Texture GUI

% For a single recording creates a GUI that displays the effect of only the
% texture by using only pretime 3 and 5. compute and show aren´t very well
% seperated between the two functions.


[TrialAvg, TORCNoiseSignal, T] = C_computeTORCWidefield(R);
O = C_showTORCWidefield(TrialAvg, R, TORCNoiseSignal, T);

% The Data that is used in the the thesis is the sustained level and
% maximum Texture response

close all
clear T TrialAvg O

%% Vocalization GUI

% for a recording the vocalization response is calcualted and displayed in
% a GUI. The SEM in the lineplots is not accurate!

[T, P, M] = C_computeTORCVOCindividualBaselineWidefield(R);
O = C_showTORCVocResponse(R, T);


close all
clear T TrialAvg O

% From these data is saved to drive (mnt/data/Samuel) for each animal and
% then combined in the actual plots

%% Thesisplots based on GUI Data
% for the next plots all data should in principle be contained in the two
% GUIs


% Texture vs Vocalization.

plotTexVsVoc
% Mean response over an area used in A is calculated for each recording
% using:
computeMeanRespMask(R)



% Texture vs sustained level

plotTexvsSus


% Texture and Sustained level for different sound variables

plotTexSusVars


% Vocalization in/out noise and sustained level

plotVocvsSilvsSus


% Contrast (I haven't recoded this one)



%% Thesisplots based Trial Data
% the final two plots also contain data calculated for individual
% trials averaged over different areas, again saved for each animal on
% /mnt/data/Samuel.
D = CalcVocRespPerTrial(R, varargin);

%from this the response size and strength for different
% pretimes and vocalization frequencies are plotted in/out Noise using:

[Time, Frequency, Plot] = PlotViolins;
[~, ~, PlotSil] = PlotViolins('Silence', 1);
% Part of the data from all animals in "Plot" is used in the final 2 plots


% Vocalization response for different pretimes

plotVocPretime(Plot)


% Vocalization On- and Offset response in/out noise

plotVocFreqOnOffsetFigure(Plot, PlotSil)






