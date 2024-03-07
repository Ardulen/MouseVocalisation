function CalcLinFitMaps(R, Data, varargin)
    P = parsePairs(varargin);
    checkField(P,'FIG',4);
    checkField(P,'Source','VideoCalcium'); % Choose the Source of the Data
    checkField(P, 'Animal');
    checkField(P, 'Recording');
    checkField(P, 'Offset', [0.20, 0.25])
    
    %% pixels to mm transformation  
    [X, Y, PixelPerMM] = C_pixelToMM(P,R,R.Frames);
    O.PixelPerMM = PixelPerMM;
    O.X = X; O.Y = Y;
    CM = HF_colormap({[0,0,1],[1,1,1],[1,0,0]});
    %% Set Cortex Area map
    [~, ~, ~, ~, TuningR] = C_showCortexRegionsTuningWF('Animal', P.Animal, 'FIG', 0);
    Xoffset = P.Offset(1);
    Yoffset = P.Offset(2);
    Toffset = 0.25;
    ImageSize = size(R.Frames.AverageRaw);
    
    
    MP = get(0,'MonitorPositions');
    NY = MP(1,end); HPixels = 540;
    FigureName=[P.Animal,' R',num2str(P.Recording),' Slope across pretimes for different VocFreqs'];
    figure(P.FIG); clf; set(P.FIG,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1350,HPixels]);
    annotation('textbox','String', FigureName,'Position',[0.12,0.96,0.7,0.05],'Horiz','l','FontSize',12,'FontW','b','EdgeColor',[1,1,1]);

    
    
    AH(1)=axes('position',[-0.04,0.62,0.30,0.30]);
    AH(2)=axes('position',[0.21,0.62,0.30,0.30]);
    AH(3)=axes('position',[0.46,0.62,0.30,0.30]);
    AH(4)=axes('position',[0.71,0.62,0.30,0.30]);
    AH(5)=axes('position',[-0.04,0.12,0.30,0.30]);
    AH(6)=axes('position',[0.21,0.12,0.30,0.30]);
    AH(7)=axes('position',[0.46,0.12,0.30,0.30]);
    AH(8)=axes('position',[0.71,0.12,0.30,0.30]);
    AH(9)=axes('position',[-0.04,0.12,0.30,0.30], 'Visible', 'off');
    AH(10)=axes('position',[0.21,0.12,0.30,0.30], 'Visible', 'off'); 
    AH(11)=axes('position',[0.46,0.12,0.30,0.30], 'Visible', 'off');
    AH(12)=axes('position',[0.71,0.12,0.30,0.30], 'Visible', 'off');
    
    SlopeMaps = zeros([ImageSize, size(Data, 3)+1]);
    
    for k = 1:size(Data, 3)
        for j = 1:ImageSize(1)
            for i = 1:ImageSize(2)
                Yvalues = squeeze(Data(j, i, k, :));
                p = polyfit(1:3, Yvalues', 1);
                SlopeMaps(j, i, k) = p(1);
            end
        end
    end
    
    if strcmp(P.Animal, 'mouse193')
        xoffset = 2;
        yoffset = -1;
        Majoroffset = 4;
        Minoroffset = 4;
    else
        xoffset = 4;
        yoffset = -1;
        Majoroffset = 5;
        Minoroffset = 4;
    end    
    % Parameters for the ellipse
    centerX = ImageSize(1)/2+xoffset;  % X-coordinate of the center
    centerY = ImageSize(2)/2+yoffset;  % Y-coordinate of the center
    semiMajorAxis = ImageSize(1)/3+Majoroffset;  % Semi-major axis length
    semiMinorAxis = ImageSize(2)/3+Minoroffset;  % Semi-minor axis length

    % Size of the matrix
    matrixSize = [ImageSize(1), ImageSize(2)];

    % Create a grid of coordinates
    [X, Y] = meshgrid(1:matrixSize(2), 1:matrixSize(1));

    % Create the elliptical mask
    CranMask = ((X - centerX) / semiMajorAxis).^2 + ((Y - centerY) / semiMinorAxis).^2 <= 1;

    
    
    Title = {'4 kHz', '8 kHz', '32 kHz', 'Average'};
    SlopeMaps(:, :, 4) = mean(SlopeMaps(:, :, 1:3), 3);
    for j = 1:2
        for i = 1:size(SlopeMaps, 3)
            cAH = AH((j-1)*4+i);
            Maps(i) = imagesc(cAH,O.X, O.Y, SlopeMaps(:, :, i)');
            hold(cAH, 'on');
            caxis(cAH, [-abs(max(SlopeMaps, [], 'all')), abs(max(SlopeMaps, [], 'all'))]);
            Maps(i).AlphaData = CranMask'.*1;
            set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
            colormap(cAH, CM)
            cAH.YAxis.Visible = 'off';
            cAH.XAxis.Visible = 'off';
            c1 = colorbar(cAH);
            ylabel(c1, 'Delta df/f');
            plot(cAH,[O.X(1),O.X(1)+1],[O.Y(end),O.Y(end)],'k','LineWidth',1);
            text(cAH,O.X(1)-0.2,O.Y(end)-0.2,'L','Rotation',90,'horiz','center', 'FontSize', 4)
            text(cAH,O.X(1)-0.2,O.Y(end)-0.8,'M','Rotation',90,'horiz','center',  'FontSize', 4)

            plot(cAH,[O.X(1),O.X(1)],[O.Y(end),O.Y(end)-1],'k','LineWidth',0.5)
            text(cAH,O.X(1)+0.2,O.Y(end)+0.2,'A','horiz','center',  'FontSize', 4)
            text(cAH,O.X(1)+0.8,O.Y(end)+0.2,'P','horiz','center',  'FontSize', 4)

            text(cAH,O.X(1)+0.1,O.Y(end)-0.2,'1mm','horiz','left',  'FontSize', 4)
            %ylabel(cAH, 'Mediolateral (mm)', 'FontSize', 4); xlabel(cAH, 'Anteroposterior (mm)', 'FontSize', 4);
            title(cAH, Title(i), 'Color', 'k', 'FontSize', 6);
            ylim(cAH, [min(O.Y), max(O.Y)]);
            xlim(cAH, [min(O.X), max(O.X)]);        

        end
    end
    
    for i = 9:12
        cAH = AH(i);
        for iA = 1:size(TuningR.Areas,3)
            cA = TuningR.AreaNames{iA};
            patch(cAH, TuningR.AreaVerticesCoordsMM.(cA).X+Xoffset,...
            TuningR.AreaVerticesCoordsMM.(cA).Y+Yoffset,[0.2,0.2,0.2],'FaceAlpha',0.2, 'EdgeColor', 'k', 'LineWidth', 1, 'Visible', 'on');
            text(cAH, mean(TuningR.AreaVerticesCoordsMM.(cA).X)+Xoffset-Toffset,...
            mean(TuningR.AreaVerticesCoordsMM.(cA).Y)+Yoffset, cA, 'FontSize', 4, 'Color', 'k', 'FontWeight', 'Bold', 'Visible', 'on');
        end
        colorbar(cAH, 'Visible', 'off')
        set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
        ylim(cAH, [min(O.Y), max(O.Y)]);
        xlim(cAH, [min(O.X), max(O.X)]);
    end   



end