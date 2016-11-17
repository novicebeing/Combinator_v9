function calibrateWavenumberFunction(this,spectrum)

    hfit = fitSpectrumXaxis_v2;

    hfit.simFilename = './Spectrum Simulations/D2O_sim_gaussian_1GHz.simSpec';
    disp('Warning: need to make fit spectrum number a variable')
                weightedAverage = 1;
                if weightedAverage == 1
                    plotSpectrum = self.constructTimeDynamicsPlot_weightedSummedSpectra(:,:,3)./self.constructTimeDynamicsPlot_weightSum(:,:,3);
                else
                    plotSpectrum = self.constructTimeDynamicsPlot_summedSpectra(:,:,3)/self.constructTimeDynamicsPlot_averageNum;
                end
                polyBaselineFit = 1;
                if polyBaselineFit == 1
                    polydegree = 2;
                    for j = 1:size(plotSpectrum,2)
                        Afit = reshape(plotSpectrum(:,j),[],1);
                        x = (1:numel(Afit))';
                        xfit = x(~isnan(Afit));
                        yfit = Afit(~isnan(Afit));

                        ws = warning('off','all');  % Turn off warning
                        ppA = polyfit(xfit, yfit,double(polydegree));
                        wFun = @(x,a,b) 0.5*(1-erf((abs(x)-a)/b));
                        for k = 1
                            ydiff = (yfit-polyval(ppA,xfit));
                            w = wFun(ydiff,std(ydiff),std(ydiff)/4);
                            ppA = self.wpolyfit(xfit,yfit,double(polydegree),w);
                        end
                        warning(ws);  % Turn it back on

                        plotSpectrum(:,j) = plotSpectrum(:,j) - polyval(ppA,x);
                    end
                end
    h = hfit.fitFrequencyAxis(plotSpectrum,...
        reshape(self.constructTimeDynamicsPlot_spectrumWavenumber,[],1));
    uiwait(h);
    fittedWavenumber = hfit.getFittedXaxis;
    if ~isempty(fittedWavenumber)
        self.constructTimeDynamicsPlot_spectrumWavenumber = reshape(fittedWavenumber,size(self.constructTimeDynamicsPlot_spectrumWavenumber));
        self.dependencyHandles.MOD_VIPA.spectrumX = 1e4./self.constructTimeDynamicsPlot_spectrumWavenumber;
    end
        
    delete(hfit);
	
    % Open the fitting figure
    fitobj = spectraobjects.VIPAxaxis(3900,1.8405,63.2908,spectrum);
    fitobj.setSimulationSpectrum([],[]);

    % Fit the x axis
    uiwait(fitobj.fitbrowser());
    
    % Display the x axis fitting on the report
    %[simPeaks,expPeaks] = fitobj.compareSimExpPeaks();

    % Get the x axis
    obj.wavenum = reshape(fitobj.getWavenum(),[],1);
end