function crossSection = createSpectrum(obj,wavenum, varargin)
    % createSpectrum - Outputs an array of cross sections using the inputs
    %      wavenum - input wavenumber array
    %      transitionWavenum - transition frequency in wavenumbers
    %      transitionStrength - transition strength in cm/molecule
    %      gaussianBroad - gaussian broadening in wavenumbers
    %      lorentzianBroad - lotrentzian broadening in wavenumbers
    
    % Check inputs
    p = inputParser;
    addParameter(p,'instrumentGaussianFWHM',0,@isnumeric);
    addParameter(p,'instrumentLorentzianFWHM',0,@isnumeric);
    addParameter(p,'instrumentPhase',0,@isnumeric);
    addParameter(p,'lineshapeFunction','pseudoVoigt',@ischar);
    parse(p,varargin{:});
    
    % Check dimension of wavenum input
    if ~ismatrix(wavenum)
        error('Wavenumber input must have 2 or less dimensions');
    end
    
    instrumentGaussianFWHM = p.Results.instrumentGaussianFWHM;
    instrumentLorentzianFWHM = p.Results.instrumentLorentzianFWHM;
    instrumentPhase = p.Results.instrumentPhase;
    lineshapeFunction = p.Results.lineshapeFunction;
    
    
    if isscalar(instrumentGaussianFWHM)
        instrumentGaussianFWHM = instrumentGaussianFWHM.*ones(size(obj.lineposition));
    else
        error('Not supported');
    end
    
    if isscalar(instrumentLorentzianFWHM)
        instrumentLorentzianFWHM = instrumentLorentzianFWHM.*ones(size(obj.lineposition));
    else
        error('Not supported');
    end
    
    if isscalar(instrumentPhase)
        instrumentPhase = instrumentPhase.*ones(size(obj.lineposition));
    else
        error('Not supported');
    end
    
    crossSection = zeros(size(wavenum));

    gaussianBroad = instrumentGaussianFWHM;
    lorentzianBroad = instrumentLorentzianFWHM;
    
    for i = 1:numel(wavenum)
        idx = abs(obj.lineposition - wavenum(i)) < 1;
        %crossSection(i) = sum(transitionStrength(idx).*areaNormalizedGaussian(wavenum(i),transitionWavenum(idx),gaussianBroad(idx)));
        %crossSection(i) = sum(transitionStrength(idx).*areaNormalizedLorentzian(wavenum(i),transitionWavenum(idx),lorentzianBroad(idx)));
        %crossSection(i) = sum(transitionStrength(idx).*areaNormVoigt(wavenum(i)-transitionWavenum(idx),gaussianBroad(idx),lorentzianBroad(idx)));
        crossSection(i) = sum(obj.linestrength(idx).*areaNormPseudoVoigt(wavenum(i)-obj.lineposition(idx),gaussianBroad(idx),lorentzianBroad(idx)));
    end
    
%     if numel(varargin) > 0
%         yin = reshape(crossSection,varargin{1});
% 
%         % Get non-nan values
%         yinNonNaN = yin;
%         yinNonNaN(isnan(yin)) = 0;
%         
%         % Construct filter matrix and normalization matrix
%         fmatrix = ones(60,1);
%         fmatrixNorm = filter2(fmatrix,~isnan(yin));
% 
%         % Calculate mean
%         ymean = filter2(fmatrix,yin)./fmatrixNorm;
% 
%         crossSection = crossSection - reshape(ymean,size(crossSection));
%     end
end

%---------- SPECTRUM GENERATION FUNCTIONS ----------------

function y = areaNormGaussian(x,FWHM)
% FWHM: Gaussian FWHM

    if FWHM == 0
        y = zeros(size(x));
        return
    end
    
    y = exp(-x.^2./(FWHM./sqrt(2.*log(2))./2).^2./2)./(FWHM./sqrt(2.*log(2))./2)./sqrt(2.*pi);
end

function y = areaNormLorentzian(x,FWHM)
% FWHM: Lorentzian FWHM

    y = FWHM./2./pi./(x.^2+FWHM.^2./4);
	
end

function y = areaNormVoigt(x,FWHMg,FWHMl)
% FWHMg: Gaussian FWHM
% FWHMl: lorentzian FWHM

    z = sqrt(log(2)).*complex(x,FWHMl./2)./(FWHMg./2);
    y = sqrt(log(2)).*cef(z,1000)./sqrt(pi)./(FWHMg./2);
	
end

function y = areaNormPseudoVoigt(x,GammaG,GammaL)
    % GammaG: Gaussian FWHM
    % GammaL: Lorentz FWHM
    
    Gamma = (GammaG.^5 + ...
        2.69269.*GammaG.^4.*GammaL + ...
        2.42843.*GammaG.^3.*GammaL.^2 + ...
        4.47163.*GammaG.^2.*GammaL.^3 + ...
        0.07842.*GammaG.^1.*GammaL.^4 + ...
        GammaL.^5).^(1./5);
    GammaRatio = GammaL./Gamma;
    eta = 1.36603.*GammaRatio - ...
        0.47719.*GammaRatio.^2 + ...
        0.11116.*GammaRatio.^3;

    y = (1-eta).*areaNormGaussian(x,GammaG) + ...
        eta.*areaNormLorentzian(x,GammaL);
		
end

function w = cef(z,N)

	%  Computes the function w(z) = exp(-z^2) erfc(-iz) using a rational 
	%  series with N terms.  It is assumed that Im(z) > 0 or Im(z) = 0.
	%
	%                             Andre Weideman, 1995

	M = 2*N;  M2 = 2*M;  k = [-M+1:1:M-1]';    % M2 = no. of sampling points.
	L = sqrt(N/sqrt(2));                       % Optimal choice of L.
	theta = k*pi/M; t = L*tan(theta/2);        % Define variables theta and t.
	f = exp(-t.^2).*(L^2+t.^2); f = [0; f];    % Function to be transformed.
	a = real(fft(fftshift(f)))/M2;             % Coefficients of transform.
	a = flipud(a(2:N+1));                      % Reorder coefficients.
	Z = (L+1i*z)./(L-1i*z); p = polyval(a,Z);    % Polynomial evaluation.
	w = 2*p./(L-1i*z).^2+(1/sqrt(pi))./(L-1i*z); % Evaluate w(z).

	% abs_carrier = exp(-4*(real(z)).^2*log(2));

end