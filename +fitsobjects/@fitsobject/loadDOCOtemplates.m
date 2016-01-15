function [Mreal] = loadDOCOtemplates( obj, varargin )

    if numel(varargin) > 0
        DOCOreport = varargin{1};
    else
        DOCOreport = [];
    end
    
    nTemplates = 3;
    obj.DOCOtemplateAvg = zeros(size(obj.ysum,1),size(obj.ysum,2),nTemplates);
    obj.DOCOtemplateError = zeros(size(obj.ysum,1),size(obj.ysum,2),nTemplates);
    obj.DOCOtemplateNames = {'D2O','DOCO','OD'};
    
    Mreal = zeros(size(obj.ysum,1),size(obj.ysum,2),nTemplates);

    % Generate D2O Spectrum

        % Load in the spectrum
        D2O = importdata('Toth_D2OMEAS_27M_2198-3100_no9s.txt');
        n_0 = 2.6867805e19;     % Loschmidt mlc/cm^3
        D2O_S = D2O.data(:,8)./n_0; % now in cm/mlc
        D2O_wavenum = D2O.data(:,1); % now in cm/mlc
    
%     fwhm = 0.032452108748898;
%     simW = [2644:0.01:2708.4];
%     D2O = importdata('Toth_D2OMEAS_27M_2198-3100_no9s.txt');
%     y = calculate_D2O_midIRcavity_spectrum(D2O,...
%         simW,fwhm);

    fwhm = 0.02997;
    x = reshape(obj.wavenum,[],1);
    yy = obj.createSpectrum(x,D2O_wavenum,D2O_S,0.0001,fwhm);
    %yy = reshape(interp1(simW,y,obj.wavenum),size(obj.ysum,1),size(obj.ysum,2));
    
    b = kineticsobject();
    b.averageSpectrum(x,yy,[],0);
    %b.plotbrowser

    obj.DOCOtemplateAvg(:,:,1) = reshape(b.ysum./b.wsum,size(obj.ysum,1),size(obj.ysum,2));
    Mreal(:,:,1) = reshape(yy,size(obj.ysum,1),size(obj.ysum,2));
    
    % Generate tDOCO spectrum at correct wavelength
    
    fwhm = 0.02997;
    tDOCO = importdata('transDOCO_45jmax.txt');
    tDOCO_wavenum = tDOCO(:,1);
    T = 273.15+21; %K
    tDOCO_S = tDOCO(:,2)*273.15/T;
    tDOCO_S(tDOCO_wavenum > 2682.8 & tDOCO_wavenum < 2683.2) = 0;
    
    x = reshape(obj.wavenum,[],1);
    yy = obj.createSpectrum(x,tDOCO_wavenum,tDOCO_S,0.0001,fwhm);

    b = kineticsobject();
    b.averageSpectrum(x,yy,[],0);
    %b.plotbrowser

    obj.DOCOtemplateAvg(:,:,2) = reshape(b.ysum./b.wsum,size(obj.ysum,1),size(obj.ysum,2));
    Mreal(:,:,2) = reshape(yy,size(obj.ysum,1),size(obj.ysum,2));    
    
    % Generate OD Spectrum
    peakPositions = [2662.3642 1;...
                    2662.4587 1;...
                    2676.6656 1;...
                    2676.6920 1;...
                    2681.7079 1;...
                    2681.7754 1;...
                    2693.6165 1;...
                    2693.6676 1;...
                    2700.3024 1;...
                    2700.3396 1;...
                    2710.1418 1;...
                    2710.2152 1];
    fwhm = 0.02997;
    
    x = obj.wavenum;
    yy = obj.createSpectrum(x,peakPositions(:,1),peakPositions(:,2)./max(peakPositions(:,2))*3e-20,0.0001,fwhm);
    
    b = kineticsobject();
    b.averageSpectrum(x,yy,[],0);
    %b.plotbrowser
    
    obj.DOCOtemplateAvg(:,:,3) = reshape(b.ysum./b.wsum,size(obj.ysum,1),size(obj.ysum,2));
    Mreal(:,:,3) = reshape(yy,size(obj.ysum,1),size(obj.ysum,2));
    
    % Add etalon frequencies
    etalonLengths = [2.15:0.01:2.25 13.2:0.01:13.3]; % in cm
    x = obj.wavenum;
    for i = 1:numel(etalonLengths)
        yySin = 1e-3*sin(x.*etalonLengths(i).*pi.*4);
        yyCos = 1e-3*cos(x.*etalonLengths(i).*pi.*4);
        b = kineticsobject();
        b.averageSpectrum(x,yySin,[],0);
        %b.plotbrowser
        obj.DOCOtemplateAvg(:,:,end+1) = reshape(b.ysum./b.wsum,size(obj.ysum,1),size(obj.ysum,2));
        b = kineticsobject();
        b.averageSpectrum(x,yyCos,[],0);
        %b.plotbrowser
        obj.DOCOtemplateAvg(:,:,end+1) = reshape(b.ysum./b.wsum,size(obj.ysum,1),size(obj.ysum,2));
    end
    
    % Set appropriate variables
    
    obj.templateAvg = obj.DOCOtemplateAvg;
    obj.templateError = obj.DOCOtemplateError;
    obj.templateNames = obj.DOCOtemplateNames;
    
end