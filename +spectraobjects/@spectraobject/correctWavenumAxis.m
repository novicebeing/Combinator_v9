function correctWavenumAxis( obj, varargin )
    
    % Perform a spectral correction using D2O
	
    % First find 12 ms data
    ind = find(obj.t >= 12000);
    ind = ind(1);
	ind = 1;

    % Get the data
    fitx = obj.wavenum;
    fity = obj.ysum(:,:,ind)./obj.wsum(:,:,ind);
    %fity((fitx > 2623.2) & (fitx < 2623.25)) = NaN;
    %fity(fitx > 2673) = NaN;
    %fity(fitx < 2659) = NaN;
    %fity((fitx > 2658.54) & (fitx < 2658.86)) = NaN;
    %fity(fitx<2680) = NaN;

    % Get the relevant fitting parameters
    fitx = reshape(fitx,size(fity));
    centerWavenum = mean(fitx(:));
    vertScale = fitx(end,1)-fitx(1,1);
    horizScale = fitx(1,end)-fitx(1,1);

    % Load in the spectrum
    D2O = importdata('Toth_D2OMEAS_27M_2198-3100_no9s.txt');
    n_0 = 2.6867805e19;     % Loschmidt mlc/cm^3
    D2O_S = D2O.data(:,8)./n_0; % now in cm/mlc
    D2O_wavenum = D2O.data(:,1); % now in cm/mlc
    indcs = D2O_S>1e-22;
    D2O_S = D2O_S(indcs);
    D2O_wavenum = D2O_wavenum(indcs);
    
	% Load in the spectrum
	s = load('H:\Spectrum Library\OD\OD_v0_PGo.mat');
	OD_S = s.OD_v0_PGo.linestrength;
	OD_wavenum = s.OD_v0_PGo.lineposition;
	
    % Open the fitting figure
    fitobj = spectraobjects.VIPAxaxis(centerWavenum,vertScale,horizScale,fity);
    %fitobj.setSimulationSpectrum(D2O_wavenum,D2O_S);
	fitobj.setSimulationSpectrum(OD_wavenum,OD_S);

    % Fit the x axis
    %fitobj.autoSelectPeaks();
    %fitobj.findCorrespondingPeaks();
    %fitobj.fitYaxis();
    uiwait(fitobj.fitbrowser());
    
    % Display the x axis fitting on the report
    %[simPeaks,expPeaks] = fitobj.compareSimExpPeaks();

    % Get the x axis
    obj.wavenum = reshape(fitobj.getWavenum(),[],1);
    
    % Update all plots
    obj.updatePlots();
 end