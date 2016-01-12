function crossSection = createSpectrum( obj, wavenum, transitionWavenum,transitionStrength,gaussianBroad,lorentzianBroad,varargin)
    % createSpectrum - Outputs an array of cross sections using the inputs
    %      wavenum - input wavenumber array
    %      transitionWavenum - transition frequency in wavenumbers
    %      transitionStrength - transition strength in cm/molecule
    %      gaussianBroad - gaussian broadening in wavenumbers
    %      lorentzianBroad - lotrentzian broadening in wavenumbers
    
    if isscalar(gaussianBroad)
        gaussianBroad = gaussianBroad.*ones(size(transitionWavenum));
    end
    
    if isscalar(lorentzianBroad)
        lorentzianBroad = lorentzianBroad.*ones(size(transitionWavenum));
    end
    
    crossSection = zeros(size(wavenum));

    for i = 1:numel(wavenum)
        idx = abs(transitionWavenum - wavenum(i)) < 1;
        %crossSection(i) = sum(transitionStrength(idx).*areaNormalizedGaussian(wavenum(i),transitionWavenum(idx),gaussianBroad(idx)));
        %crossSection(i) = sum(transitionStrength(idx).*areaNormalizedLorentzian(wavenum(i),transitionWavenum(idx),lorentzianBroad(idx)));
        %crossSection(i) = sum(transitionStrength(idx).*areaNormVoigt(wavenum(i)-transitionWavenum(idx),gaussianBroad(idx),lorentzianBroad(idx)));
        crossSection(i) = sum(transitionStrength(idx).*areaNormPseudoVoigt(wavenum(i)-transitionWavenum(idx),gaussianBroad(idx),lorentzianBroad(idx)));
    end
    
    if numel(varargin) > 0
        yin = reshape(crossSection,varargin{1});

        % Get non-nan values
        yinNonNaN = yin;
        yinNonNaN(isnan(yin)) = 0;
        
        % Construct filter matrix and normalization matrix
        fmatrix = ones(60,1);
        fmatrixNorm = filter2(fmatrix,~isnan(yin));

        % Calculate mean
        ymean = filter2(fmatrix,yin)./fmatrixNorm;

        crossSection = crossSection - reshape(ymean,size(crossSection));
    end
end

