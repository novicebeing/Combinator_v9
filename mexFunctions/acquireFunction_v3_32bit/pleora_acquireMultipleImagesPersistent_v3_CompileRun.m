% Compile and run camtest

% Clear old function
clear pleora_acquireMultipleImagesPersistent_v3

%cd H:\Codes&Scripts\Combinator\mexFiles\pleora
% Compile
mex(['-L' pwd],'-lCyCamLib','-lCyUtilsLib','-lCyComLib',['-I' pwd],'pleora_acquireMultipleImagesPersistent_v3.cpp')
return
%% Run
%a = pleora_acquireMultipleImagesPersistent(uint16(64),uint16(4),uint16(1));
[b,t] = pleora_acquireMultipleImagesPersistent_v3(uint16(64),uint16(16),uint16(53));
return

%%
%c = pleora_acquireMultipleImagesPersistent(uint16(2),uint16(320),uint16(256),uint16(1));
d = pleora_acquireMultipleImagesPersistent_v3();
error
size(d)