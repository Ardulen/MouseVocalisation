function plotDiffMethMaps(R, varargin)
    P = parsePairs(varargin);
    checkField(P, 'FIG', 5)
    checkField(P, 'FilterOrder', 1)
    checkField(P, 'CutoffFreq', 1)
    checkField(P, 'WindowSize', 20)
    checkField(P, 'FR', 100)
    checkField(P, 'PreTime', 3)
    %% Time Points
    Time=R.Frames.TimeAvg-2;
    PreTime = P.PreTime;
    VocStartFrame = (PreTime+2)*P.FR;
    %% Set figure
    MP = get(0,'MonitorPositions');
    NY = MP(1,end); HPixels = 540;
    FigureName=[R.Parameters.Animal,' R',num2str(R.Parameters.Recording),' Signal clean up methods'];
    Fig = figure(P.FIG); clf; set(Fig,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1250,HPixels]);
    [~,AH] = axesDivide(4,1,[0.05, 0.1, 0.9, 0.8],[],0.4, 'c');
    annotation('textbox','String', 'bla','Position',[0.4,0.97,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    
    %% Data
    TrialNums = GetTrialNums(0, 0, 0, R.General, 1, R.General.Paradigm.Trial, PreTime, R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value);
    Data = 100*squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
    
    %% VocStart - VocMax
    
    MaxVocResp = max(Data(:, :, VocStartFrame:VocStartFrame+10), [], 3);
    PreVocLvl = Data(:, :, VocStartFrame);
    Resp = 100*(MaxVocResp-PreVocLvl);
    
    %% Butter Filter
    % Define the range for finding local minima
    RangeStart = (PreTime+2)*100;
    RangeEnd = (PreTime+3.9)*100;
    
    for k = 1:size(Data, 1)
        for j = 1:size(Data, 2)
            for i = 1:10
                [PreMinVs(i), PreMinIs(i)] = min(squeeze(Data(k, j, RangeStart-20+i*20:RangeStart-16+i*20)));
                [PostMinVs(i), PostMinIs(i)] = min(squeeze(Data(k, j, RangeStart-14+i*20:RangeStart-9+i*20)));
            end
            MergedMinVs = zeros(1, length(PreMinVs)*2);
            MergedMinIs = zeros(1, length(PreMinIs)*2);
            % Use a loop to fill in the merged list
            for i = 1:length(PreMinVs)
                MergedMinVs(2 * i - 1) = PreMinVs(i);
                MergedMinVs(2 * i) = PostMinVs(i);
                MergedMinIs(2 * i - 1) = PreMinIs(i)+RangeStart-20+i*20;
                MergedMinIs(2 * i) = PostMinIs(i)+RangeStart-14+i*20;       
            end

            InterpRange = linspace(RangeStart, RangeEnd, 190);
            InterpMin = interp1(MergedMinIs, MergedMinVs, InterpRange, 'pchip');
            x = VocStartFrame:1:VocStartFrame+10;
            % Integrate both curves
            area1 = trapz(x, InterpMin(1:10));
            area2 = trapz(x, Data(k, j, x));

            % Calculate the difference in area
            areaDifference = area2 - area1;
            
        end
    end
    
end