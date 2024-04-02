function [STRF,x,pst] = C_generateSTRF(Kspec,X,T)
% Generate STRF-Kernels by superimposing a number of templates at various locations.
% X = X.{Xres,Xges}; T = T.{SR,LSTRF}
global U; if isempty(U) U = units; end 
if ~isDimVar(T.LSTRF) T.LSTRF = T.LSTRF*U.ms; end; if ~isDimVar(T.SR) T.SR = T.SR*U.ms; end

% GENERATE STRF
Tsteps = fix(T.LSTRF*T.SR); Xsteps = fix(X.Xges/X.Xres+1); 
x = [0:X.Xres:X.Xges]; pst = [0:Tsteps-1]/T.SR;
STRF = zeros(Xsteps,Tsteps); 
for i=1:length(Kspec)
  eval(['STRF = STRF + Kspec{i}.A*LF_add',Kspec{i}.Type,'(Kspec{i}.Pars,X,T);']);
end

function STRF = LF_addGaussian(P,X,T)
global U;  [XT,Tsteps,Xsteps] = LF_genXT(X,T);
 STRF = mvnpdf(XT,[P.CF,P.CL/U.s],[P.SBW.^2,0;0,(P.LBW/U.s).^2]);
 STRF = reshape(STRF,Tsteps,Xsteps)'/sum(STRF(:));

function STRF = LF_addAlpha(P,X,T)
 global U; [XT,Tsteps,Xsteps] = LF_genXT(X,T); 
 STRF = 1/(sqrt(2*pi*P.SBW.^2))*exp(-(XT(:,1)-P.CL).^2/(2*P.SBW.^2)).*XT(:,2).*exp(-(XT(:,2)-P.CF)/P.Tau); 
 STRF = reshape(STRF,Tsteps,Xsteps)'/sum(STRF(:));

function STRF = LF_addBlock(P,X,T)
 global U; [XT,Tsteps,Xsteps] = LF_genXT(X,T); 
 STRF = zeros(length(XT),1);
 Xind = intersect(find(XT(:,1)>=P.CF-P.SBW),find(XT(:,1)<=P.CF+P.SBW));
 Tind = intersect(find(XT(:,2)>=(P.CL-P.LBW)/U.s),find(XT(:,2)<=(P.CL+P.LBW)/U.s));
 STRF(intersect(Xind,Tind)) = 1/(1/X.Xres * T.SR/U.kHz);  
 STRF = reshape(STRF,Tsteps,Xsteps)';
 
function [XT,Tsteps,Xsteps]= LF_genXT(X,T)
 Tsteps = fix(T.LSTRF*T.SR); Xsteps = fix(X.Xges/X.Xres+1);
 tmp = [0:X.Xres:X.Xres*(Xsteps-1)]';  tmp = repmat(tmp,1,Tsteps)'; XT(:,1) = tmp(:);
 tmp = [0:u2num(1/T.SR):u2num(1/T.SR)*(Tsteps-1)];   XT(:,2) = repmat(tmp,1,Xsteps)';
