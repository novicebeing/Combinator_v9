function calibrateWavenumberFunction(this,spectrum)
    % Open the fitting figure
    fitobj = spectraobjects.VIPAxaxis(3900,2,60,spectrum);
    fitobj.setSimulationSpectrum([],[]);

    % Fit the x axis
    uiwait(fitobj.fitbrowser());
    
    % Display the x axis fitting on the report
    %[simPeaks,expPeaks] = fitobj.compareSimExpPeaks();

    % Get the x axis
    obj.wavenum = reshape(fitobj.getWavenum(),[],1);
end