function [Xnew, Ynew]=C_alignFOVAcrosSetups(X, Y, Mouse)
switch Mouse
    case 'mouse193'
    XOffset = 7;
    YOffset = 12;
    PixelToMM = 40;
end
Xnew = X + XOffset/PixelToMM;
Ynew = Y + YOffset/PixelToMM;
end