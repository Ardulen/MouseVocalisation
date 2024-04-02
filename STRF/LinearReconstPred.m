function StimR = LinearReconstPred(Stim,Resp,Model,P)
% Stim : {Stimulus}[ Frequency X Time]  --------> [Frequency X Time]
% Resp : {Channel}[ Time X Rep X Stimulus ] ----> [Time X Rep]
% 
% TrainStimuli: frequency*time
% TrainResp: time*Neuron
% TestResp:  time*Neuron

if ~isfield(P,'Indices') P.Indices = [1:size(Resp,1)]; end

NResp = size(Resp,3);
NFrequencies = size(Stim,1);
Time = [0:size(Stim,2)-1]/P.SR;
Frequency = P.Frequency;

% EXTEND INDICES BY TEMPORAL KERNEL LENGTH
if P.Indices(end)~=length(Time)
  NExtend = length(Model.Dims.Time);
  P.Indices = [P.Indices,P.Indices(end)+[1:NExtend]];
end

% CREATE PSTH
Resp = squeeze(nanmean(Resp(P.Indices,:,:),2));
Resp(isnan(Resp))=0;

% RECONSTRUCT STIMULU BASED ON MODEL TYPE
switch lower(Model.Type)
  case 'linear'
    
    switch lower(Model.Subtype)
      case 'directreverse'
        RespLag = LagGeneratorNew(Resp,round(P.BwdLag*P.SR));
        RespLag(:,end+1) = 1; % Constant Term (already present in G)
        StimR = Model.G'*RespLag';
        
      case 'forwardreverse';
        % Since this is not on the lagged representation, it ends up as only a linear combination of the Neurons, 
        % which is much weaker than for the 'Optimal Stimulus Prior'...
        % The combination can be weighted with different parts of the inverted STRF
        % One contracts the matrix to make use of the different time-point predictions
        
        cStimLag = Model.G*Resp';
        %cStimConst = cStimLag(end,:); % Add back the constant term
        % Reshape and average/select from different delay representation
        cStimLag = reshape(cStimLag(1:end,:),[NFrequencies,length(P.BwdLag),length(Time)]);
        
        cStimR = zeros(NFrequencies,length(Time));
        for iF=1:length(P.BwdLag)
          cStimR(:,1:end-iF+1) = cStimR(:,1:end-iF+1) + squeeze(cStimLag(:,iF,iF:end));
        end
        %cStimR = cStimR + repmat(cStimConst,[length(Frequency),1]);
        StimR = cStimR;
    end
end

% REDUCE PREDICTION AGAIN
if P.Indices(end)~=length(Time)
  StimR = StimR(:,1:end-NExtend);
end