function [STRF, Resp] = createSTRF(Stim, varargin)

P = parsePairs(varargin);
checkField(P, 'NumFreqs', 26)

Time = linspace(0, 300, 30);
Octaves = 1:P.NumFreqs;
CenterOctave = 5;
CenterTime = 50;

% Generate Gaussian kernel
SigmaTime = 30; 
SigmaOct = 2;
GaussTime = exp(-(Time - CenterTime).^2 / (2 * SigmaTime^2));
GaussFreq = exp(-(Octaves -CenterOctave).^2 / (2 * SigmaOct^2));

% Create STRF
STRF = zeros(length(Octaves), length(Time));
for iF = 1:P.NumFreqs
          STRF(iF, :) = GaussFreq(iF)*GaussTime(:);
end

%Create Resp
Resp = 0;
for oct=1:P.NumFreqs 
    Resp = Resp + conv(Stim(oct,:),STRF(oct,:)); 
end
Resp = Resp(1:size(Stim, 2));

% Plot STRF
figure;
imagesc(Time, 0:.2:5, STRF);
xlabel('Time (ms)');
axis xy
ylabel('Octaves');
yticks(0:5)
title(['CenterOctave ', num2str(CenterOctave/5), ' CenterTime ', num2str(CenterTime)]);
colorbar;