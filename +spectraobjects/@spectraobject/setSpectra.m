function obj = setSpectra(obj,specWavenum,specY,specYerror,t)
    % averageSpectrum - adds a spectrum directly to the average
    %     Uses: t,wavenum,ysum,wsum
    
    % Check for proper dimensions
    if ~ismatrix(specWavenum) || ndims(specY)>3 || ~ismatrix(specYerror)
        ismatrix(specWavenum)
        ndims(specY)
        ismatrix(specYerror)
       error('Too many dimensions'); 
    end
    
    % Assign errors if necessary
    if isempty(specYerror)
       yout = zeros(size(specY));
       specYerror = zeros(size(specY));
       for i = 1:size(specY,3)
           [yout(:,:,i),specYerror(:,:,i)] = obj.assignyerror(specWavenum,specY(:,:,i));
       end
    end
    %yout = specY;
    
    % Calculate weights from errors
    w = 1./specYerror.^2;
    
    obj.t = t;
    obj.ysum = specY.*w;
    obj.wsum = w;
    obj.wavenum = specWavenum;
    
    % Average the spectra
    obj.averageSpectra();
    
    % Update the plots
    obj.updatePlots();
end