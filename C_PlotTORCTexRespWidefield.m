classdef C_PlotTORCTexRespWidefield < handle
 
  properties (SetAccess = public)
    Frames = [];
    Stimulus = [];
    GUI = [];
    X = [];
    Y = [];
    PixelPerMM = [];
    P = [];
    Info = [];
    Time = [];
    ROIMask = [];
    CurrentTime = 0;
    ROIAll = [];
    ROIAvgImage  = [];
    ROIAvgImageTrial = [];
    ROISEMImageTrial  = [];
    Scope = [];
    FigSavePath = [];
    General = [];
  end


methods

function O = C_PlotTORCTexRespWidefield(ParAvg, Corrs, Vars, R, minpretime, pl, varargin)

    P = parsePairs(varargin);
    checkField(P,'ROI',[]); % [centerX centerY radius] in mm
    checkField(P,'FIG',2001);
    checkField(P,'Lens','Nikon4X') % Usually set automatically by the Setup
    checkField(P,'Source','VideoCalcium'); % Choose the Source of the Data
    checkField(P,'FigSavePath',[])
    checkField(P,'Trials',[]); 
    checkField(P, 'Animal')
    checkField(P, 'Recording')
    
    VarNum = length(Corrs)*length(Vars);
    CorrVar = {};
    for i = 1:length(Corrs)
        for j = 1:length(Vars)
        % Concatenate elements from both vectors into a string
            combination = ['Corr', num2str(Corrs(i)), ' Var', num2str(Vars(j))];
        % Add the combination to the cell array
            CorrVar = [CorrVar, combination];
        end
    end
    
    MP = get(0,'MonitorPositions');
    NY = MP(1,end); HPixels = 500;
    FigureName=[P.Animal,' R',num2str(P.Recording),' Texture Response'];
    figure(P.FIG); clf; set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1200,HPixels]);

    AH(1)=axes('position',[0.04,0.55,0.20,0.40]);
    AH(2)=axes('position',[0.04,0.05,0.20,0.40]);
    AH(3)=axes('position',[0.28,0.55,0.20,0.40]);
    AH(4)=axes('position',[0.28,0.05,0.20,0.40]);
    AH(5)=axes('position',[0.56,0.23,0.30,0.52]);
    annotation('textbox','String',FigureName,'Position',[0.6,0.93,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    %% pixels to mm transformation  
    [X, Y, PixelPerMM] = C_pixelToMM(P,R,R.Frames);
    O.PixelPerMM = PixelPerMM;
    O.X = X; O.Y = Y;
    
    O.Time=Frames.TimeAvg;
    TimeInd = round(size(Frames.AvgTimeTrial,3)/2);%select arbitrary frame
    AvgFrame = 100*squeeze(Frames.AvgTimeTrial(:,:,TimeInd));
    SRAudio = O.Stimulus.Parameters.SR.Value;
    StartTimes = O.Stimulus.StartPos/SRAudio;
    StopTimes = O.Stimulus.StopPos/SRAudio;
    AvgOverTime = nanmedian(Frames.AvgTimeTrial,[1,2]);
    ValidInd = find(O.Time>StartTimes(1));
    
    %% plot largest Text response map        
        TexResp = squeeze(nanmean(ParAvg, 4));
    for i = 1:4
        axes(AH(i));
        imagesc(X, Y,100*TexResp(:, :, pl(i)));
        Clim = 100*max(TexResp, [], 'all');
        caxis([0, Clim]);
        CM = HF_colormap({[0,0,1],[1,1,1],[1,0,0]});
        colormap(CM)
        axis square;
        colorbar;
        ylabel('Mediolateral (mm)'); xlabel('Anteroposterior (mm)');
        title(CorrVar(pl(i)));
    end
    %% plot Traces
    axes(AH(5));
    Time = R.Frames.TimeAvg;
    
    AvgImage = squeeze(mean(mean(ParAvg,2),1));
    AvgImageTrial = squeeze(nanmean(AvgImage,2));
    hold on;
    line_colors = [0, 0, 1; 0, 0, 1; 1, 0, 0; 1, 0, 0];
    line_styles = ['-', ':', '-', ':'];
    for i =1:length(pl)
        plot(Time, 100*AvgImageTrial(:, pl(i)), 'Color', line_colors(i, :), 'Linestyle', line_styles(i));
    end
    plot([2, 2],[-1000,1000],'-','Color','g');
    hold off;
    colormap(CM);
    legend(CorrVar(pl), 'Location', 'NorthEast');
    xlim([1.5, minpretime+2]);
    ylim([-2, 2]);
    xlabel('time (s)');
    ylabel('Change norm. (%)')
    title('Average over whole craniotomy')
end
end
end