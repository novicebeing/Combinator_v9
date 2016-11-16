function obj = averageSpectrum(obj,specWavenum,specY,specYerror,t)
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
    
    % Check that wavenum axis is the same
    if isempty(obj.wavenum)
        obj.wavenum = specWavenum;
    elseif obj.wavenum ~= specWavenum
        error('Wavenum axis is not the same!');
    end
    
    % Avoid NaN
        yadd = specY;
        wadd = w;
        yadd(isnan(yout)|isnan(w)) = 0;
        wadd(isnan(yout)|isnan(w)) = 0;
    
    % Check if t has already been included
    if isempty(obj.t)
        obj.ysum = yadd.*wadd;
        obj.wsum = wadd;
        obj.t = t;
    else
        for i = 1:numel(t)
            ind = find(t(i) == obj.t);
            if isempty(ind)
                ind = numel(obj.t)+1;
                obj.t(ind) = t(i);
                obj.ysum(:,:,ind) = zeros([size(obj.ysum,1) size(obj.ysum,2)]);
                obj.wsum(:,:,ind) = zeros([size(obj.wsum,1) size(obj.wsum,2)]);
            else
                ind = ind(1);
            end
            obj.ysum(:,:,ind) = obj.ysum(:,:,ind)+yadd(:,:,i).*wadd(:,:,i);
            obj.wsum(:,:,ind) = obj.wsum(:,:,ind)+wadd(:,:,i);
        end
    end
    
    % Average the spectra
    obj.averageSpectra();
    
    % Update the plots
    obj.updatePlots();
end