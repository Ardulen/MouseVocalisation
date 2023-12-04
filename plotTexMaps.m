function plotTexMaps(ParFrames, Corrs, Vars, R, pl, minpretime, varargin)

    P = parsePairs(varargin);
    checkField(P,'ROI',[1.14, 1.77, 0.2]); % [centerX centerY radius] in mm
    checkField(P,'FIG',1);
    checkField(P,'Lens','Nikon4X') % Usually set automatically by the Setup
    checkField(P,'Source','VideoCalcium'); % Choose the Source of the Data
    checkField(P,'FigSavePath',[]);
    checkField(P,'Trials',[]); 
    checkField(P, 'Animal');
    checkField(P, 'Recording');
    checkField(P, 'FR', 100);
    checkField(P, 'MaxFrame', 0);
    
    MP = get(0,'MonitorPositions');
    NY = MP(1,end); HPixels = 540;
    FigureName=[P.Animal,' R',num2str(P.Recording),' Adaptation and Decay Maps'];
    figure(P.FIG); clf; set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1350,HPixels]);
    
    line_colors = [0, 0, 1; 0, 0, 1; 1, 0, 0; 1, 0, 0];
    line_styles = ['--', "-", '--', "-"];
    line_widths = [1.5, 1, 1.5, 1];
    CM = HF_colormap({[0,0,1],[1,1,1],[1,0,0]});
    
    AH(1)=axes('position',[0.02,0.72,0.20,0.20]);
    AH(2)=axes('position',[0.02,0.40,0.20,0.20]);
    AH(3)=axes('position',[0.23,0.72,0.20,0.20]);
    AH(4)=axes('position',[0.23,0.40,0.20,0.20]);
    AH(5)=axes('position',[0.44,0.72,0.20,0.20]);
    AH(6)=axes('position',[0.44,0.40,0.20,0.20]); 
    AH(7)=axes('position',[0.65,0.72,0.20,0.20]);
    AH(8)=axes('position',[0.65,0.40,0.20,0.20]);
    AH(9)=axes('position',[0.06,0.07,0.4,0.20]);
    AH(10)=axes('position',[0.5,0.07,0.4,0.20]);
    annotation('textbox','String',FigureName,'Position',[0.3,0.96,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);
    %% pixels to mm transformation  
    [X, Y, PixelPerMM] = C_pixelToMM(P,R,R.Frames);
    X = X/1;
    Y = Y/1;
    ROIs = [1.1,1.77,0.2;2.13,2.18,0.2];
    
    CorrVar = {};
    for i = 1:length(Corrs)
        for j = 1:length(Vars)
        % Concatenate elements from both vectors into a string
            combination = ['Corr', num2str(Corrs(i)), ' Var', num2str(Vars(j))];
        % Add the combination to the cell array
            CorrVar = [CorrVar, combination];
        end
    end
    
    function ROIMask = findROIMask(Y, X, ROI)
      [YGrid, XGrid] = meshgrid(Y,X);
      ROIMask = sqrt((XGrid - ROI(1) ).^2 + (YGrid - ROI(2) ).^2) <= ROI(3);
      ROIMask = ROIMask';
    end

    function redrawCircle(ROI, color)
      Steps = linspace(0,2*pi,100);
      CircleC = ROI(3) * exp(Steps*sqrt(-1));
      CircleX = real(CircleC) + ROI(1);
      CircleY = imag(CircleC) + ROI(2);
      plot(CircleX,CircleY,'Color',color,'LineWidth',1.5);
    end
    
    
    %% plot Adaptation map
    TrialAvg = squeeze(nanmean(ParFrames, 4));
    TexResp = TrialAvg(:, :, 200:1:250, :);
    MaxTexResp = squeeze(max(TexResp, [], 3));
    MedTexResp = squeeze(median(TrialAvg(:, :, 300:1:500, :), 3));
    Adaptmap = MedTexResp./MaxTexResp;
    for i = 1:4
        axes(AH(i));
        hold on;
        imagesc(X, Y,Adaptmap(:, :, pl(i)));
        P95=prctile(Adaptmap(:, :, pl(i)),95,'all');%caxis range
        P05=prctile(Adaptmap(:, :, pl(i)),5,'all');
        set(gca,'YDir','reverse','DataAspectRatio',[1,1,1])
        caxis([P05, P95]);
        redrawCircle(ROIs(1, :), 'm');
        redrawCircle(ROIs(2, :), [0.2, 1, 0.2]);
        colormap(jet)
        colorbar;
        ylabel(colorbar, 'Sustained ratio');
        ylabel('Mediolateral (mm)'); xlabel('Anteroposterior (mm)');
        title(CorrVar(pl(i)));
        ylim([min(Y), max(Y)]);
        xlim([min(X), max(X)]);
        hold off;
    end
    
    %% plot Decay time map
    P1t=prctile(TrialAvg(:, :, 220:500, :),3, 3);
    im = TrialAvg(:, :, 220:500, :) <= P1t(:, :, 1, :);
    dtime = zeros(length(im(:, 1, 1, 1)), length(im(1, :, 1, 1)), 1, length(im(1, 1, 1, :)));
    for i = 1:length(im(:, 1, 1, 1))
        for j = 1:length(im(1, :, 1, 1))
            for k = 1:length(im(1, 1, 1, :))
                TimeIndex = find(im(i, j, :, k) == 1);
                dtime(i, j, 1, k) = TimeIndex(1);
            end
        end
    end
    dtime = squeeze(dtime);
    DecayMap = 0.2+dtime./P.FR;
    for i = 5:8
        axes(AH(i));
        hold on;
        imagesc(X, Y,DecayMap(:, :, pl(i-4)));
        P95=prctile(DecayMap(:, :, pl(i-4)),95,'all');%caxis range
        P05=prctile(DecayMap(:, :, pl(i-4)),5,'all');
        set(gca,'YDir','reverse','DataAspectRatio',[1,1,1])
        caxis([P05, P95]);
        redrawCircle(ROIs(1, :), 'm');
        redrawCircle(ROIs(2, :), [0.2, 1, 0.2]);
        colormap(jet)
        colorbar;
        ylabel(colorbar, 'sec');
        ylabel('Mediolateral (mm)'); xlabel('Anteroposterior (mm)');
        title(CorrVar(pl(i-4)));
        ylim([min(Y), max(Y)]);
        xlim([min(X), max(X)]);
        hold off;
    end
    
    %% plot ROI Traces

    for i = 9:10
        axes(AH(i));
        Time = R.Frames.TimeAvg;
        ROIMask = findROIMask(X, Y, ROIs(i-8, :));
        ROIAll = TrialAvg.*ROIMask;
        ROIAll(ROIAll==0) = NaN;
        AvgImage = squeeze(nanmean(nanmean(ROIAll,2),1));
        hold on;
        for j =1:length(pl)
            plot(Time, 100*AvgImage(:, pl(j)), 'Color', line_colors(j, :), 'Linewidth', line_widths(j));
        end
        plot([2, 2],[-1000,1000],'-','Color','k');
        hold off;
        lgd = legend(CorrVar(pl), 'Location', [0.35, 0.2, 0.08, 0.08]);
        xlim([1.8, minpretime+2]);
        xlabel('time (s)');
        ylabel('Change norm. (%)');
        if i == 9
            title('Averages over left ROI');
            ylim([-8, 6]);
            set(get(gca, 'title'), 'Color', 'm');
        else
            title('Averages over right ROI');
            ylim([-8, 6]);
            set(get(gca, 'title'), 'Color', [0.2, 1, 0.2]);
        end
        lgd.FontSize = 6;
    end
    
end