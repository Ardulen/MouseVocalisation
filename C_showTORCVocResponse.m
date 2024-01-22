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
    AxNum = 8;
    TuningR = [];
    Xoffset = 0.20;
    Yoffset = 0.25;
    Toffset = 0.25;
  end
  
  
  methods
    
    function O = C_showTORCVocResponse(R, T,varargin)

        P = parsePairs(varargin);
        checkField(P,'ROI',[1.14, 1.77, 0.2]); % [centerX centerY radius] in mm
        checkField(P,'FIG',1);
        checkField(P, 'Source', 'VideoCalcium');
        checkField(P, 'FR', 100);
        checkField(P, 'CranMask', 1);
        checkField(P, 'WindowSize', 5);

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
        O.Legend = {'Tex + PreTime 0.5', 'Tex + PreTime 1', 'Tex + PreTime 3', 'BaseLine: Tex + PreTime 5 Moving Median Window 5 frames', 'Sil + Pretime 0.5', 'BaseLine Sil Pretime 0.5', 'Sil + Pretime 1', 'BaseLine Sil + Pretime 1', 'Sil + PreTime 3', 'BaseLine Sil + Pretime 3'};
        %% pixels to mm transformation  
        [X, Y, PixelPerMM] = C_pixelToMM(P,R,R.Frames);
        O.PixelPerMM = PixelPerMM;
        O.X = X; O.Y = Y;
        
        %% Set Cortex Area map
        [~, ~, ~, ~, O.TuningR] = C_showCortexRegionsTuningWF('Animal', O.P.Animal, 'FIG', 0);

        
        %% Set figure
        MP = get(0,'MonitorPositions');
        NY = MP(1,end); HPixels = 540;
        O.FigureName=[O.P.Animal,' R',num2str(O.P.Recording),' Texture Response'];
        Fig = figure(O.P.FIG); clf; set(O.P.FIG,'name', O.FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1250,HPixels]);

        O.LineColors = [0, 0.4470, 0.7410; 0.8500, 0.3250, 0.0980; 0.9290, 0.6940, 0.1250; 0.4940, 0.1840, 0.5560];
        O.LineStyles = [':', "-"];
        O.LineWidths = [2, 1.5, 1];
        
        
        
        O.createAxes(4, 2);
        [~, O.GUI.AH(31)] = axesDivide(1,1,[0.04, 0.1, 0.7, 0.2],[],0.3,'c');
        annotation('textbox','String', O.FigureName,'Position',[0.3,0.96,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
        



        %% Time Points
        O.Time=R.Frames.TimeAvg;
        %% popup menus
        
        O.GUI.Mapspopup = uicontrol('Style',  'popup', 'FontSize', 8, 'Position', [870, 520, 150, 15]);
        O.GUI.Mapspopup.String = {'Tex vs Sil', 'Correlations', 'Variances', 'Realizations', 'Vocalization Frequency', 'VocFreqs Silent', 'Summary'};
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
        O.T.OffsetSilAvg = mean(O.T.VocResp.OffsetSil, 3);
        O.T.OffsetAvg = mean(O.T.OffsetResp, 3);
        FirstTrialVocResp = zeros([O.ImageSize(1), O.ImageSize(2), 390, 10]);
        FirstTrialVocRespSil = zeros([O.ImageSize(1), O.ImageSize(2), 390, 10]);
        LastTrialVocResp = zeros([O.ImageSize(1), O.ImageSize(2), 390, 10]);
        LastTrialVocRespSil = zeros([O.ImageSize(1), O.ImageSize(2), 390, 10]);
        TexTrialNums = GetTrialNums(T.Parameters.Corrs, T.Parameters.Vars, T.Parameters.Reals, R.General, 0, T.Parameters.NTrials, T.Parameters.PreTimes, T.Parameters.VocFreqs);
        SilTrialNums = GetTrialNums(T.Parameters.Corrs, T.Parameters.Vars, T.Parameters.Reals, R.General, 1, T.Parameters.NTrials, T.Parameters.PreTimes, T.Parameters.VocFreqs);
        for i = 1:10
            PreTime = R.General.Paradigm.Trials(TexTrialNums(i)).Stimulus.ParSequence.PreTime;
            FirstTrialVocResp(:, :, :, i) = R.Frames.AvgTime(:, :, (PreTime+1)*O.P.FR:(PreTime+4.89)*O.P.FR, TexTrialNums(i));
            PreTime = R.General.Paradigm.Trials(TexTrialNums(end-i)).Stimulus.ParSequence.PreTime;
            LastTrialVocResp(:, :, :, i) = R.Frames.AvgTime(:, :, (PreTime+1)*O.P.FR:(PreTime+4.89)*O.P.FR, TexTrialNums(end-i));
            PreTime = R.General.Paradigm.Trials(SilTrialNums(i)).Stimulus.ParSequence.PreTime;
            FirstTrialVocRespSil(:, :, :, i) = R.Frames.AvgTime(:, :, (PreTime+1)*O.P.FR:(PreTime+4.89)*O.P.FR, SilTrialNums(i));
            PreTime = R.General.Paradigm.Trials(SilTrialNums(end-i)).Stimulus.ParSequence.PreTime;
            LastTrialVocRespSil(:, :, :, i) = R.Frames.AvgTime(:, :, (PreTime+1)*O.P.FR:(PreTime+4.89)*O.P.FR, SilTrialNums(end-i));
        end
        O.T.FLAvg(:, :, :, 1) = mean(FirstTrialVocResp, 4);
        O.T.FLAvg(:, :, :, 2) = mean(LastTrialVocResp, 4);
        O.T.FLAvg(:, :, :, 3) = mean(FirstTrialVocRespSil, 4);
        O.T.FLAvg(:, :, :, 4) = mean(LastTrialVocRespSil, 4);
        


        
        %% plot ROI Traces

        cAH = O.GUI.AH(31);
        set(cAH,'ButtonDownFcn',{@O.selectTime});
        O.ROIAvgImage = zeros(length(O.Time), 10);
        hold(cAH, 'on');
        for j =1:10
            O.GUI.ROIAverage(j) = plot(cAH, O.Time, 100*O.ROIAvgImage(:, j), 'Linewidth', 1.5, 'Visible', 'off');
        end
        for j = 1:4
            for i = 1:10
                % Calculate the x-coordinate of each rectangle
                xCenter = O.T.Parameters.PreTimes(j)+0.2*(i-1);

                % Use the rectangle function to create each rectangle
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
        for i =1:8
            O.GUI.Circle.left(i) = O.redrawCircle(i, 'm');
        end
        O.ROIMask = O.findROIMask;
        O.updateROIAverages;
        
    end
        
        function createAxes(O, Xax, Yax)
            [~,AHTop] = axesDivide(Xax,Yax,[0.02, 0.4, 1, 0.5],[],0.4, 'c');
            [~,AHAreas] = axesDivide(Xax,Yax,[0.02, 0.4, 1, 0.5],[],0.4, 'c');
            set(AHAreas, 'Visible', 'off', 'HitTest', 'off')
            TotAx = Xax*Yax;
            O.GUI.AH(1:2*TotAx) = [AHTop;AHAreas]';
            O.plotAreas;
        end
        
        function InitParTab(O, Yax, Leg, SelP, AxNum, Clims)
            O.AxNum = AxNum;           
            O.createAxes(4, Yax)
            O.updateLegend(Leg);
            O.SelP = SelP;
            O.plotParMaps(SelP, Clims);
            O.plotTimePoint;
        end
        
        function plotParMaps(O, Par, Clims)
            Clims = O.GetClims(O.T.VocResp.(Par), Clims);
            for j = 1:length(O.T.Parameters.(Par))
               for i = 1:length(O.T.Parameters.PreTimes)-1
                    O.plotMaps(Par, O.T.VocResp.(Par)(:, :, (j-1)*(length(O.T.Parameters.PreTimes)-1)+i), 'Area under graph',  Clims, O.LineColors(i, :), (j-1)*4+i, O.Legend{(j-1)*4+i}, 'jet')
               end
            end
        end    
        
        function plotSilMaps(O)
            % plots the response maps for different pretimes for Trials
            % with and without Texture
            ClimsFull = O.GetClims(O.T.VocResp.PreTime(:, :, :, 1), [95, 5]);
            ClimsSil = O.GetClims(O.T.VocResp.Sil(:, :, :, 1), [95, 5]);
            for i = 1:length(O.T.Parameters.PreTimes)-1
                O.plotMaps('Full', O.T.VocResp.PreTime(:, :, i), 'Area under Graph', ClimsFull, O.LineColors(i, :), i, O.Legend{i}, 'jet')
                O.plotMaps('Sil', O.T.VocResp.Sil(:, :, i), 'Area under Graph', ClimsSil, O.LineColors(i, :), i+length(O.T.Parameters.PreTimes), O.Legend{(i-0.5)*2+4}, 'jet');
            end
        end 
        
        function plotSumMaps(O)
            Clims = O.GetClims(O.T.TexResp, [95, 5]);
            O.plotMaps("TexResp", O.T.TexResp, 'Change Norm (%)', Clims, O.LineColors(1, :), 1, 'Texture Response', 'jet');
            Clims = O.GetClims(O.T.FullVocAvg, [95, 5]);
            O.plotMaps('AvgVocResp', O.T.FullVocAvg, 'Area of peak', Clims, 'k', 2, 'Texture Voc resp', 'jet')
            Clims = O.GetClims(O.T.SilVocAvg, [95, 5]);
            O.plotMaps('AvgVocResp', O.T.SilVocAvg, 'Area under peak', Clims, 'k', 3, 'Silent Voc resp', 'jet')
            Clims = O.GetClims(O.T.SusLvl, [95, 5]);
            O.plotMaps("SusLvl", O.T.SusLvl, 'Change Norm (%)', Clims, O.LineColors(2, :), 4, 'Sustained Level', 'jet');
            Clims = O.GetClims(O.T.FitDecMap, [95, 5]);
            O.plotMaps("FitDec", O.T.FitDecMap, 'Tau', Clims, O.LineColors(2, :), 5, 'Decay constant', 'jet');
            Clims = O.GetClims(O.T.OffsetSilAvg, [95, 5]);
            O.plotMaps("OffSetSilAvg", O.T.OffsetSilAvg, 'Avg Area of peak', Clims, 'k', 6, 'Voc offset resp', 'jet');
            Clims = O.GetClims(O.T.OffsetAvg, [95, 5]);
            O.plotMaps("OffSetAvg", O.T.OffsetAvg, 'Avg Area of peak', Clims, 'k', 7, 'Tex+Voc offset resp', 'jet');

        end
        
        function plotTimePoint(O)
            for i = 1:size(O.T.Data.(O.SelP), 4)/length(O.T.Parameters.PreTimes)
                MapData = 100*O.T.Data.(O.SelP)(:, :, round((O.Vid.CurrentTime+2)*O.P.FR), round((i-1)*4+O.Vid.PreTime));
                if O.Vid.Caxis
                    Clims = O.GetClims(MapData, [95, 5]);
                else
                    Clims = O.Vid.Clims;
                end
                O.plotMaps(['TimePoint', num2str(i)], MapData, ' ', Clims, 'k', 4+4*(i-1), ['Pretime', num2str(O.T.Parameters.PreTimes(O.Vid.PreTime)),' @ ',num2str(O.Vid.CurrentTime,2),'s'], 'bone')
            end
        end
        
        function plotAreas(O)
            for i = O.AxNum+1:2*O.AxNum
                cAH = O.GUI.AH(i);
                for iA = 1:size(O.TuningR.Areas,3)
                    cA = O.TuningR.AreaNames{iA};
                    patch(cAH, O.TuningR.AreaVerticesCoordsMM.(cA).X+O.Xoffset,...
                    O.TuningR.AreaVerticesCoordsMM.(cA).Y+O.Yoffset,[0.2,0.2,0.2],'FaceAlpha',0.2, 'EdgeColor', 'w', 'LineWidth', 1, 'Visible', 'off');
                    text(cAH, mean(O.TuningR.AreaVerticesCoordsMM.(cA).X)+O.Xoffset-O.Toffset,...
                    mean(O.TuningR.AreaVerticesCoordsMM.(cA).Y)+O.Yoffset, cA, 'FontSize', 4, 'Color', 'w', 'FontWeight', 'Bold', 'Visible', 'off');
                end
                colorbar(cAH, 'Visible', 'off')
                set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
                ylim(cAH, [min(O.Y), max(O.Y)]);
                xlim(cAH, [min(O.X), max(O.X)]);
            end   
        end
        
        function plotMaps(O, GUIDat, MapData, ylab, Clims, Color, AxNum, Title, ColMap)
            %plots a single map for given data
            cAH = O.GUI.AH(AxNum);
            hold(cAH, 'on');
            O.GUI.(GUIDat) = imagesc(cAH, O.X, O.Y, MapData'); %[cAH, AHB, cBar] = HF_imagescCraniotomy(Fig,cAH,cAH,O.X,O.Y,Adaptmap(:, :, O.P.Pl(i)),Adaptmap(:, :, O.P.Pl(i)),R.Frames.CraniotomyMask, 'AlphaF', 1, 'AlphaB', 0); 
            O.GUI.(GUIDat).AlphaData = O.CraniotomyMask'.*1;
            set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
            set(cAH, 'FontSize', 5);
            set(cAH,'ButtonDownFcn',{@O.selectROI});
            colormap(cAH, ColMap)
            caxis(cAH, Clims);
            set(O.GUI.(GUIDat),'HitTest','off');
            c1 = colorbar(cAH);
            ylabel(c1, ylab);
            %ylabel(cAH, 'Mediolateral (mm)', 'FontSize', 4); xlabel(cAH, 'Anteroposterior (mm)', 'FontSize', 4);
            title(cAH, Title, 'Color', Color, 'FontSize', 6);
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
            SelType = get(O.P.FIG,'SelectionType');
            if strcmp(SelType, 'alt')
                O.toggleAreaVis;
            else    
                O.P.ROI(1:2) = CP(1,1:2);
                delete(O.GUI.ROICoords);
                O.GUI.ROICoords = uicontrol('Style', 'text', 'FontSize', 7, 'String', ['ROI Coordinates X: ' num2str(O.P.ROI(1)) ', Y: ' num2str(O.P.ROI(2))], 'Position', [10, 520, 300, 15]);


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
            axes(O.GUI.AH(31));
            for i = 1:size(O.T.Data.(O.SelP), 4)
                PlotVis = O.GUI.ROIAverage(i).Visible;
                delete(O.GUI.ROIAverage(i));
                ColIndex = mod(i - 1, 4) + 1;
                WidthIndex = ceil(i/4);
                O.GUI.ROIAverage(i) = plot(O.Time-2, 100*O.ROIAvgImage(:, i)', 'Color', O.LineColors(ColIndex, :), 'LineWidth', O.LineWidths(WidthIndex), 'Visible', PlotVis);
            end
            O.GUI.AH(31).YLim=[ROIAverageYLims(1),ROIAverageYLims(2)];
            lgd = legend(O.Legend, 'Position', [0.8, 0.11, 0.1, 0.1], 'ItemHitFcn', @O.legendClickCallback);
            lgd.FontSize = 5;
        end
        
        function updateLegend(O, LegTex)
            %Updates legend when the parameter to compare is switched
            O.Legend = {};
            for j = 1:length(LegTex)
                for i= 1:length(O.T.Parameters.PreTimes)-1
                    O.Legend = [O.Legend, strcat(LegTex(j), num2str(O.T.Parameters.PreTimes(i)))];
                end
                O.Legend = [O.Legend, strcat(LegTex(j), num2str(O.T.Parameters.PreTimes(i+1)), ' Moving Median, WindowSize:', num2str(O.P.WindowSize), ' frames')];
            end
        end
        
        function updateFLAverages(O)
            ROIFL = O.T.FLAvg.*O.ROIMask;
            FLAvgImage = squeeze(nanmean(nanmean(ROIFL,2),1));
            ROIAverageYLims  = [min(100*FLAvgImage, [], 'all')*1.1,...
                                max(100*FLAvgImage, [], 'all')*1.1];
            axes(O.GUI.AH(15));
            for i = 1:size(O.T.FLAvg, 4)
                PlotVis = O.GUI.FLAverage(i).Visible;
                delete(O.GUI.FLAverage(i));
                O.GUI.FLAverage(i) = plot(O.Time(1:390)-1, 100*FLAvgImage(:, i)', 'Color', O.LineColors(i, :), 'LineWidth', 1.5, 'Visible', PlotVis);
            end
            O.GUI.AH(15).YLim=[ROIAverageYLims(1),ROIAverageYLims(2)];
            O.GUI.AH(15).XLim = [-0.5, 2.5];
            lgd = legend({'First 10 Texture Trials', 'Last 10 Texture Trials', 'First 10 Silent Trials', 'Last 10 Silent Trials'}, 'Position', [0.8, 0.35, 0.1, 0.1], 'ItemHitFcn', @O.legendClickCallback);
            lgd.FontSize = 6;

        end
        
        function updateTimePlots(O)
            for i = 1:size(O.T.Data.(O.SelP), 4)/length(O.T.Parameters.PreTimes)
                MapData = 100*O.T.Data.(O.SelP)(:, :, round((O.Vid.CurrentTime+2)*O.P.FR), round((i-1)*4+O.Vid.PreTime));
                TimePoint = ['O.GUI.TimePoint', num2str(i)];
                set(eval(TimePoint), 'CData', MapData')
            end
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
          O.updateTimePlots;
        end

        function prevTimeStep(O, ~, ~)
          O.Vid.CurrentTime = O.Time(dsearchn(O.Time,O.Vid.CurrentTime)-1);
          O.GUI.TimeIndicator.XData = repmat(O.Vid.CurrentTime,1,2);
          O.updateTimePlots;
        end

        function MapsdropdownCallback(O, hObject, ~)
        % Get the selected option
        selectedOption = hObject.String{hObject.Value};
        disp(['Selected option: ' selectedOption]);
        Buttons = fieldnames(O.GUI.Buttons);
        for i = 1:length(Buttons)
            O.GUI.Buttons.(Buttons{i}).Visible = 'on';
        end
        for i = 1:2*O.AxNum
            delete(O.GUI.AH(i));
        end
        for i = 1:length(O.GUI.ROIAverage)
            delete(O.GUI.ROIAverage(i));
        end   
        if strcmp(O.SelP, 'Summary')
            O.GUI.TimeIndicator = plot(O.GUI.AH(31), [O.Vid.CurrentTime,O.Vid.CurrentTime],[-1000,1000],'-','Color','r', 'HandleVisibility', 'off');
            delete(O.GUI.AH(15));
            set(O.GUI.AH(31), 'HitTest', 'on');
            set(O.GUI.AH(31),'ButtonDownFcn',{@O.selectTime});
            O.GUI.AH(31).XLim = [-1, 8];
        end
        if strcmp(selectedOption, 'Tex vs Sil')
            O.AxNum = 8;
            O.createAxes(4, 2)
            O.Legend = {'Tex + PreTime 0.5', 'Tex + PreTime 1', 'Tex + PreTime 3', 'BaseLine: Tex + PreTime 5 Moving Median Window 5 frames', 'Sil + Pretime 0.5', 'BaseLine Sil Pretime 0.5', 'Sil + Pretime 1', 'BaseLine Sil + Pretime 1', 'Sil + PreTime 3', 'BaseLine Sil + Pretime 3'};
            O.SelP = 'Full';
            O.plotSilMaps;
            O.plotTimePoint
        elseif strcmp(selectedOption, 'Correlations')
            Leg = {'HighCFC Pretime ', 'LowCFC Pretime '};
            O.InitParTab(2, Leg, 'Corrs', 8, [95, 5]);
        elseif strcmp(selectedOption, 'Variances')
            for i = 1:length(O.T.Parameters.VocFreqs)
                Leg{i} = ['Var ', num2str(O.T.Parameters.Vars(i)), ' Pretime '];
            end  
            O.InitParTab(3, Leg, 'Vars', 12, [95, 5]);
        elseif strcmp(selectedOption, 'Realizations')
            Leg = {'Real 1 Pretime ', 'Real 2 Pretime ', 'Real 3 Pretime '};
            O.InitParTab(3, Leg, 'Reals', 12, [95, 5]);
        elseif strcmp(selectedOption, 'Vocalization Frequency')
            for i = 1:length(O.T.Parameters.VocFreqs)
                Leg{i} = ['Freq ', num2str(O.T.Parameters.VocFreqs(i)), ' Pretime '];
            end  
            O.InitParTab(3, Leg, 'VocFreqs', 12, [95, 5]);
        elseif strcmp(selectedOption, 'VocFreqs Silent')
            for i = 1:length(O.T.Parameters.VocFreqs)
                Leg{i} = ['Freq ', num2str(O.T.Parameters.VocFreqs(i)), ' Pretime '];
            end  
            O.InitParTab(3, Leg, 'VocFreqsSil', 12, [95, 5]);
        elseif strcmp(selectedOption, 'Summary')
            O.AxNum = 7;
            O.Legend = {'Texture all Pretimes', 'Texture Pretime 3 and 5'};
            delete(O.GUI.TimeIndicator);
            set(O.GUI.AH(31), 'HitTest', 'off');
            set(O.GUI.AH(31),'ButtonDownFcn', ' ');
            for i = 3:length(O.GUI.ROIAverage)
                delete(O.GUI.ROIAverage(i));
            end
            O.GUI.AH(31).XLim = [-1, 3];
            Buttons = fieldnames(O.GUI.Buttons);
            for i = 1:length(Buttons)
                O.GUI.Buttons.(Buttons{i}).Visible = 'off';
            end
            for i =1:2    
                O.GUI.AH((i-1)*7+1)=axes('position',[-0.01,0.69,0.21,0.21]);
                O.GUI.AH((i-1)*7+2)=axes('position',[0.200,0.69,0.21,0.21]);
                O.GUI.AH((i-1)*7+3)=axes('position',[0.410,0.69,0.21,0.21]);
                O.GUI.AH((i-1)*7+4)=axes('position',[-0.01,0.37,0.21,0.21]);
                O.GUI.AH((i-1)*7+5)=axes('position',[0.200,0.37,0.21,0.21]);
                O.GUI.AH((i-1)*7+6)=axes('position',[0.620,0.69,0.21,0.21]);
                O.GUI.AH((i-1)*7+7)=axes('position',[0.830,0.69,0.21,0.21]);

            end
            for i = 8:14
                set(O.GUI.AH(i), 'Visible', 'off', 'HitTest', 'off');
            end    
            O.GUI.AH(15)=axes('position',[0.410,0.37,0.30,0.2]);
            O.plotAreas;
            O.SelP = 'Summary';
            FLAvgImage = zeros(300, 4);
            hold(O.GUI.AH(15), 'on');
            for i = 1:size(O.T.FLAvg, 4)
                O.GUI.FLAverage(i) = plot(O.GUI.AH(15), 100*FLAvgImage(:, i));
            end
            for i = 1:10
                % Calculate the x-coordinate of the center of each rectangle
                xCenter = 0.2*(i-1);

                % Use the rectangle function to create each rectangle with specified alpha value
                O.GUI.FLVocStims(i) = rectangle(O.GUI.AH(15), 'Position', [xCenter, -10, 0.1, 20], 'FaceColor', 'g', 'EdgeColor', 'none', 'HandleVisibility', 'off');
            end
            O.plotSumMaps;
            O.updateFLAverages
        end
        ROILineNums = size(O.T.Data.(O.SelP), 4);
        O.ROIAvgImage = zeros(length(O.Time), ROILineNums);
        for j =1:ROILineNums
            O.GUI.ROIAverage(j) = plot(O.GUI.AH(31), O.Time, 100*O.ROIAvgImage(:, j), 'Linewidth', 1.5, 'Visible', 'off');
        end
            set(O.GUI.AH(31), 'HitTest', 'on');
        for i =1:O.AxNum
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
            for i = 1:3
                O.GUI.Buttons.(['VocStimButton', num2str(i)]) = uicontrol('Style', 'togglebutton', 'BackgroundColor', 'g', 'String', 'Stims','FontSize', 6, ...
                                        'Position', [60 + (i-1) * 337, 185, 100, 15]);
                O.GUI.Buttons.(['VocStimButton', num2str(i)]).Callback = {@O.toggleVocStims, i};
            end

            O.GUI.Buttons.CaxisButton = uicontrol('Style', 'togglebutton', 'String', 'Caxis','FontSize', 6 ,...
                                        'Position', [1115, 185, 70, 15]);
            O.GUI.Buttons.CaxisButton.Callback = {@O.toggleCaxis};

            O.GUI.Buttons.PrevTimeStepButton = uicontrol('Style', 'pushbutton', 'String', '⬅', 'FontSize', 6,...
                                        'Position', [1055, 185, 25, 15]);
            O.GUI.Buttons.PrevTimeStepButton.Callback = {@O.prevTimeStep};
            O.GUI.Buttons.NextTimeStepButton = uicontrol('Style', 'pushbutton', 'String', '➡', 'FontSize', 6,...
                                        'Position', [1085, 185, 25, 15]);
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
        
        function toggleAreaVis(O)
            if strcmp(O.GUI.AH(O.AxNum+1).Children(1).Visible, 'off')
                for i = O.AxNum+1:2*O.AxNum
                    set(O.GUI.AH(i).Children, 'Visible', 'on')
                end
            else
                for i = O.AxNum+1:2*O.AxNum
                    set(O.GUI.AH(i).Children, 'Visible', 'off')
                end
            end    
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