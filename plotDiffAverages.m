function plotDiffAverages(R, P, DiffAvg, varargin)
    

    
    [X, Y, ~] = C_pixelToMM(P,R,R.Frames);
    PreTimes = [0.5, 1, 3, 5];
    %PreTime = squeeze(mean(mean(mean(mean(DiffAvg, 4), 5), 6), 7));
    Corrs = squeeze(mean(mean(mean(DiffAvg, 5), 6), 7));
    %Vars = squeeze(mean(mean(mean(T.VocResp.FullResp, 3), 6), 7));
    %Reals = squeeze(mean(mean(mean(T.VocResp.FullResp, 3), 5), 7));
    %VocFreqs = squeeze(mean(mean(mean(T.VocResp.FullResp, 4), 5), 6));
    Resp = ([144, 150, 2, 3]);
    for q = 1:2
        for i = 1:3
            VocStart = (2+PreTimes(i))*P.FR;
            dat = VocStart:VocStart+10;
            for j = 1:144
                for k = 1:150
                    Resp(j, k, q, i) = trapz(dat, Corrs(j, k, dat, q, i));
                end
            end
        end
    end
    
    MP = get(0,'MonitorPositions');
    NY = MP(1,end); HPixels = 540;
    FigureName=[P.Animal,' R',num2str(P.Recording),' Average of Difference Maps'];
    Fig = figure(1); clf; set(1,'name', FigureName, 'Color',[1,1,1],'Position',[5,NY-HPixels-60,1250,HPixels]);

    [~,AHTop] = axesDivide(3,2,[0.02, 0.4, 1, 0.5],[],0.4, 'c');
    AHTop = AHTop';
    Title={'PreTime 0.5', 'PreTime 1', 'PreTime 3'};
    for j = 1:2
       for i = 1:3
            %plots a single map for given data
            cAH = AHTop((j-1)*3+i);
            hold(cAH, 'on');
            imagesc(cAH, X, Y, Resp(:, :, j, i)'); %[cAH, AHB, cBar] = HF_imagescCraniotomy(Fig,cAH,cAH,O.X,O.Y,Adaptmap(:, :, O.P.Pl(i)),Adaptmap(:, :, O.P.Pl(i)),R.Frames.CraniotomyMask, 'AlphaF', 1, 'AlphaB', 0); 
            %O.GUI.(GUIDat).AlphaData = O.CraniotomyMask'.*1;
            set(cAH,'YDir','reverse','DataAspectRatio',[1,1,1])
            set(cAH, 'FontSize', 5);
            %set(cAH,'ButtonDownFcn',{@O.selectROI});
            %colormap(cAH, ColMap)
            caxis(cAH, [-0.1, 0.1]);
            %set(O.GUI.(GUIDat),'HitTest','off');
            c1 = colorbar(cAH);
            ylabel(c1, 'Area of peak');
            %ylabel(cAH, 'Mediolateral (mm)', 'FontSize', 4); xlabel(cAH, 'Anteroposterior (mm)', 'FontSize', 4);
            title(cAH, Title{i}, 'FontSize', 6);
            ylim(cAH, [min(Y), max(Y)]);
            xlim(cAH, [min(X), max(X)]);
       end
    end
    
    
    
    
   
end