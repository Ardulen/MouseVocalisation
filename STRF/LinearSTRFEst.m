function LinearSTRFEst(Stim, Resp, varargin)
P = parsePairs(varargin);
checkField(P,'Principle','directreverse');
checkField(P,'Method','inverse');
checkField(P,'Indices',[1:size(Resp,1)]);
checkField(P,'FIG',1);
checkField(P, 'Lambda', 100);
checkField(P, 'FwdLag', 0.01:0.01:0.3);
checkField(P, 'Frequency', 0:0.2:5); 
checkField(P, 'SR', 100);

NResp = size(Resp,3);
NChannels = size(Stim,1);

% CREATE PSTH
Resp = squeeze(nanmean(Resp(P.Indices,:,:),2));

%% COMPUTE STRFS
fprintf('Estimating STRFs...\n');
Stim = Stim(:,P.Indices);
StimLag = LagGeneratorNew(Stim',round(P.FwdLag*P.SR));
% StimLag(:,end+1) = 1; % add constant input for estimate
SS = StimLag'*StimLag;
SR = StimLag'*Resp;
STRFs = pinv(SS+P.Lambda*eye(size(SS)))*SR;

% DISPLAY STRFs
for i=1:NResp DispFilters{i} = reshape(STRFs(1:end,i),length(P.Frequency),length(P.FwdLag)); end
LF_showFilters('Time [ms]',P.FwdLag*1000,'Octaves',P.Frequency,DispFilters,...
  'STRF (0.7 0.7)',[1:NResp],P.FIG*15,1056); clear DispFilters


function LF_showFilters(XLabel,X,YLabel,Y,Filters,Title,Plots,FIG,Pos);

if FIG
  GPos = [.03,.18,.95,.8];
  figure(FIG); clf;
  set(gcf,'Name',Title,'NumberTitle','off','Toolbar','none','Menubar','none');
  [DC,AH] = axesDivide(length(Plots),1,GPos,.2,[],'c');
  CM = HF_colormap({[0,0,1],[1,1,1],[1,0,0]},[-1,0,1]); colormap(CM);
  
  for i=1:length(Plots)
    axes(AH(i));
    cFilter = Filters{i}/std(Filters{i}(:));
    imagesc(X,Y,cFilter); set(gca,'YDir','normal'); caxis([-4,4]);
    text(0.9,0.9,[sprintf('%5.0f',Plots(i))],'Units','n','Horiz','r','FontSize',8);
    if i>1 axis off; else set(gca,'FontSize',7); ylabel(YLabel); xlabel(XLabel); end
  end
  drawnow;
end