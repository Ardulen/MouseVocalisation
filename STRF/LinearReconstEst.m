function M = LinearReconstEst(Stim,Resp,P)
% Stim : {Stimulus}[ Frequency X Time]  --------> [Frequency X Time]
% Resp : {Channel}[ Time X Rep X Neurons ] ----> [Time X Rep]
% 
% TrainStimuli: frequency*time
% TrainResp: time*Neuron
% TestResp:  time*Neuron

checkField(P,'Principle','directreverse');
checkField(P,'Method','inverse');
checkField(P,'Indices',[1:size(Resp,1)]);
checkField(P,'FIG',1);

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
STRFs = pinv(SS+10000*eye(size(SS)))*SR;

% DISPLAY STRFs
for i=1:NResp DispFilters{i} = reshape(STRFs(1:end,i),length(P.Frequency),length(P.FwdLag)); end
LF_showFilters('Time [ms]',P.FwdLag*1000,'Octaves',P.Frequency,DispFilters,...
  'STRFs per Neuron',[1:NResp],P.FIG*1001,1056); clear DispFilters

%% ESTIMATE RECONSTRUCTION FILTERS
switch lower(P.Principle)
  case 'directreverse'; % Optimal Stimulus Prior Reconstruction (Mesgarani et al. 2009, Eq.2)
    % Basic normal equations for mapping from the responses to the stimulus
    % In this way, correlations across neurons are removed, but stimulus correlations remain
    % These stimulus correlations are termed 'optimal stimulus prior'.
    Resp(isnan(Resp))=0;
    RespLag = LagGeneratorNew(Resp,round(P.BwdLag*P.SR));
    RespLag(:,end+1) = 1; % add constant input for estimate
    
    RR = RespLag'*RespLag; % Response-Response correlations
    RS = Stim*RespLag; % Stiumulus-Response correlations
    clear RespLag Stim Resp

    switch lower(P.Method)
      case 'inverse';
        G = inv(RR+1*eye(size(RR))) * RS';
      case 'pseudoinverse'; % 'Optimal Stimulus Prior', but estimated differently
        G = pinv(RR)*RS';
      case 'svd'; % Dimensionality reduction of the response matrix
        [U,S,V] = svd(RR);
        tmp1 = diag(S); tmp2 = tmp1/sum(tmp1);
        % Keep enough dimensions to explain 90% of the variance
        Explained = cumsum(tmp2);
        cnt1 = find(Explained>0.90,1,'first');
        % Reconstruction of the RR matrix, and estimation using the classical SVD decomposition
        % Inversion in the SVD case is achieved by transposing the matrices and sequence of multiplications
        % Invert inner matrix
        tmp1 = tmp1.^-1; tmp1(cnt1+1:end) = 0;
        G = ( V * diag(tmp1) * U' )*RS';
      otherwise error('Estimation method not known!');
    end; endl;
    % Reconstruction Filters
    % G is the reverse kernel, i.e. projecting from responses to stimuli
    assert(size(G,2)==length(P.Frequency),'Dimensions of G appear to wrong.')
    Filters = G(1:end-1,:); % -1 ... the constant?
   
    % DISPLAY RECONSTRUCTION FILTERS PER NEURON
    for i=1:NResp DispFilters{i} = Filters(i:NResp:end,:)'; end 
    LF_showFilters('Time [ms]',P.BwdLag*1000,'Frequency [Hz]',P.Frequency,DispFilters,...
      'Reconstruction Filters per Neuron',[1:NResp],P.FIG*1002,932); clear DispFilters
    
    % DISPLAY RECONSTRUCTION FILTERS PER FREQUENCY
    for i=1:length(P.Frequency) DispFilters{i} = reshape(Filters(:,i),NResp,length(P.BwdLag)); end
    LF_showFilters('Time [ms]',P.BwdLag*1000,'Neurons',[1:NResp],DispFilters,...
      'Reconstruction Filters per Frequency',P.Frequency,P.FIG*1003,805); clear DispFilters

  case 'forwardreverse'; % 'Flat Stimulus Prior' Reconstruction (Mesgarani et al. 2009, Eq.6ff)
    % Inversion of the forward estimated linear regression model
    % H maps from the population response (NCells X TimeSteps) to a STRFdims X TimeSteps Matrix.
    % See LinearReconstPred for the application of the inverse.
    switch lower(P.Method)
      case 'inverse'; 
        G = pinv(STRFs)';
        %G = inv(STRFs*STRFs' + 0.1*eye(size(STRFs,1)))*STRFs;
      otherwise error('Estimation method not known!');
    end; endl;
    % Reconstruction Filters
    assert(size(G,2)==NResp,'Dimensions of G appear to wrong.')

    % DISPLAY RECONSTRUCTION FILTERS PER Neuron
    for i=1:NResp DispFilters{i} = reshape(G(1:end,i),length(P.Frequency),length(P.FwdLag)); end
    LF_showFilters('Time [ms]',P.FwdLag*1000,'Frequency',P.Frequency,DispFilters,...
      'Reconstruction Filters per Neuron',[1:NResp],P.FIG*1002,932);    
    
  otherwise error('Estimation principle not known!');
end

M.Type = 'Linear'; M.Subtype = P.Principle;
M.Dims.Time = P.BwdLag;
M.Dims.Frequency = P.Frequency;
M.G = G;

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