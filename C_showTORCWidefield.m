classdef C_showTORCWidefield < handle
 
  properties (SetAccess = public)
    ParFrames = [];
    NoiseWaveform = [];
    Frames = [];
    Stimulus = [];
    CraniotomyMask = [];
    FFTendpoint = [];
    GUI = [];
    X = [];
    Y = [];
    PixelPerMM = [];
    P = [];
    Info = [];
    Time = [];
    AdaptMap = [];
    SustainedLvlMap = [];
    DiffMeanMap = [];
    DecayMap = [];
    FitDecMap = [];
    MaxTexResp = [];
    MaxFreqMap = [];
    SpecFreqMap = [];
    ROIMask = [];
    TrialAvg
    ROIAll = [];
    ROIAvgImage  = [];
    ROIAvgImageTrial = [];
    ROISEMImageTrial  = [];
    General = [];
    line_colors = [];
    line_styles = [];
    line_widths = [];
    CorrVar = [];
    FigureName = {};
    minpretime = [];
    DiffSustainLevel = [];
    DataDims = [];
  end
  
  
  methods
    
    function O = C_showTORCWidefield(TrialAvg, R, NoiseWaveform, T,varargin)
      
      P = parsePairs(varargin);
      checkField(P,'CLim','Auto')
      checkField(P,'ROI',[1.14, 1.77, 0.2]); % [centerX centerY radius] in mm
      checkField(P,'Threshold',0.0028)
      checkField(P,'FIG',1);
      checkField(P,'Lens','Nikon4X') % Usually set automatically by the Setup
      checkField(P,'FOV2PAngle',38); % Set the  Angle at which the 2P Field-Of-View is rotated
      checkField(P,'FOV2PSize',[0.8,0.8]); % Set the Size of the 2P Field-Of-View
      checkField(P,'Source','VideoCalcium'); % Choose the Source of the Data
      checkField(P, 'FR', 100);
      checkField(P,'Trials',[]); % Choose the Source of the Data
      checkField(P, 'Pl', [1, 3, 4, 6]); %dicides which parameters are shown
      checkField(P, 'Corrs', [0, 0.8]);
      checkField(P, 'Vars', [0.02, 0.2, 0.4]);
      checkField(P, 'Pretimes', [3, 5]);
      checkField(P, 'Scale', 2);
      checkField(P, 'Freq', 6);
      checkField(P, 'FreqLim', 2);
      checkField(P, 'CranMask', 1);
      
      NTrials = size(R.Frames.AvgTime,4);
      
      O.General = R.General;
      O.P = P;
      O.minpretime = O.P.Pretimes(1);
      O.NoiseWaveform = NoiseWaveform;
      if P.CranMask
          O.CraniotomyMask = R.Frames.CraniotomyMask;
      else    
        O.CraniotomyMask = O.createCranMask;
      end
      %% Set figure
      MP = get(0,'MonitorPositions');
      NY = MP(1,end); HPixels = 540;
      O.FigureName=[O.P.Animal,' R',num2str(O.P.Recording),' Texture Response'];
      Fig = figure(O.P.FIG); clf; set(O.P.FIG,'name', O.FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1350,HPixels]);
    
      O.line_colors = [0.5, 0.5, 1; 0.4, 0.5, 0.4; 1, 0.5, 0.5; 0, 0, 1; 0, 0.5, 0; 1, 0, 0];
      O.line_styles = [':', ":", ':', "-", "-", "-"];
      O.line_widths = [1.5, 1.5, 1.5, 1.5];
      CM = HF_colormap({[0,0,1],[1,1,1],[1,0,0]});
    
    O.GUI.AH(1)=axes('position',[0.02,0.60,0.20,0.25]);
    O.GUI.AH(4)=axes('position',[0.02,0.10,0.20,0.25]);
    O.GUI.AH(2)=axes('position',[0.23,0.60,0.20,0.25]);
    O.GUI.AH(5)=axes('position',[0.23,0.10,0.20,0.25]);
    O.GUI.AH(3)=axes('position',[0.44,0.60,0.20,0.25]);
    O.GUI.AH(6)=axes('position',[0.44,0.10,0.20,0.25]); 
    O.GUI.AH(7)=axes('position',[0.69,0.60,0.20,0.30]);
    O.GUI.AH(8)=axes('position',[0.69,0.10,0.20,0.30]);
    annotation('textbox','String', O.FigureName,'Position',[0.3,0.96,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);

      %% pixels to mm transformation  
      [X, Y, PixelPerMM] = C_pixelToMM(P,R,R.Frames);
      O.PixelPerMM = PixelPerMM;
      O.X = X; O.Y = Y;
    
     %% Time Points
      O.Time=R.Frames.TimeAvg;
      O.FFTendpoint = O.P.Pretimes(end);
      %% legend
      O.CorrVar = O.GetCorrVar(O.P.Corrs, O.P.Vars);
    
    %% popup menus
    
    O.GUI.Mapspopup = uicontrol('Style', 'popup', 'Position', [150, 500, 250, 30]);
    O.GUI.Mapspopup.String = {'Sustained Ratio', 'Sustained Level', 'Derivative Sustained Level', 'Mean Derivative MovMedian', 'Maximum Texture Response', 'Time of Minimum', 'Exponential Time Constant', 'Maximum Frequency', ['Size ', num2str(O.P.Freq), ' Hz peak']};
    O.GUI.Mapspopup.Callback = @O.MapsdropdownCallback;
    %O.GUI.Varspopup = uicontrol('Style', 'popup', 'Position', [10, 500, 120, 30]);
    %O.GUI.Varspopup.String = {'Var 0.02', 'Var 0.2'};
    %O.GUI.Varspopup.Callback = @O.VarsdropdownCallback;
    %% display current ROI coordinates
    O.GUI.ROICoords = uicontrol('Style', 'text', 'String', ['ROI Coordinates X: ' num2str(O.P.ROI(1)) ', Y: ' num2str(O.P.ROI(2))], 'Position', [50, 235, 400, 20]);
    
    %% visibility buttons
    O.GUI.buttonHandles = gobjects(6, 1);
    O.GUI.buttonLabels = {'<html><font color="blue" style="background-color:blue;">R</font><font color="white" style="background-color:white;">R</font><font color="blue" style="background-color:blue;">R</font></html>', ...
                '<html><font color="green" style="background-color:green;">R</font><font color="white" style="background-color:white;">R</font><font color="green" style="background-color:green;">R</font></html>', ...
                '<html><font color="red" style="background-color:red;">R</font><font color="white" style="background-color:white;">R</font><font color="red" style="background-color:red;">R</font></html>', ...
                '<html><font color="blue" style="background-color:blue;">Red</font></html>', ...
                '<html><font color="green" style="background-color:green;">Red</font></html>', ...
                '<html><font color="red" style="background-color:red;">Red</font></html>'};
    for i = 1:6
        O.GUI.buttonHandles(i) = uicontrol('Style', 'togglebutton', ...
                                'String', O.GUI.buttonLabels{i}, ...
                                'Position', [920 + (i-1) * 50, 242, 30, 30]);
        O.GUI.buttonHandles(i).Callback = {@O.togglePlotVisibility, i};
    end
    
    %% plot Sustained Ratio map

    O.TrialAvg = TrialAvg;
    TexResp = O.TrialAvg(:, :, 2*O.P.FR:1:2.5*O.P.FR, :);
    MaxTexResp = squeeze(max(TexResp, [], 3));
    MedTexResp = squeeze(median(O.TrialAvg(:, :, 4*O.P.FR:1:5*O.P.FR, :), 3));
    O.AdaptMap = MedTexResp./MaxTexResp;
    O.SustainedLvlMap = 100*MedTexResp;
    
    
    O.FitDecMap = T.FitDecMap;
    O.DecayMap = T.DecayMap;
      
      %% plot sustained level via diff
      
      MovingMedian = movmedian(O.TrialAvg(:, :, 2.21*O.P.FR:1:5*O.P.FR, :), 100, 3);
      O.DataDims = size(O.TrialAvg(:, :, 2.21*O.P.FR:1:5*O.P.FR, :));

      Diffs = diff(MovingMedian, 1, 3);
      Diffs = cat(3, Diffs, zeros(size(Diffs, 1), size(Diffs, 2), 1, size(Diffs, 4))); %zero padding to ensure equal lengths
      Diffmean = mean(Diffs(:, :, 180:280, :), 3);
      O.DiffMeanMap = O.P.FR*100*Diffmean;
      DiffMask = (Diffmean >= -4e-05) & (Diffmean <= 4e-05);
      SustainPixels = O.TrialAvg(:, :, 4.01*O.P.FR:1:5*O.P.FR, :).*DiffMask;
      SustainPixels(SustainPixels == 0) = NaN;
      MedSustain = squeeze(nanmedian(SustainPixels, 3));
      O.DiffSustainLevel = 100*MedSustain;
      
      %% plot Max Texture Response
      O.MaxTexResp = 100*MaxTexResp;
      
       
    
        %% plot ROI Traces

        cAH = O.GUI.AH(7);
        O.ROIAvgImage = zeros(length(O.Time), 6);
        Xshade = 0.2:0.1:O.FFTendpoint;
        Yshade = 100*ones(size(Xshade));
        O.GUI.FFTArea = area(cAH, Xshade,Yshade, -100,'FaceColor',[0.9,0.9,1],'EdgeColor','None','HitTest','Off', 'HandleVisibility', 'Off');
        set(O.GUI.FFTArea, 'HitTest', 'off');
        hold(cAH, 'on');
        for j =1:O.DataDims(4)
            O.GUI.ROIAverage(j) = plot(cAH, O.Time, 100*O.ROIAvgImage(:, j), 'Color', O.line_colors(j, :), 'Linewidth', 1.5, 'LineStyle', O.line_styles(j));
        end
        plot(cAH, [0, 0],[-1000,1000],'-','Color','k', 'HandleVisibility', 'Off');
        xlim(cAH, [-1, O.P.Pretimes(1)]);
        plot(cAH, [-3, 10],[0,0],'-','Color','k', 'HandleVisibility', 'Off');
        set(cAH,'ButtonDownFcn',{@O.SelectFFTendpoint});
        set(O.GUI.ROIAverage,'HitTest','off');
        xlabel(cAH, 'time (s)');
        ylabel(cAH, 'Change norm. (%)');
        title(cAH, 'Averages over ROI');
        
       %% plot fft
        cAH = O.GUI.AH(8);
        [P1, frequencies] = O.getP1(O.ROIAvgImage(2.21*O.P.FR:1:(2+O.minpretime)*O.P.FR, :), O.P.FR);
        hold(cAH, 'on');
        for i =1:O.DataDims(4)
            O.GUI.ROIFFTs(i) = plot(cAH, frequencies, P1(:, i), 'Color', O.line_colors(i, :), 'Linestyle', O.line_styles(i), 'Linewidth', 1.5);
        end
        xlim(cAH, [0, 20]);
        xlabel(cAH, 'f (Hz)');
        ylabel(cAH, 'Relative P');
        title(cAH, 'FFTs over shaded area');
        lgd = legend(cAH, O.CorrVar, 'Location', 'NorthEast');
        lgd.FontSize = 6;
    
    %% plot FFT sound envelope vs FFT signal
    
    %cAH = O.GUI.AH(8);
    %hold(cAH, 'on');
    %[audio_filts, audio_cutoffs_Hz] = make_constQ_cos_filters(length(O.NoiseWaveform), 250000, 30, 2000, 64000, 8);
    %subbands = generate_subbands(O.NoiseWaveform, audio_filts);
    %subband_envs = abs(hilbert(subbands));
    %[SubbandP1, SubbandFreqs] = O.getP1(subband_envs, 250000);
    %SubbandP1Avg = squeeze(mean(SubbandP1, 2));
    % Define the threshold for peak detection
    %threshold = 0.002;
    % Identify peaks above the threshold
    %peaks = SubbandP1Avg > threshold;
    % Set values below the threshold to zero
    %SubbandP1Avg(~peaks) = 0;
    %O.GUI.ROIFFT4copy1 = copyobj(O.GUI.ROIFFTs(4), cAH);
    %ylabel(cAH, 'Relative P');
    %ylim(cAH, [0, 0.06]);
    %O.GUI.ROIStimFFt = plot(cAH, SubbandFreqs, SubbandP1Avg(:, 1), 'Color', 'k');
    %xlim(cAH, [0, 50]);
    %xlabel(cAH, 'f (Hz)');
    %title(cAH, 'Stimulus FFT vs Response FFT')
    
    %% Plot preTex FFT vs PostTex FFT
    
    %%cAH = O.GUI.AH(7);
    
    %[PresignalP1, PresignalFreqs] = O.getP1(O.ROIAvgImage(2:1:1.99*O.P.FR, :), O.P.FR);
    %hold(cAH, 'on');
    %O.GUI.ROIPreFFT = plot(cAH, PresignalFreqs, PresignalP1(:, O.P.Pl(4)), 'Color', 'k', 'Linewidth', 1.5);
    %O.GUI.ROIFFTs(4) = plot(cAH, frequencies, P1(:, O.P.Pl(4)), 'Color', O.line_colors(4, :), 'Linestyle', O.line_styles(4), 'Linewidth', 1.5);
    %O.GUI.ROIFFT4copy2 = copyobj(O.GUI.ROIFFTs(4), cAH);
    %ylabel(cAH, 'Relative P');
    %title(cAH, [O.CorrVar(O.P.Pl(4)), ' pre and post Texture FFT'])
    %xlim(cAH, [0, 50]);
    %xlabel(cAH, 'f (Hz)');
    O.SustainedRatioMap;  
    for i =1:6
        O.GUI.Circle.left(i) = O.redrawCircle(i, 'm');
    end
    O.ROIMask = O.findROIMask;
    O.updateROIAverages;

  end
    
    function SustainedRatioMap(O)
        Clims = O.GetClims(O.AdaptMap, [95, 5]);
        O.plotMaps('Adapt', O.AdaptMap, 'Sustained Ratio', Clims);
  
    end 
    
    function SustainedLevelMap(O)
        Clims = O.GetClims(O.SustainedLvlMap, [95, 5]);
        O.plotMaps('Adapt', O.SustainedLvlMap, 'Change norm. (%)', Clims);
  
    end 
    
    function DiffSustainedRatioMap(O)
        Clims = O.GetClims(O.DiffSustainLevel, [95, 5]);
        O.plotMaps('DiffAdapt', O.DiffSustainLevel, 'Change norm. (%)', Clims);
    end 
    
    function DerMeanMap(O)
        Clims = O.GetClims(O.DiffMeanMap, [95, 5]);
        O.plotMaps('DiffAdapt', O.DiffMeanMap, 'Change (%) per sec', Clims);
    end
    
    function MaxTexResponse(O)
        Clims = [min(O.MaxTexResp, [], 'all')*1.1, max(O.MaxTexResp, [], 'all')*1.1];
        O.plotMaps('MaxResponse', O.MaxTexResp, 'Change norm. (%)', Clims);
    end
    
    function DecayTime(O)
        Clims = O.GetClims(O.DecayMap, [90, 5]);
        O.plotMaps('Decay', O.DecayMap, 'time (sec)', Clims);
    end
    
    function FitDecayMap(O)
        Clims = O.GetClims(O.FitDecMap, [95, 1]);
        O.plotMaps('Decay', O.FitDecMap, 'Tau', Clims);

    end
    
    function MaxFreq(O)
        O.RecalcFreqs;
        Clims = [1, 10];
        O.plotMaps('MaxFreq', O.MaxFreqMap, 'Maximum Frequnecy (Hz)', Clims);
    end 
    
    function SpecFreq(O)
        O.RecalcFreqs;
        Clims = [min(O.SpecFreqMap, [], 'all'), max(O.SpecFreqMap, [], 'all')];
        O.plotMaps('SpecFreq', O.SpecFreqMap, ['Relative Power in ' num2str(O.P.Freq), 'Hz'], Clims);
    end 
    
    
    function RecalcFreqs(O)
         N = round(((O.FFTendpoint)*O.P.FR-0.2*O.P.FR)/2+1);
         WholeP1 = zeros(size(O.TrialAvg, 1), size(O.TrialAvg, 2), N, size(O.TrialAvg, 4));
         for i = 1:length(O.TrialAvg(:, 1, 1, 1))
            for j = 1:length(O.TrialAvg(1, :, 1, 1))
                Signal = squeeze(O.TrialAvg(i, j, 2.21*O.P.FR:1:round((O.FFTendpoint+2)*O.P.FR), :));
                [WholeP1(i, j, :, :), frequency] = O.getP1(Signal, O.P.FR);
            end
         end
         FreqRatio = frequency(2);
         [~, FreqLimIndex] = min(abs(frequency - O.P.FreqLim));
         StdFreqs = std(WholeP1, 0, 3);
         WholeP1(:, :, 1:FreqLimIndex, :) = 0;
         [MaxFrequency, Indices] = max(WholeP1, [], 3);
         FreqMask = MaxFrequency > 0.5*StdFreqs;
         Indices = Indices.*FreqMask;
         Indices(Indices==0) = NaN;
         Indices = squeeze(Indices);
         O.MaxFreqMap = (Indices-1)*FreqRatio;
         [~, FreqIndex] = min(abs(frequency - O.P.Freq));
         O.SpecFreqMap = WholeP1(:, :, FreqIndex, :);
    end
    
    function plotMaps(O, GUIDat, MapData, ylab, Clims)
        for i = 1:O.DataDims(4)
            cAH = O.GUI.AH(i);
            hold(cAH, 'on');
            O.GUI.(GUIDat)(i) = imagesc(cAH, O.X, O.Y,MapData(:, :, i)); %[cAH, AHB, cBar] = HF_imagescCraniotomy(Fig,cAH,cAH,O.X,O.Y,Adaptmap(:, :, O.P.Pl(i)),Adaptmap(:, :, O.P.Pl(i)),R.Frames.CraniotomyMask, 'AlphaF', 1, 'AlphaB', 0); 
            O.GUI.(GUIDat)(i).AlphaData = O.CraniotomyMask.*1;
            set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
            set(cAH,'ButtonDownFcn',{@O.selectROI});
            colormap(cAH, 'jet')
            caxis(cAH, Clims);
            set(O.GUI.(GUIDat)(i),'HitTest','off');
            c1 = colorbar(cAH);
            ylabel(c1, ylab);
            ylabel(cAH, 'Mediolateral (mm)'); xlabel(cAH, 'Anteroposterior (mm)');
            title(cAH, O.CorrVar(i), 'Color', O.line_colors(i, :));
            ylim(cAH, [min(O.Y), max(O.Y)]);
            xlim(cAH, [min(O.X), max(O.X)]);
        end
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