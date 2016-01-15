function obj = averageSpectrum(obj,specWavenum,specY,specYerror,t)
    % averageSpectrum - adds a spectrum directly to the average
    %     Uses: t,wavenum,ysum,wsum
    
    % Check for proper dimensions
    if ~ismatrix(specWavenum) || ~ismatrix(specY) || ~ismatrix(specYerror)
       error('Too many dimensions'); 
    end
    
    % Assign errors if necessary
    if isempty(specYerror)
       [yout,specYerror] = obj.assignyerror(specWavenum,specY);
    end
    
    % Calculate weights from errors
    w = 1./specYerror.^2;
    
    % Check that wavenum axis is the same
    if isempty(obj.wavenum)
        obj.wavenum = specWavenum;
    elseif obj.wavenum ~= specWavenum
        error('Wavenum axis is not the same!');
    end
    
    % Avoid NaN
        yadd = yout;
        wadd = w;
        yadd(isnan(yout)|isnan(w)) = 0;
        wadd(isnan(yout)|isnan(w)) = 0;
    
    % Check if t has already been included
    if isempty(obj.t)
        obj.ysum = yadd.*wadd;
        obj.wsum = wadd;
        obj.t = t;
    else
        ind = find(t == obj.t);
        if isempty(ind)
            ind = numel(obj.t)+1;
            obj.t(ind) = t;
            obj.ysum(:,:,ind) = zeros([size(obj.ysum,1) size(obj.ysum,2)]);
            obj.wsum(:,:,ind) = zeros([size(obj.wsum,1) size(obj.wsum,2)]);
        else
            ind = ind(1);
        end
        obj.ysum(:,:,ind) = obj.ysum(:,:,ind)+yadd.*wadd;
        obj.wsum(:,:,ind) = obj.wsum(:,:,ind)+wadd;
    end
    
    debugging = 0;
    if debugging == 1
        figure(10);
        ax = gca;
        h = plot(ax,specWavenum,reshape(yout,[],1)); hold(ax,'on');
        herrorplus = plot(ax,specWavenum,reshape(yout+1./sqrt(w),[],1));
        herrorminus = plot(ax,specWavenum,reshape(yout-1./sqrt(w),[],1));
        hold(ax,'off');
        
        figure(11);
        ax = gca;
        [tplot,averageErrorPlot] = obj.averageError(2682,2686);
        
        % Sort t,averageError
        [~,isort] = sort(tplot);
        
        bar(1./averageErrorPlot(isort));
    end
end