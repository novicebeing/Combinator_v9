function calibrateWavenumberFunction(this,spectrum)
    % Open the fitting figure
    fitobj = spectraobjects.VIPAxaxis(2595,1.8405,63.2908,spectrum);
	%s = load('C:\Users\bryce\Documents\GitHub\Combinator_v9\Spectrum Simulations\06_hit04.mat');
	%s = load('H:\GitHub\Combinator_v9\Spectrum Simulations\06_hit04.mat');
    s = load([fileparts(which('openvipaworkspace')) '\Spectrum Simulations\06_hit04.mat']);
	fitobj.setSimulationSpectrum(s.s.wnum,s.s.int);

    % Fit the x axis
    uiwait(fitobj.fitbrowser());
    
    % Display the x axis fitting on the report
    %[simPeaks,expPeaks] = fitobj.compareSimExpPeaks();

    % Get the x axis
    this.wavenum = reshape(fitobj.getWavenum(),[],1);
end