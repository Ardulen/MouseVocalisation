function [out]=LagGeneratorNew(R,Lag)
% R: is the time*neurons
% out: is the time* (neuron*lags)

% Nima, 2008
out=zeros(size(R,1),size(R,2)*length(Lag));
ind2=0;
for i = 1:length(Lag)
  out(:,ind2+1:ind2+size(R,2)) = circshift(R,Lag(i));
  if Lag(i)<0
    out(end+Lag(i)+1:end,ind2+1:ind2+size(R,2)) = 0;
  else
    out(1:Lag(i),ind2+1:ind2+size(R,2)) = 0;
  end
  ind2 = ind2+size(R,2);
end