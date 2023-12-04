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
    ROIAll = [];
    ROIAvgImage  = [];
    ROIAvgImageTrial = [];
    ROISEMImageTrial  = [];
    General = [];
    LineColors = [];
    LineStyles = [];
    LineWidths = [];
    FigureName = {};
    ImageSize = [];
    NTrials = [];
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
        O.T = T;
        O.General = R.General;
        O.P = P;
        if P.CranMask
            O.CraniotomyMask = R.Frames.CraniotomyMask;
        else    
            O.CraniotomyMask = O.createCranMask;
        end
        %% Set figure
        MP = get(0,'MonitorPositions');
        NY = MP(1,end); HPixels = 540;
        O.FigureName=[O.P.Animal,' R',num2str(O.P.Recording),' Texture Response'];
        Fig = figure(O.P.FIG); clf; set(O.P.FIG,'name', O.FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1250,HPixels]);

        O.LineColors = [0.5, 0.5, 1; 0.4, 0.5, 0.4; 1, 0.5, 0.5; 0, 0, 1; 0, 0.5, 0; 1, 0, 0];
        O.LineStyles = [':', ":", ':', "-", "-", "-"];
        O.LineWidths = [1.5, 1.5, 1.5, 1.5];
        
        [~,AHTop] = axesDivide(5,2,[0.05, 0.4, 0.9, 0.5],[],0.20,'c');
        [~,AHBottom] = axesDivide(1,1,[0.05, 0.1, 0.9, 0.2],[],0.3,'c');
        O.GUI.AH = [AHTop(:); AHBottom(:), ;AHTop(:)];
        
        annotation('textbox','String', O.FigureName,'Position',[0.3,0.96,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);

        %% pixels to mm transformation  
        [X, Y, PixelPerMM] = C_pixelToMM(P,R,R.Frames);
        O.PixelPerMM = PixelPerMM;
        O.X = X; O.Y = Y;

        %% Time Points
        O.Time=R.Frames.TimeAvg;
        %% popup menus

        O.GUI.Mapspopup = uicontrol('Style',  'popup', 'FontSize', 8,'Position', [900, 520, 200, 15]);
        O.GUI.Mapspopup.String = {'Tex vs Sil', 'Correlations', 'Summary'};
        O.GUI.Mapspopup.Callback = @O.MapsdropdownCallback;
        %O.GUI.Varspopup = uicontrol('Style', 'popup', 'Position', [10, 500, 120, 30]);
        %O.GUI.Varspopup.String = {'Var 0.02', 'Var 0.2'};
        %O.GUI.Varspopup.Callback = @O.VarsdropdownCallback;
        %% display current ROI coordinates
        O.GUI.ROICoords = uicontrol('Style', 'text', 'FontSize', 7, 'String', ['ROI Coordinates X: ' num2str(O.P.ROI(1)) ', Y: ' num2str(O.P.ROI(2))], 'Position', [10, 520, 300, 15]);

        %% visibility buttons
        O.GUI.buttonHandles = gobjects(6, 1);
        for i = 1:8
        O.GUI.buttonHandles(i) = uicontrol('Style', 'togglebutton', ...
                                'String', O.GUI.buttonLabels{i}, ...
                                'Position', [920 + (i-1) * 50, 242, 30, 30]);
        O.GUI.buttonHandles(i).Callback = {@O.togglePlotVisibility, i};
        end



        %% plot ROI Traces

        cAH = O.GUI.AH(9);
        O.ROIAvgImage = zeros(length(O.Time), 6);
        hold(cAH, 'on');
        for j =1:8
            O.GUI.ROIAverage(j) = plot(cAH, O.Time, 100*O.ROIAvgImage(:, j), 'Color', O.line_colors(j, :), 'Linewidth', 1.5, 'LineStyle', O.line_styles(j));
        end
        plot(cAH, [0, 0],[-1000,1000],'-','Color','k', 'HandleVisibility', 'Off');
        xlim(cAH, [-1, O.P.Pretimes(1)]);
        plot(cAH, [-3, 10],[0,0],'-','Color','k', 'HandleVisibility', 'Off');
        %set(cAH,'ButtonDownFcn',{@O.SelectTimePoint});
        set(O.GUI.ROIAverage,'HitTest','off');
        xlabel(cAH, 'time (s)');
        ylabel(cAH, 'Change norm. (%)');
        title(cAH, 'Averages over ROI');


        O.Sil;  
        for i =1:6
        O.GUI.Circle.left(i) = O.redrawCircle(i, 'm');
        end
        O.ROIMask = O.findROIMask;
        O.updateROIAverages;

        end

        function PlotSilMaps(O)
            % plots the response maps for different pretimes for Trials
            % with and without Texture
            ClimsFull = O.GetClims(O.T.VocResp, [95, 5]);
            ClimsSil = O.GetClims(
            for i = 1:4
                O.plotMaps('Full', O.T.VocResp.Pretime(:, :, i), 'Change norm (%)', Clims);
                O.plotMaps('Sil', O.T.VocResp.Sil(:, :, i), 
            end
        end 

        function plotMaps(O, GUIDat, MapData, ylab, Clims, Color, AxNum)
            cAH = O.GUI.AH(AxNum);
            hold(cAH, 'on');
            O.GUI.(GUIDat) = imagesc(cAH, O.X, O.Y,MapData); %[cAH, AHB, cBar] = HF_imagescCraniotomy(Fig,cAH,cAH,O.X,O.Y,Adaptmap(:, :, O.P.Pl(i)),Adaptmap(:, :, O.P.Pl(i)),R.Frames.CraniotomyMask, 'AlphaF', 1, 'AlphaB', 0); 
            O.GUI.(GUIDat).AlphaData = O.CraniotomyMask.*1;
            set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
            set(cAH,'ButtonDownFcn',{@O.selectROI});
            colormap(cAH, 'jet')
            caxis(cAH, Clims);
            set(O.GUI.(GUIDat),'HitTest','off');
            c1 = colorbar(cAH);
            ylabel(c1, ylab);
            %ylabel(cAH, 'Mediolateral (mm)'); xlabel(cAH, 'Anteroposterior (mm)');
            title(cAH, O.CorrVar, 'Color', Color);
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



        function [P1, frequencies] = getP1(O, Signal, Fs)
        WindowedSignal = Signal .* hann(length(Signal));
        fftImage = fft(WindowedSignal);
        N = length(WindowedSignal(:, 1));
        P2 = abs(fftImage/N);
        P1 = P2(1:N/2+1, :);
        P1(2:end-1, :) = 2*P1(2:end-1, :);
        TotalP = sum(P1);
        P1 = P1./TotalP;
        frequencies = linspace(0, Fs/2, N/2+1);

        end

        function Clims = GetClims(O, InputDat, Perc)
        P95=prctile(InputDat(:, :, :),Perc(1),'all');
        P05=prctile(InputDat(:, :, :),Perc(2),'all');
        Clims = [P05, P95];
        end

        function selectROI(O,H,E)


        CP =  get(H,'CurrentPoint');
        O.P.ROI(1:2) = CP(1,1:2);
        delete(O.GUI.ROICoords);
        O.GUI.ROICoords = uicontrol('Style', 'text', 'String', ['ROI Coordinates X: ' num2str(O.P.ROI(1)) ', Y: ' num2str(O.P.ROI(2))], 'Position', [50, 235, 400, 20]);
        SelType = get(O.P.FIG,'SelectionType');

        O.ROIMask = O.findROIMask;
        set(O.P.FIG,'Name','Computing...'); drawnow;
        O.updateROIAverages;
        set(O.P.FIG,'Name', O.FigureName)
        for i =1:6
            delete(O.GUI.Circle.left(i));
        end

        for i = 1:6 
            O.GUI.Circle.left(i) = O.redrawCircle(i, 'm'); 
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

        function CorrVar = GetCorrVar(O, Corrs, Vars)
        VarNum = length(Corrs)*length(Vars);
        CorrVar = {};
        for i = 1:length(Corrs)
            for j = 1:length(Vars)
                if Corrs(i) == 0.8
                    combination = ['HighCFC ', 'Var', num2str(Vars(j))];
                else
                    combination = ['LowCFC ', 'Var', num2str(Vars(j))];
                end% Add the combination to the cell array
                CorrVar = [CorrVar, combination];
            end
        end
        end

        function updateROIAverages(O)
        O.ROIAll = O.TrialAvg.*O.ROIMask; %
        O.ROIAll(O.ROIAll==0) = NaN; % Replace 0 entries from Mask (which cannot be set to NaN, as they are logical
        O.ROIAvgImage  = squeeze(nanmean(nanmean(O.ROIAll,2),1)); % Average over Image Dimensions   
        ROIAverageYLims  = [min(100*O.ROIAvgImage(1.8*O.P.FR:1:5*O.P.FR, :), [], 'all')*1.1,...
                          max(100*O.ROIAvgImage(1.8*O.P.FR:1:5*O.P.FR, :), [], 'all')*1.1];
        Xshade = 0.2:0.1:O.FFTendpoint;
        Yshade = 100*ones(size(Xshade));
        [P1, frequencies] = O.getP1(O.ROIAvgImage(2.21*O.P.FR:1:round((O.FFTendpoint+2)*O.P.FR), :), O.P.FR);
        [PresignalP1, PresignalFreqs] = O.getP1(O.ROIAvgImage(2:1:1.99*O.P.FR, :), O.P.FR);
        axes(O.GUI.AH(7));
        delete(O.GUI.FFTArea);
        O.GUI.FFTArea = area(Xshade,Yshade, -100,'FaceColor',[0.9,0.9,1],'EdgeColor','None','HitTest','Off', 'HandleVisibility', 'Off');
        for i = 1:O.DataDims(4)
            PlotVis = O.GUI.ROIAverage(i).Visible;
            delete(O.GUI.ROIAverage(i));
            O.GUI.ROIAverage(i) = plot(O.Time-2, 100*O.ROIAvgImage(:, i), 'Color', O.line_colors(i, :), 'LineStyle', O.line_styles(i), 'LineWidth', 1.5, 'Visible', PlotVis);
        end
        O.GUI.AH(7).YLim=[ROIAverageYLims(1),ROIAverageYLims(2)];
        axes(O.GUI.AH(8));
        for i = 1:O.DataDims(4)
            PlotVis = O.GUI.ROIAverage(i).Visible;
            delete(O.GUI.ROIFFTs(i));
            O.GUI.ROIFFTs(i) = plot(frequencies, P1(:, i), 'Color', O.line_colors(i, :), 'Linestyle', O.line_styles(i), 'Linewidth', 1.5, 'Visible', PlotVis);
        end
        lgd = legend(O.CorrVar, 'Location', 'NorthEast');
        lgd.FontSize = 6;
        %axes(O.GUI.AH(8))
        %delete(O.GUI.ROIFFT4copy1);
        %O.GUI.ROIFFT4copy1 = copyobj(O.GUI.ROIFFTs(4), O.GUI.AH(8));        
        %axes(O.GUI.AH(7));
        %delete(O.GUI.ROIPreFFT);
        %delete(O.GUI.ROIFFT4copy2);
        %O.GUI.ROIFFT4copy2 = copyobj(O.GUI.ROIFFTs(4), O.GUI.AH(7));
        %O.GUI.ROIPreFFT = plot(PresignalFreqs, PresignalP1(:, O.P.Pl(4)), 'Color', 'k', 'Linewidth', 1.5);
        end

        function SelectFFTendpoint(O,H,E)
        CP =  get(H,'CurrentPoint');
        cTime = round(CP(1,1), 2);
        NumStr = sprintf('%.2f', cTime);
        SecDecDig = str2double(NumStr(4));
        if mod(SecDecDig, 2) ~= 0
        cTime = cTime + 0.01;
        end
        O.FFTendpoint = O.Time(dsearchn(O.Time,cTime));
        O.updateROIAverages;
        end

        function MapsdropdownCallback(O, hObject, ~)
        % Get the selected option
        selectedOption = hObject.String{hObject.Value};
        disp(['Selected option: ' selectedOption]);
        if strcmp(selectedOption, 'Sustained Ratio')

            O.SustainedRatioMap;
        elseif strcmp(selectedOption, 'Sustained Level')
            O.SustainedLevelMap;
        elseif strcmp(selectedOption, 'Derivative Sustained Level')
            O.DiffSustainedRatioMap;
        elseif strcmp(selectedOption, 'Mean Derivative MovMedian')
            O.DerMeanMap;
        elseif strcmp(selectedOption, 'Maximum Texture Response')
            O.MaxTexResponse;
        elseif strcmp(selectedOption, 'Time of Minimum')
            O.DecayTime;
        elseif strcmp(selectedOption, 'Exponential Time Constant')
            O.FitDecayMap;
        elseif strcmp(selectedOption, 'Maximum Frequency')
            O.MaxFreq;
        elseif strcmp(selectedOption, ['Size ', num2str(O.P.Freq), ' Hz peak'])
            O.SpecFreq;
        end
        for i =1:O.DataDims(4)
            delete(O.GUI.Circle.left(i));
        end

        for i = 1:O.DataDims(4)
            O.GUI.Circle.left(i) = O.redrawCircle(i, 'm'); 
        end
        end

        function VarsdropdownCallback(O, hObject, ~)
        selectedOption = hObject.String{hObject.Value};
        disp(['Selected option: ' selectedOption]);
        if strcmp(selectedOption, 'Var 0.02')
            O.P.Pl = [1, 3, 4, 6];
            O.SustainedRatioMap;
            O.updateROIAverages;
        elseif strcmp(selectedOption, 'Var 0.2')
            O.P.Pl = [2, 3, 5, 6];
            O.SustainedRatioMap;
            O.updateROIAverages;
        end
        for i =1:6
            delete(O.GUI.Circle.left(i));
        end

        for i = 1:6 
            O.GUI.Circle.left(i) = O.redrawCircle(i, 'm'); 
        end
        end

        function togglePlotVisibility(O, ~, ~, PlotIndex)
        if strcmp(O.GUI.ROIAverage(PlotIndex).Visible, 'on')
            set(O.GUI.ROIAverage(PlotIndex), 'Visible', 'off');
            set(O.GUI.ROIFFTs(PlotIndex), 'Visible', 'off');
        else
            set(O.GUI.ROIAverage(PlotIndex), 'Visible', 'on');
            set(O.GUI.ROIFFTs(PlotIndex), 'Visible', 'on');
        end
        end

        function ROIMask = findROIMask(O)
        [Y, X] = meshgrid(O.Y,O.X);
        ROIMask = sqrt((X - O.P.ROI(1) ).^2 + (Y - O.P.ROI(2) ).^2) <= O.P.ROI(3);
        end

  end
end