function [yout,deltay] = assignyerror(~,wavenum,yin)

    % Get non-nan values
    yinNonNaN = yin;
    yinNonNaN(isnan(yin)) = 0;
    
    % Check that the input is not NaN
    if ~isreal(yinNonNaN)>0
        yinNonNaN
        error('Non-real input');
    end

    % Construct filter matrix and normalization matrix
    fmatrix = ones(60,1);
    fmatrixNorm = filter2(fmatrix,~isnan(yin));
    
    % Calculate mean
    ymean = filter2(fmatrix,yinNonNaN)./fmatrixNorm;
    ymean(fmatrixNorm<40) = NaN;
    if ~isreal(ymean)
        error('Complex mean calculated');
    end
    yout = yin - ymean;
    yout(isnan(ymean) | isnan(yin)) = NaN;
    
    % Calculate the standard deviation
    youtnonnan = yout;
    youtnonnan(isnan(yout)) = 0;
    deltay = sqrt(filter2(fmatrix,youtnonnan.^2)./filter2(fmatrix,~isnan(yout)));
    if sum(~isreal(deltay(~isnan(deltay))))>0
        deltay(~isnan(deltay))
        error('Complex weight calculated');
    end
    deltay(isnan(yout)) = NaN;
    
    deltay(deltay == 0 | ~isfinite(deltay)) = NaN;
    yout(deltay == 0 | ~isfinite(deltay)) = NaN;
    
%     % Do not modify the spectrum
%     yout = yin - repmat(nanmean(yin,1),[size(yin,1) 1 1]);
%     yout(deltay == 0 | ~isfinite(deltay)) = NaN;
%     yout(isnan(ymean) | isnan(yin)) = NaN;
    
    % OLD SLOW METHOD
%         yout = zeros(size(yin));
%         deltay = zeros(size(yin));
%         ytemp = reshape(yin,size(yin,1)*size(yin,2),1,size(yin,3));
%         for i = 1:numel(wavenum)
%             ind = find(abs(wavenum-wavenum(i)) < 0.4);
%             [ii,jj] = ind2sub([size(yin,1) size(yin,2)],i);
%             deltay(ii,jj,:) = nanstd(ytemp(ind,:),[],1);
%             yout(ii,jj,:) = yin(ii,jj,:) - nanmean(ytemp(ind,:),1);
%         end
%         %obj.deltay(obj.deltay == 0) = NaN;
    % END OLD SLOW METHOD
end