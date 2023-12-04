function PlotTORCVOCResponse(R, varargin)
    
    P = parsePairs(varargin);
    checkField(P,'FR',100)
    checkField(P, 'Animal')
    checkField(P, 'Recording')
    checkField(P, 'FIG', 2)


    MP = get(0,'MonitorPositions');
    NY = MP(1,end); HPixels = 540;
    FigureName=[P.Animal,' R',num2str(P.Recording),' Vocalization Response'];
    Fig = figure(P.FIG); clf; set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1350,HPixels]);
    
    line_colors = [0.5, 0.5, 1; 0.4, 0.5, 0.4; 1, 0.5, 0.5; 0, 0, 1; 0, 0.5, 0; 1, 0, 0];
    line_styles = [':', ":", ':', "-", "-", "-"];
    line_widths = [1.5, 1.5, 1.5, 1.5];
    CM = HF_colormap({[0,0,1],[1,1,1],[1,0,0]});
    
    AH(1)=axes('position',[0.02,0.60,0.20,0.25]);
    AH(2)=axes('position',[0.23,0.60,0.20,0.25]);
    AH(3)=axes('position',[0.44,0.60,0.20,0.25]);
    AH(4)=axes('position',[0.65,0.60,0.20,0.25]);
    AH(5)=axes('position',[0.02,0.10,0.20,0.25]);
    AH(6)=axes('position',[0.23,0.10,0.20,0.25]);
    AH(7)=axes('position',[0.44,0.10,0.20,0.25]);
    AH(8)=axes('position',[0.65,0.10,0.20,0.25]);
    
    
    
    Corrs = R.General.Paradigm.Stimulus.Parameters.Correlations.Value;
    Vars = R.General.Paradigm.Stimulus.Parameters.Variances.Value;
    Reals = 1:R.General.Paradigm.Stimulus.Parameters.NRealizations.Value;
    NTrials = R.General.Paradigm.Trial;
    PreTimes = R.General.Paradigm.Stimulus.Parameters.DurContext.Value;
    VocFreqs = R.General.Paradigm.Stimulus.Parameters.VocalFrequencies.Value;
    
    for i =1:length(PreTimes)
        TrialNums = GetTrialNums(Corrs, Vars, Reals, R.General, 0, NTrials, PreTimes(i), VocFreqs);
        Data = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
        VocResp = max(Data(:, :, PreTimes(i)*P.FR:(PreTimes(i)+0.2)*P.FR), [], 3)-Data(:, :, PreTimes(i)*P.FR);
        cAH = AH(i);
        imagesc(cAH, VocResp);
        set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
        caxis(cAH, [0, 0.02])
        ylabel(cAH, 'Mediolateral (mm)'); xlabel(cAH, 'Anteroposterior (mm)');
        title(cAH, ['Pretime ', num2str(PreTimes(i))]);
        colormap(cAH, 'jet')
        colorbar(cAH);
        cAH = AH(i+4);
        TrialNums = GetTrialNums(Corrs, Vars, Reals, R.General, 1, NTrials, PreTimes(i), VocFreqs);
        Data = squeeze(mean(R.Frames.AvgTime(:, :, :, TrialNums), 4));
        VocResp = max(Data(:, :, PreTimes(i)*P.FR:(PreTimes(i)+0.2)*P.FR), [], 3)-Data(:, :, PreTimes(i)*P.FR);
        imagesc(cAH, VocResp);
        set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
        caxis(cAH, [0, 0.02])
        ylabel(cAH, 'Mediolateral (mm)'); xlabel(cAH, 'Anteroposterior (mm)');
        title(cAH, ['Pretime ', num2str(PreTimes(i))]);
        colormap(cAH, 'jet')
        colorbar(cAH);
    end
    
   
        
        
        
        