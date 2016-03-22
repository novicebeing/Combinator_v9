function [simPeaks,expPeaks] = correctDOCOwavenumAxis( obj, varargin )

    if numel(varargin) > 0
        import mlreportgen.dom.*;
        DOCOreport = varargin{1};
    else
        DOCOreport = [];
    end
    
    % Perform a spectral correction using D2O

    % First find 12 ms data
    ind = find(obj.t >= 12000);
    ind = ind(1);

    % Get the data
    fitx = obj.wavenum;
    fity = obj.ysum(:,:,ind)./obj.wsum(:,:,ind);
    fity((fitx > 2658.54) & (fitx < 2658.86)) = NaN;

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

    % Open the fitting figure
    fitobj = spectraobjects.VIPAxaxis(centerWavenum,vertScale,horizScale,fity);
    fitobj.setSimulationSpectrum(D2O_wavenum,D2O_S);

    % Fit the x axis
    fitobj.autoSelectPeaks();
    fitobj.findCorrespondingPeaks();
    fitobj.fitYaxis();
    
    % Display the x axis fitting on the report
    [simPeaks,expPeaks] = fitobj.compareSimExpPeaks();

    % Get the x axis
    obj.wavenum = reshape(fitobj.getWavenum(),[],1);
 end