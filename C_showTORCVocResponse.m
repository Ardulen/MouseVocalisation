classdef C_showTORCVocResponse < handle
 
  properties (SetAccess = public)
    CraniotomyMask = [];
    GUI = [];
    X = [];
    Y = [];
    PixelPerMM = [];
    P = [];
    T = {};
    Time = [];
    ROIMask = [];
    ROIAvgImage  = [];
    General = [];
    LineColors = [];
    LineStyles = [];
    LineWidths = [];
    FigureName = {};
    ImageSize = [];
    NTrials = [];
    SelP = 'Full';
    Legend = {};
    Vid = {};
    AxNum = 10;
  end
  
  
  methods
    
    function O = C_showTORCVocResponse(R, T,varargin)

        P = parsePairs(varargin);
        checkField(P,'CLim','Auto')
        checkField(P,'ROI',[1.14, 1.77, 0.2]); % [centerX centerY radius] in mm
        checkField(P,'FIG',1);
        checkField(P, 'Source', 'VideoCalcium');
        checkField(P, 'FR', 100);
        checkField(P, 'CranMask', 1);

        O.NTrials = size(R.Frames.AvgTime,4);
        O.ImageSize = size(R.Frames.AverageRaw);
        O.T = T;
        O.General = R.General;
        O.P = P;
        if P.CranMask
            O.CraniotomyMask = R.Frames.CraniotomyMask;
        else    
            O.CraniotomyMask = O.createCranMask;
        end
        O.Vid.CurrentTime = 0.5;
        O.Vid.PreTime = 1;
        O.Vid.Caxis = 0;
        O.Vid.Clims = O.GetClims(100*O.T.Data.Full(:, :, 180:500, 1), [99.9, 5]);%[min(100*O.T.Data.Full(:, :, 180:500, 1), [], 'all'), max(100*O.T.Data.Full(:, :, 180:500, 1), [], 'all')];
        O.updateLegend('Tex + Pretme ', 'Sil + Pretime ');        
        %% Set figure
        MP = get(0,'MonitorPositions');
        NY = MP(1,end); HPixels = 540;
        O.FigureName=[O.P.Animal,' R',num2str(O.P.Recording),' Texture Response'];
        Fig = figure(O.P.FIG); clf; set(O.P.FIG,'name', O.FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1250,HPixels]);

        O.LineColors = [0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980; 0.9290, 0.6940, 0.1250; 0.4940, 0.1840, 0.5560;0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980; 0.9290, 0.6940, 0.1250; 0.4940, 0.1840, 0.5560];
        O.LineStyles = [':', "-"];
        O.LineWidths = [1.5, 1.5, 1.5, 1.5, 1, 1, 1, 1];
        
        O.createAxes;
        [~, O.GUI.AH(11)] = axesDivide(1,1,[0.04, 0.1, 0.7, 0.2],[],0.3,'c');
        annotation('textbox','String', O.FigureName,'Position',[0.3,0.96,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);

        %% pixels to mm transformation  
        [X, Y, PixelPerMM] = C_pixelToMM(P,R,R.Frames);
        O.PixelPerMM = PixelPerMM;
        O.X = X; O.Y = Y;

        %% Time Points
        O.Time=R.Frames.TimeAvg;
        %% popup menus
        
        O.GUI.Mapspopup = uicontrol('Style',  'popup', 'FontSize', 8, 'Position', [870, 520, 150, 15]);
        O.GUI.Mapspopup.String = {'Tex vs Sil', 'Correlations', 'Summary'};
        O.GUI.Mapspopup.Callback = @O.MapsdropdownCallback;
        PretimeCellarray = cellfun(@num2str, num2cell(O.T.Parameters.PreTimes), 'UniformOutput', false);
        O.GUI.PreTimepopup = uicontrol('Style', 'popup', 'FontSize', 8, 'Position', [1120, 520, 50, 15]);
        O.GUI.PreTimepopup.String = PretimeCellarray;
        O.GUI.PreTimepopup.Callback = @O.PreTimedropdownCallback;
        %% display current ROI coordinates
        O.GUI.ROICoords = uicontrol('Style', 'text', 'FontSize', 7, 'String', ['ROI Coordinates X: ' num2str(O.P.ROI(1)) ', Y: ' num2str(O.P.ROI(2))], 'Position', [10, 520, 300, 15]);

        %% buttons
        O.createButtons;
        
        
        O.T.SilVocAvg = mean(O.T.VocResp.Sil, 3);
        O.T.FullVocAvg = mean(O.T.VocResp.PreTime, 3);
        FirstTrialVocResp = zeros([O.ImageSize(1), O.ImageSize(2), 250, 10]);
        FirstTrialVocRespSil = zeros([O.ImageSize(1), O.ImageSize(2), 250, 10]);
        LastTrialVocResp = zeros([O.ImageSize(1), O.ImageSize(2), 250, 10]);
        LastTrialVocRespSil = zeros([O.ImageSize(1), O.ImageSize(2), 250, 10]);
        TexTrialNums = GetTrialNums(T.Parameters.Corrs, T.Parameters.Vars, T.Parameters.Reals, R.General, 0, T.Parameters.NTrials, T.Parameters.PreTimes, T.Parameters.VocFreqs);
        SilTrialNums = GetTrialNums(T.Parameters.Corrs, T.Parameters.Vars, T.Parameters.Reals, R.General, 1, T.Parameters.NTrials, T.Parameters.PreTimes, T.Parameters.VocFreqs);
        for i = 1:10
            PreTime = R.General.Paradigm.Trials(TexTrialNums(i)).Stimulus.ParSequence.PreTime;
            FirstTrialVocResp(:, :, :, i) = R.Frames.AvgTime(:, :, (PreTime+1.5)*O.P.FR:(PreTime+3.99)*O.P.FR, TexTrialNums(i));
            PreTime = R.General.Paradigm.Trials(TexTrialNums(end-i)).Stimulus.ParSequence.PreTime;
            LastTrialVocResp(:, :, :, i) = R.Frames.AvgTime(:, :, (PreTime+1.5)*O.P.FR:(PreTime+3.99)*O.P.FR, TexTrialNums(end-i));
            PreTime = R.General.Paradigm.Trials(SilTrialNums(i)).Stimulus.ParSequence.PreTime;
            FirstTrialVocRespSil(:, :, :, i) = R.Frames.AvgTime(:, :, (PreTime+1.5)*O.P.FR:(PreTime+3.99)*O.P.FR, SilTrialNums(i));
            PreTime = R.General.Paradigm.Trials(SilTrialNums(end-i)).Stimulus.ParSequence.PreTime;
            LastTrialVocRespSil(:, :, :, i) = R.Frames.AvgTime(:, :, (PreTime+1.5)*O.P.FR:(PreTime+3.99)*O.P.FR, SilTrialNums(end-i));
        end
        O.T.FLAvg(:, :, :, 1) = mean(FirstTrialVocResp, 4);
        O.T.FLAvg(:, :, :, 2) = mean(LastTrialVocResp, 4);
        O.T.FLAvg(:, :, :, 3) = mean(FirstTrialVocRespSil, 4);
        O.T.FLAvg(:, :, :, 4) = mean(LastTrialVocRespSil, 4);
        

        %% plot ROI Traces

        cAH = O.GUI.AH(11);
        set(cAH,'ButtonDownFcn',{@O.selectTime});
        O.ROIAvgImage = zeros(length(O.Time), 8);
        hold(cAH, 'on');
        for j =1:8
            O.GUI.ROIAverage(j) = plot(cAH, O.Time, 100*O.ROIAvgImage(:, j), 'Linewidth', 1.5, 'Visible', 'off');
        end
        for j = 1:4
            for i = 1:10
                % Calculate the x-coordinate of the center of each rectangle
                xCenter = O.T.Parameters.PreTimes(j)+0.2*(i-1);

                % Use the rectangle function to create each rectangle with specified alpha value
                O.GUI.VocStims(j, i) = rectangle('Position', [xCenter, -5, 0.1, 10], 'FaceColor', 'g', 'EdgeColor', 'none', 'Visible', 'off', 'HandleVisibility', 'off');
            end
        end
        plot(cAH, [0, 0],[-1000,1000],'-','Color','k', 'HandleVisibility', 'Off');
        xlim(cAH, [-1, 8]);
        plot(cAH, [-3, 10],[0,0],'-','Color','k', 'HandleVisibility', 'Off');
        O.GUI.TimeIndicator = plot([O.Vid.CurrentTime,O.Vid.CurrentTime],[-1000,1000],'-','Color','r', 'HandleVisibility', 'off');
        set(O.GUI.ROIAverage,'HitTest','off');
        xlabel(cAH, 'time (s)');
        ylabel(cAH, 'Change norm. (%)');
        title(cAH, 'Averages over ROI');
        set(cAH, 'FontSize', 6);


        O.plotSilMaps;
        O.plotTimePoint;
        for i =1:10
            O.GUI.Circle.left(i) = O.redrawCircle(i, 'm');
        end
        O.ROIMask = O.findROIMask;
        O.updateROIAverages;
        
    end
        
        function createAxes(O)
            [~,AHTop] = axesDivide(5,1,[0.02, 0.60, 1, 0.4],[],0.4, 'c');
            [~,AHMiddle] = axesDivide(5,1,[0.02, 0.25, 1, 0.45],[],0.4, 'c');
            O.GUI.AH(1:10) = [AHTop(:); AHMiddle(:)];
        end  
        
        function plotSilMaps(O)
            % plots the response maps for different pretimes for Trials
            % with and without Texture
            ClimsFull = O.GetClims(O.T.VocResp.PreTime, [95, 5]);
            ClimsSil = O.GetClims(O.T.VocResp.Sil, [95, 5]);
            for i = 1:4
                O.plotMaps('Full', O.T.VocResp.PreTime(:, :, i), 'Change norm (%)', ClimsFull, O.LineColors(i, :), i, O.Legend{i}, 'jet')
                O.plotMaps('Sil', O.T.VocResp.Sil(:, :, i), 'Change norm (%)', ClimsSil, O.LineColors(i, :), i+5, O.Legend{i+4}, 'jet');
            end
        end 
        
        function plotCorrMaps(O)
           Clims = O.GetClims(O.T.VocResp.Corr, [95, 5]);
           for j = 1:2
               for i = 1:4
                    O.plotMaps("Corr", O.T.VocResp.Corr(:, :, (j-1)*4+i), 'Change Norm (%)',  Clims, O.LineColors(i, :), (j-1)*5+i, O.Legend{(j-1)*4+i}, 'jet')
               end
           end
        end
        
        function plotSumMaps(O)
            Clims = O.GetClims(O.T.TexResp, [95, 5]);
            O.plotMaps("TexResp", O.T.TexResp, 'Change Norm (%)', Clims, O.LineColors(1, :), 1, 'Texture Response', 'jet');
            Clims = O.GetClims(O.T.FullVocAvg, [95, 5]);
            O.plotMaps('AvgVocResp', O.T.FullVocAvg, 'Change Norm (%)', Clims, 'k', 2, 'Texture Voc Resp', 'jet')
            Clims = O.GetClims(O.T.SilVocAvg, [95, 5]);
            O.plotMaps('AvgVocResp', O.T.SilVocAvg, 'Change Norm (%)', Clims, 'k', 3, 'Silent Voc Resp', 'jet')
            Clims = O.GetClims(O.T.SusLvl, [95, 5]);
            O.plotMaps("SusLvl", O.T.SusLvl, 'Change Norm (%)', Clims, O.LineColors(2, :), 4, 'Sustained Level', 'jet');
            Clims = O.GetClims(O.T.FitDecMap, [95, 5]);
            O.plotMaps("SusLvl", O.T.FitDecMap, 'Tau', Clims, O.LineColors(2, :), 5, 'Decay constant', 'jet');
            
        end
        
        function plotTimePoint(O)
            for i = 1:2
                MapData = 100*O.T.Data.(O.SelP)(:, :, round((O.Vid.CurrentTime+2)*O.P.FR), round((i-1)*4+O.Vid.PreTime));
                if O.Vid.Caxis
                    Clims = O.GetClims(MapData, [95, 5]);
                else
                    Clims = O.Vid.Clims;
                end
                O.plotMaps('TimePoint', MapData, ' ', Clims, 'k', 5+5*(i-1), ['Pretime', num2str(O.T.Parameters.PreTimes(O.Vid.PreTime)),' @ ',num2str(O.Vid.CurrentTime,2),'s'], 'bone')
            end
        end
        
        function plotMaps(O, GUIDat, MapData, ylab, Clims, Color, AxNum, Title, ColMap)
            %plots a single map for given data
            cAH = O.GUI.AH(AxNum);
            hold(cAH, 'on');
            O.GUI.(GUIDat) = imagesc(cAH, O.X, O.Y,MapData); %[cAH, AHB, cBar] = HF_imagescCraniotomy(Fig,cAH,cAH,O.X,O.Y,Adaptmap(:, :, O.P.Pl(i)),Adaptmap(:, :, O.P.Pl(i)),R.Frames.CraniotomyMask, 'AlphaF', 1, 'AlphaB', 0); 
            O.GUI.(GUIDat).AlphaData = O.CraniotomyMask.*1;
            set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
            set(cAH, 'FontSize', 5);
            set(cAH,'ButtonDownFcn',{@O.selectROI});
            colormap(cAH, ColMap)
            caxis(cAH, Clims);
            set(O.GUI.(GUIDat),'HitTest','off');
            c1 = colorbar(cAH);
            ylabel(c1, ylab);
            %ylabel(cAH, 'Mediolateral (mm)'); xlabel(cAH, 'Anteroposterior (mm)');
            title(cAH, Title, 'Color', Color, 'FontSize', 7);
            ylim(cAH, [min(O.Y), max(O.Y)]);
            xlim(cAH, [min(O.X), max(O.X)]);
        end
        
        function H = redrawCircle(O, i, color)
            Steps = linspace(0,2*pi,100);
            CircleC = O.P.ROI(3) * exp(Steps*sqrt(-1));
            CircleX = real(CircleC) + O.P.ROI(1);
            CircleY = imag(CircleC) + O.P.ROI(2);
            H = plot(O.GUI.AH(i), CircleX,CircleY,'Color',color,'LineWidth',2,'Hittest','Off');
        end

        function Clims = GetClims(O, InputDat, Perc)
            P95=prctile(InputDat,Perc(1),'all');
            P05=prctile(InputDat,Perc(2),'all');
            Clims = [P05, P95];
        end

        function selectROI(O,H,E)

            CP =  get(H,'CurrentPoint');
            O.P.ROI(1:2) = CP(1,1:2);
            delete(O.GUI.ROICoords);
            O.GUI.ROICoords = uicontrol('Style', 'text', 'FontSize', 7, 'String', ['ROI Coordinates X: ' num2str(O.P.ROI(1)) ', Y: ' num2str(O.P.ROI(2))], 'Position', [10, 520, 300, 15]);
            SelType = get(O.P.FIG,'SelectionType');

            O.ROIMask = O.findROIMask;
            set(O.P.FIG,'Name','Computing...'); drawnow;
            O.updateROIAverages;
            set(O.P.FIG,'Name', O.FigureName)
            for i =1:O.AxNum
                delete(O.GUI.Circle.left(i));
                O.GUI.Circle.left(i) = O.redrawCircle(i, 'm'); 
            end
            if strcmp(O.SelP, 'Summary')
                O.updateFLAverages
            end
        end
        
        function ROIMask = findROIMask(O)
            [Y, X] = meshgrid(O.Y,O.X);
            ROIMask = sqrt((X - O.P.ROI(1) ).^2 + (Y - O.P.ROI(2) ).^2) <= O.P.ROI(3);
            ROIMask = double(ROIMask);
            ROIMask(ROIMask==0) = NaN;
        end
        
        function updateROIAverages(O)
            ROIAll = O.T.Data.(O.SelP).*O.ROIMask;
            %ROIAll(ROIAll==0) = NaN; % Replace 0 entries from Mask (which cannot be set to NaN, as they are logical
            O.ROIAvgImage  = squeeze(nanmean(nanmean(ROIAll,2),1)); % Average over Image Dimensions   
            ROIAverageYLims  = [min(100*O.ROIAvgImage(1.8*O.P.FR:1:5*O.P.FR, :), [], 'all')*1.1,...
                            max(100*O.ROIAvgImage(1.8*O.P.FR:1:5*O.P.FR, :), [], 'all')*1.1];
            axes(O.GUI.AH(11));
            for i = 1:size(O.T.Data.(O.SelP), 4)
                PlotVis = O.GUI.ROIAverage(i).Visible;
                delete(O.GUI.ROIAverage(i));
                O.GUI.ROIAverage(i) = plot(O.Time-2, 100*O.ROIAvgImage(:, i), 'Color', O.LineColors(i, :), 'LineWidth', O.LineWidths(i), 'Visible', PlotVis);
            end
            O.GUI.AH(11).YLim=[ROIAverageYLims(1),ROIAverageYLims(2)];
            lgd = legend(O.Legend, 'Position', [0.8, 0.15, 0.1, 0.1], 'ItemHitFcn', @O.legendClickCallback);
            lgd.FontSize = 6;
        end
        
        function updateLegend(O, LegTexTop, LegTexBot)
            %Updates legend when the parameter to compare is switched
            O.Legend = {};
            for i= 1:4
                O.Legend = [O.Legend, {[LegTexTop, num2str(O.T.Parameters.PreTimes(i))]}];
            end
            for i= 1:4
                O.Legend = [O.Legend, {[LegTexBot, num2str(O.T.Parameters.PreTimes(i))]}];
            end
        end
        
        function updateFLAverages(O)
            ROIFL = O.T.FLAvg.*O.ROIMask;
            FLAvgImage = squeeze(nanmean(nanmean(ROIFL,2),1));
            ROIAverageYLims  = [min(100*FLAvgImage, [], 'all')*1.1,...
                                max(100*FLAvgImage, [], 'all')*1.1];
            axes(O.GUI.AH(6));
            for i = 1:size(O.T.FLAvg, 4)
                PlotVis = O.GUI.FLAverage(i).Visible;
                delete(O.GUI.FLAverage(i));
                O.GUI.FLAverage(i) = plot(O.Time(1:250)-0.5, 100*FLAvgImage(:, i), 'Color', O.LineColors(i, :), 'LineWidth', O.LineWidths(i), 'Visible', PlotVis);
            end
            O.GUI.AH(6).YLim=[ROIAverageYLims(1),ROIAverageYLims(2)];
            lgd = legend({'First 10 Texture Trials', 'Last 10 Texture Trials', 'First 10 Silent Trials', 'Last 10 Silent Trials'}, 'Position', [0.8, 0.35, 0.1, 0.1], 'ItemHitFcn', @O.legendClickCallback);
            lgd.FontSize = 6;

        end
        
        function selectTime(O,H,E)
          % Executed by clicking on the average time trace
          CP =  get(H,'CurrentPoint');
          cTime = CP(1,1);
          O.Vid.CurrentTime = O.Time(dsearchn(O.Time,cTime));

          O.GUI.TimeIndicator.XData = repmat(O.Vid.CurrentTime,1,2);

          O.plotTimePoint;
        end

        function nextTimeStep(O, ~, ~)
          O.Vid.CurrentTime = O.Time(dsearchn(O.Time,O.Vid.CurrentTime)+1);
          O.GUI.TimeIndicator.XData = repmat(O.Vid.CurrentTime,1,2);
          O.plotTimePoint;
        end

        function prevTimeStep(O, ~, ~)
          O.Vid.CurrentTime = O.Time(dsearchn(O.Time,O.Vid.CurrentTime)-1);
          O.GUI.TimeIndicator.XData = repmat(O.Vid.CurrentTime,1,2);
          O.plotTimePoint;
        end

        function MapsdropdownCallback(O, hObject, ~)
        % Get the selected option
        selectedOption = hObject.String{hObject.Value};
        disp(['Selected option: ' selectedOption]);
        Buttons = fieldnames(O.GUI.Buttons);
        for i = 1:length(Buttons)
            O.GUI.Buttons.(Buttons{i}).Visible = 'on';
        end
        for i = 1:10
            delete(O.GUI.AH(i));
        end
        if strcmp(O.SelP, 'Summary')
            O.ROIAvgImage = zeros(length(O.Time), 8);
            O.GUI.TimeIndicator = plot(O.GUI.AH(11), [O.Vid.CurrentTime,O.Vid.CurrentTime],[-1000,1000],'-','Color','r', 'HandleVisibility', 'off');
            for j =1:8
                delete(O.GUI.ROIAverage(j));
                O.GUI.ROIAverage(j) = plot(O.GUI.AH(11), O.Time, 100*O.ROIAvgImage(:, j), 'Linewidth', 1.5, 'Visible', 'off');
            end
            set(O.GUI.AH(11), 'HitTest', 'on');
            O.GUI.AH(11).XLim = [-1, 8];
        end
        if strcmp(selectedOption, 'Tex vs Sil')
            O.createAxes
            O.updateLegend('Tex Pretime ', 'Sil Pretime ');
            O.SelP = 'Full';
            O.plotSilMaps;
            O.plotTimePoint
            O.AxNum = 10;
        elseif strcmp(selectedOption, 'Correlations')
            O.createAxes
            O.updateLegend('HighCFC Pretime ', 'LowCFC Pretime ');
            O.SelP = 'Corr';
            O.plotCorrMaps;
            O.plotTimePoint
            O.AxNum = 10;
        elseif strcmp(selectedOption, 'Summary')
            O.Legend = {'Texture all Pretimes', 'Texture Pretime 3 and 5'};
            delete(O.GUI.TimeIndicator);
            set(O.GUI.AH(11), 'HitTest', 'off');
            for i = 3:length(O.GUI.ROIAverage)
                delete(O.GUI.ROIAverage(i));
            end
            O.GUI.AH(11).XLim = [-1, 3];
            Buttons = fieldnames(O.GUI.Buttons);
            for i = 1:length(Buttons)
                O.GUI.Buttons.(Buttons{i}).Visible = 'off';
            end
            O.GUI.AH(1)=axes('position',[-0.01,0.69,0.21,0.21]);
            O.GUI.AH(2)=axes('position',[0.200,0.69,0.21,0.21]);
            O.GUI.AH(3)=axes('position',[0.410,0.69,0.21,0.21]);
            O.GUI.AH(4)=axes('position',[-0.01,0.37,0.21,0.21]);
            O.GUI.AH(5)=axes('position',[0.200,0.37,0.21,0.21]);
            O.GUI.AH(6)=axes('position',[0.410,0.37,0.30,0.2]);
            O.SelP = 'Summary';
            FLAvgImage = zeros(250, 4);
            hold(O.GUI.AH(6), 'on');
            for i = 1:size(O.T.FLAvg, 4)
                O.GUI.FLAverage(i) = plot(O.GUI.AH(6), 100*FLAvgImage(:, i));
            end
            for i = 1:10
                % Calculate the x-coordinate of the center of each rectangle
                xCenter = 0.2*(i-1);

                % Use the rectangle function to create each rectangle with specified alpha value
                O.GUI.FLVocStims(i) = rectangle(O.GUI.AH(6), 'Position', [xCenter, -5, 0.1, 10], 'FaceColor', 'g', 'EdgeColor', 'none', 'HandleVisibility', 'off');
            end
            O.plotSumMaps;
            O.updateFLAverages
            O.AxNum = 3;
        end
        for i =1:O.AxNum
            delete(O.GUI.Circle.left(i));
            O.GUI.Circle.left(i) = O.redrawCircle(i, 'm'); 
        end
        
        O.updateROIAverages;
        end
        
        function PreTimedropdownCallback(O, hObject, ~)
            selectedOption = hObject.String{hObject.Value};
            disp(['Selected option: ' selectedOption]);
            for i = 1:length(O.T.Parameters.PreTimes)
                if strcmp(selectedOption, num2str(O.T.Parameters.PreTimes(i)))
                    O.Vid.PreTime = i;
                end
            end
            O.plotTimePoint
        end
        
        function createButtons(O)
            for i = 1:4
                O.GUI.Buttons.(['VocStimButton', num2str(i)]) = uicontrol('Style', 'togglebutton', 'BackgroundColor', 'g', 'String', 'Stims','FontSize', 6, ...
                                        'Position', [40 + (i-1) * 265, 336, 100, 15]);
                O.GUI.Buttons.(['VocStimButton', num2str(i)]).Callback = {@O.toggleVocStims, i};
            end

            O.GUI.Buttons.CaxisButton = uicontrol('Style', 'togglebutton', 'String', 'Caxis','FontSize', 6 ,...
                                        'Position', [1150, 336, 70, 15]);
            O.GUI.Buttons.CaxisButton.Callback = {@O.toggleCaxis};

            O.GUI.Buttons.PrevTimeStepButton = uicontrol('Style', 'pushbutton', 'String', '⬅', 'FontSize', 6,...
                                        'Position', [1090, 336, 25, 15]);
            O.GUI.Buttons.PrevTimeStepButton.Callback = {@O.prevTimeStep};
            O.GUI.Buttons.NextTimeStepButton = uicontrol('Style', 'pushbutton', 'String', '➡', 'FontSize', 6,...
                                        'Position', [1120, 336, 25, 15]);
            O.GUI.Buttons.NextTimeStepButton.Callback = {@O.nextTimeStep};
        end
        
        function legendClickCallback(O, ~, event)
            % Toggle the visibility of the corresponding plot
            if strcmpi(event.Peer.Visible, 'on')
                event.Peer.Visible = 'off';
            else
                event.Peer.Visible = 'on';
            end
        end

        function toggleVocStims(O, ~, ~, PlotIndex)
            if strcmp(O.GUI.VocStims(PlotIndex, 1).Visible, 'on')
                set(O.GUI.VocStims(PlotIndex, :), 'Visible', 'off');
            else
                set(O.GUI.VocStims(PlotIndex, :), 'Visible', 'on');
            end
            
        end
        
        function toggleCaxis(O, src, ~)
            % Get the value of the toggle button
            buttonValue = get(src, 'Value');
            if buttonValue
                O.Vid.Caxis = 1;
            else
                O.Vid.Caxis = 0;
            end
            O.plotTimePoint;
        end
        
        function ellipseMask = createCranMask(O)
            % Parameters for the ellipse
            centerX = 77;  % X-coordinate of the center
            centerY = 73;  % Y-coordinate of the center
            semiMajorAxis = 57;  % Semi-major axis length
            semiMinorAxis = 55;  % Semi-minor axis length

            % Size of the matrix
            matrixSize = [144, 150];

            % Create a grid of coordinates
            [X, Y] = meshgrid(1:matrixSize(2), 1:matrixSize(1));

            % Create the elliptical mask
            ellipseMask = ((X - centerX) / semiMajorAxis).^2 + ((Y - centerY) / semiMinorAxis).^2 <= 1;

        end

        
  end
end