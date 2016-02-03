function self = fitSpectrumWavenumber(self)
    
    hfit = fitSpectrumXaxis_v3;
    
    %hfit.simFilename = './Spectrum Simulations/D2O_sim_gaussian_1GHz.simSpec';

    %hfit.simFilename = './Spectrum Simulations/D2O_sim_gaussian_1GHz.simSpec';
    disp('Warning: need to make fit spectrum number a variable')
                [~,plotSpectrum] = self.createSpectra(cat(3,self.refImage,self.sigImage),[0 0],[true false]);
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
                            ppA = wpolyfit(xfit,yfit,double(polydegree),w);
                        end
                        warning(ws);  % Turn it back on

                        plotSpectrum(:,j) = plotSpectrum(:,j) - polyval(ppA,x);
                    end
                end
    % Construct Starting Wavenumber            
    reflambda = 3.725;
    fsr = 55;
    spectrumX = zeros(size(self.spectrumIndcs));
    for k = 1:size(self.spectrumIndcs,2)
        deltaLambda = fsr * 1e9 * ((reflambda/10^6)^2)/3e8 * 1e6;
        spectrumX(:,k) = reflambda + deltaLambda*(k-1) + ...
            deltaLambda/size(self.spectrumIndcs,1)*((1:size(self.spectrumIndcs,1))-1);
    end
                
    h = hfit.fitFrequencyAxis(plotSpectrum,...
        reshape(1e4./spectrumX,[],1));
    uiwait(h);
    fittedWavenumber = hfit.getFittedXaxis;
    if ~isempty(fittedWavenumber)
        self.xAxis_wavenumber = reshape(fittedWavenumber,size(self.spectrumIndcs));
        self.xaxisCalibrated = true;
    end
        
    delete(hfit);
end