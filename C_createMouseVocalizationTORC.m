function R =  C_createMouseVocalizationTORC(varargin)
%This file creates the speech stimuli that are used in the psychophysics
%experiment. 
%% PARSE PARAMETERS
P = parsePairs(varargin);
checkField(P,'Mode','Stimulus'); % Information or Stimulus
checkField(P,'Index',[]); % Return Stimulus for this Index
checkField(P,'Target','Save'); % Return or Save
checkField(P,'StimInfo',[]); % Stimulus Information ; Computed, unless provided
checkField(P,'Path',[]); % Alternative Path for saving
checkField(P,'Parameters',[]);
checkField(P,'Verbose',0);

% SET PATHS
if isempty(P.Path)
    P.Path = which('C_createMouseVocalization');
    Pos = find(P.Path==filesep,1,'last');
    P.Path = P.Path(1:Pos);
end
InPath = [P.Path,'BaseTextures',filesep];
switch P.Target
    case 'Save'; OutPath = [P.Path,filesep,'Stimuli',filesep];
end

%% DEFINE PARAMETERS (should never be changed, so that this remains reconstructable)
Par = P.Parameters;
SR = Par.SR;
SNR = 10^(Par.SNR/20); %Signal-to-noise ratio from dB to ratio where signal=1 noise=SNR
LStim=0.1; % s
Xges=0.2; % octaves
TargetDur =  (2*Par.NVocalRepetitions-1)*LStim;

NVocFrequencies = length(Par.VocalFrequencies);

switch P.Mode
    case 'Information'
        %% CREATE STIMULUS INDICES
        rng('default'); %Sometimes Matlab opens in an unchangable RNG mode, which screws with the seeding, so this is just a safety check
        
        StimulusBlocks = {'Texture','Clean'};
       
        for iStimBlock = 1:length( StimulusBlocks)
          cStimBlock=StimulusBlocks{iStimBlock};
          switch cStimBlock
            
            case 'Texture' % Inherited from earlier version of the stimulus (with few changes)
              StartTexture=[];
              iStim=0; iBase = 0;
              
              for iR=1:Par.NRealizations    
                for iC = 1:length(Par.Correlations)
                  for iV = 1:length(Par.Variances)
                    for iVoc = 1:NVocFrequencies
                      iStim=iStim+1;
                      StartTexture(iStim,:)=[iR, Par.Correlations(iC), Par.Variances(iV)];
                      VocalFrequencies(iStim,:) = Par.VocalFrequencies(iVoc); % Balance vocalization frequencies
                      % load BaseTexture
                      if iVoc == 1
                        iBase = iBase + 1;
                        TextureName = ['TORCNoise',...
                          '_corr',num2str(StartTexture(iStim,2)),'_var',num2str(StartTexture(iStim,3)),...
                          '_real',num2str(StartTexture(iStim,1))];
                        Soundfile =load([InPath, TextureName,'.mat']);
                        TextureSR = Soundfile.Fs; Texture=vertical(real(Soundfile.NoiseWaveform));
%                         [Texture,TextureSR] = audioread([InPath, TextureName,'.wav']);
                        R.BaseTextures{iBase} = C_StimConversion(Par.AmplitudeTexture,'dB2S') * Texture/std(Texture);
                        R.BaseTextureNames{iBase} = TextureName;
                      end
                      % Compute RMS for each Voc Frequency Location
                      fbase = Par.VocalFrequencies(iVoc);
                      [Vocalization,FRange]= prepareVocalization(LStim,Xges,fbase,SR);
                      
                      R.RMSLocalTexture(iStim) = computeLocalRMS(R.BaseTextures{iBase},FRange,SR);
                    end
                  end
                end
              end
              
              Index = 0;
              for iStim=1:size(StartTexture,1)
                        TextureName = ['TORCNoise',...
                          '_corr',num2str(StartTexture(iStim,2)),'_var',num2str(StartTexture(iStim,3)),...
                          '_real',num2str(StartTexture(iStim,1))];
                for iCT=1:length(Par.DurContext)
                  % RECORD STIMULUS PROPERTIES
                  Tpre(iCT) = Par.DurContext(iCT);
                  Ttrial(iCT) = Tpre(iCT) + TargetDur;
                  Index = Index + 1;
                  rng(Index);
                  RandNumber = rand(1);
               
                  R.StimInfo(Index) = struct(...
                    'BaseTexture',TextureName,...
                    'VocFrequency',VocalFrequencies(iStim),...
                    'PreTime',Tpre(iCT),...
                    'TargetDur', TargetDur,...
                    'Index',Index,...
                    'StimulusIndex',iStim,...
                    'TrialDuration',Ttrial(iCT)...
                    );
                end
              end
              
            case 'Clean'
              TextureName = 'Silence';
              StartTextureClean=[]; VocFrequenciesClean=[];
              for iRep = 1:Par.NCleanRepetitions
                for iVoc = 1:NVocFrequencies
                  StartTextureClean(end+1,:)=iRep;
                  VocFrequenciesClean(end+1,:) = Par.VocalFrequencies(iVoc); % Balance vocalization frequencies
                end
              end
              for iStim=1:size(StartTextureClean,1)
                cVocFreq = VocFrequenciesClean(iStim);
                for iCT=1:length(Par.DurContext)
                  % RECORD STIMULUS PROPERTIES
                  Tpre(iCT) = Par.DurContext(iCT);
                  Ttrial(iCT) = Tpre(iCT) + TargetDur;
                  Index = Index + 1;
                  rng(Index);
                  RandNumber = rand(1);
                  
                  R.StimInfo(Index) = struct(...
                    'BaseTexture',TextureName,...
                    'VocFrequency',cVocFreq,...
                    'PreTime',Tpre(iCT),...
                    'TargetDur', TargetDur,...
                    'Index',Index,...
                    'StimulusIndex',NaN,...
                    'TrialDuration',Ttrial(iCT)...
                  );
                end
              end
          end
        end
        
    case 'Stimulus'
        %% CREATE STIMULUS
        %Prepare Gating for stimulus
        GateDur = 0.01; % 10 ms cosine gate
        NGateSteps = round(GateDur*SR);
        GateTime = [0:NGateSteps-1]/SR;
        Gate = 1-(cos(2*pi*(1/(2*GateDur)*GateTime))+1)/2;
        
        % CREATE ONLY A PARTICULAR INDEX
        Indices = [P.StimInfo.Index];
        cStimInfo = P.StimInfo(P.Index==Indices);
        
        if ~strcmp(cStimInfo.BaseTexture,'Silence') % Load precomputed textures
          cInd = find(strcmp(cStimInfo.BaseTexture,P.BaseTextureNames));
          Texture = P.BaseTextures{cInd};
        else % Create array of zeros
          Texture = zeros(50*SR,1);
        end
        
        PreTime = cStimInfo.PreTime;
        
        TextureLength = round((PreTime +TargetDur) * SR);
        
        % Create proper length texture
        BackgroundTexture = Texture(1:TextureLength);
        BackgroundTexture = C_addRamp(BackgroundTexture,0.005,SR);
       
        if ~strcmp(cStimInfo.BaseTexture,'Silence') % Load precomputed textures
          iStim = cStimInfo.StimulusIndex;
          cRMSLocalTexture = P.RMSLocalTexture(iStim);
        else
          NStim = numel(P.RMSLocalTexture);
          RMSLocalTextureAllXVoc = reshape(P.RMSLocalTexture,[NVocFrequencies,NStim/NVocFrequencies]);
          iVoc = find(cStimInfo.VocFrequency == Par.VocalFrequencies);
          cRMSLocalTexture = mean(RMSLocalTextureAllXVoc(:,iVoc));
        end
        SpeechStimulus = ...
          addVocalization(LStim, Xges, cStimInfo.VocFrequency, SR, BackgroundTexture, SNR,cRMSLocalTexture, PreTime, Par.NVocalRepetitions);
        
        % ADD Gating at beginning and end
        SpeechStimulus(1:NGateSteps) = Gate'.* SpeechStimulus(1:NGateSteps);
        SpeechStimulus(end-NGateSteps+1:end) = Gate(end:-1:1)'.* SpeechStimulus(end-NGateSteps+1:end);
        
        % WRITE STIMULI TO DISK
        switch P.Target
            case 'Save'
                FilenameOut = [cStimInfo.Name,'.mat'];
                if P.Verbose;  disp(['Creating ',FilenameOut]); end
                save(FileNameOut,'SpeechStimulus');
        end
        
        R.Stimulus = SpeechStimulus;
        
    otherwise
        error(['Mode ',P.Mode,' not known.'])
        
end

function [Vocalization,FRange]= prepareVocalization(LStim,Xges,fbase,SRHz)
dt=1/SRHz;
T=[0:dt:LStim-dt];
sinusoid=sin(2*pi*(1/(4.8*LStim))*T.^(0.6));
F=fbase*(1+(2^Xges-1)*sinusoid);
UpperSpeechF=fbase*2^Xges;
FRange = [fbase,UpperSpeechF];

phaseinc=dt*F;
phases=cumsum(phaseinc);

Vocalization=sin(2*pi.*phases);
Vocalization = Vocalization/rms(Vocalization);

function RMSLocalTexture = computeLocalRMS(Texture,FRange,SRHz);
RMSLocalTexture = rms(bandpass(Texture,FRange,SRHz));

function Texture = addVocalization(LStim, Xges, fbase, SRHz, Texture, SNRVoc, RMSLocalTexture,PreTime, NVocalRepetitions)

[Vocalization,FRange]= prepareVocalization(LStim,Xges,fbase,SRHz);

Vocalization = Vocalization * RMSLocalTexture * SNRVoc;

PreSteps = round(PreTime*SRHz);
for iV=1:NVocalRepetitions
  StartPos = PreSteps + (iV-1)*(2*length(Vocalization)); % Length of Vocalization and following Pause, which are of the same length
  cInd = StartPos+1 : StartPos + length(Vocalization);
  Texture(cInd)= Texture(cInd) + Vocalization';
end


