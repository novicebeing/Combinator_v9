function performDOCOfit( obj )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

    % Load DOCO templates if necessary
    if isempty(obj.DOCOtemplateNames)
        obj.loadDOCOtemplates();
    end

    % Construct the fitting matrix
    %   Fitting matrix should be of size (x size,number of fitting
    %   elements)
    fitMatrix = reshape(obj.DOCOtemplateAvg,size(obj.DOCOtemplateAvg,1)*size(obj.DOCOtemplateAvg,2),size(obj.DOCOtemplateAvg,3));
    fitMatrix(isnan(fitMatrix)) = 0;
    
    % Normalize the stdev if necessary
    stdNormFactor = nanstd(fitMatrix,0,1);
    stdNormFactor(isnan(stdNormFactor)) = 1;
    stdNormFactor(stdNormFactor == 0) = 1;
    
    % Fit each spectrum
    beta = zeros([size(fitMatrix,2) size(obj.yavg,3)]);
    betaError = zeros([size(fitMatrix,2) size(obj.yavg,3)]);
    for i = 1:size(obj.yavg,3)
        % Get the data
        dataY = reshape(obj.yavg(:,:,i),size(obj.yavg,1)*size(obj.yavg,2),1);
        
        % Remove the NaN Values
        nonnanvals = ~isnan(dataY) & ~isnan(sum(fitMatrix,2));
        dataYnonnan = dataY(nonnanvals);
        nonnanvalsFitMatrix = repmat(reshape(nonnanvals,[],1),1,size(fitMatrix,2));
        fitMatrixnonnan = reshape(fitMatrix(nonnanvalsFitMatrix),[],size(fitMatrix,2));

        % Perform the matrix division
        %beta(:,i) = mldivide(fitMatrixnonnan./repmat(stdNormFactor,size(fitMatrixnonnan,1),1),(dataYnonnan/std(dataYnonnan))).*std(dataYnonnan)./stdNormFactor';
        Y = dataYnonnan;
        M = fitMatrixnonnan;
        alpha = 0.05;
        [b,bError] = regress(Y,M./repmat(nanmean(fitMatrixnonnan,1),size(fitMatrixnonnan,1),1),alpha);
        beta(:,i) = b./reshape(nanmean(fitMatrixnonnan,1),[],1);
        betaError(:,i) = (bError(:,2)-bError(:,1))/2./reshape(nanmean(fitMatrixnonnan,1),[],1);
    end

    % Plot the results
    figure;
    for i = 1:size(beta,1)
        shadederrorbar(obj.tavg,beta(i,:),betaError(i,:),'o'); hold on;
    end
    xlabel('Time [\mus]');
    ylabel('Integrated Absorbance');
    %title(sprintf('Multi Peak Fit: [%s]',sprintf('%g ',round(templateParams((npeaks+1):(2*npeaks))*100)/100)));    
    legend(obj.templateNames);
    
    % Construct the residuals
    yfit = fitMatrixnonnan*beta;
    yresiduals = obj.yavg;
    yresidualsError = obj.ystderror;
    nonnanvalsResiduals = repmat(reshape(nonnanvals,size(obj.yavg,1),size(obj.yavg,2)),[1 1 size(obj.yavg,3)]);
    yresiduals(nonnanvalsResiduals) = yresiduals(nonnanvalsResiduals) - yfit(:);
    
    % Display the residuals
    kobj = kineticsobject();
    kobj.name = 'Residuals';
    kobj.ysum = yresiduals./yresidualsError.^2;
    kobj.wsum = 1./yresidualsError.^2;
    kobj.t = obj.tavg;
    kobj.wavenum = obj.wavenum;
    kobj.plotbrowser;
end

