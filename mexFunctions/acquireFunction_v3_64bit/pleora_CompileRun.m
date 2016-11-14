% Compile and run camtest

% Clear old function
clear pleora

%cd H:\Codes&Scripts\Combinator\mexFiles\pleora
% Compile
cd 'C:\Users\bryce\Documents\GitHub\Combinator_v9\mexFunctions\acquireFunction_v3_64bit'
mex(['-L' pwd],'-lCyCamLib64','-lCyUtilsLib64','-lCyComLib64',['-I' pwd],'pleora.cpp')
return
%% Run
%a = pleora_acquireMultipleImagesPersistent(uint16(64),uint16(4),uint16(1));
[b,t] = pleora_acquireMultipleImagesPersistent_v4(uint16(64),uint16(16),uint16(53));
return

%%
%c = pleora_acquireMultipleImagesPersistent(uint16(2),uint16(320),uint16(256),uint16(1));
d = pleora_acquireMultipleImagesPersistent_v3();
error
size(d)