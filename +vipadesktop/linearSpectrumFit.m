function fitobjectout = linearSpectrumFit(spectrumobject,fitspectrumobjects,fitoptions)
    % Check the input arguments
    if ~isa(spectrumobject,'kineticsobject') && ~isa(spectrumobject,'spectraobjects.spectraobject')
        error('Spectra object must be of "kineticsobject" or "spectraobjects.spectraobject" type');
    end
%     if ~isa(fitspectrumobjects,'fitspectraobjects.linelist')
%         if iscell(fitspectrumobjects)
%             if sum(cellfun(@(x) isa(x,'fitspectraobjects.linelist'),fitspectrumobjects))>1
%                 error('Spectra object must be of "fitspectraobjects.linelist" type or a cell array of that type');
%             end
%         else
%             error('Spectra object must be of "fitspectraobjects.linelist" type or a cell array of that type');
%         end
%     end
%     if ~isa(fitoptions,'vipadesktop.fitoptions')
%         error('Spectra object must be of "vipadesktop.fitoptions" type');
%     end

    % Warn that gaussian fwhm is hard coded
    %warning('Gaussian FWHM is hard coded...');
    %warning('kineticsobject averaging is hard coded...');
    %warning('nan removal with averaging is hard coded...');
    
    % Make sure that the kineticsobject spectrum is properly averaged
    spectrumobject.averageSpectra();
    
    % Construct the fit matrix
    fitbNames = {};
    fitbInd = [];
    x = spectrumobject.wavenum;
    fitMatrix = zeros(size(x,1),size(x,2),numel(fitspectrumobjects));
    fitArrayNum = 1;
    for i = 1:numel(fitspectrumobjects)
        for j = 1:numel(fitspectrumobjects{i})
            y = fitspectrumobjects{i}(j).createSpectrum(x,'instrumentLorentzianFWHM',0.06);%0.02997); %***
            k = kineticsobject(); %***
            k.averageSpectrum(x,y,[],0);
            yy = k.ysum./k.wsum;
            yy(isnan(yy)) = 0;
            fitMatrix(:,:,fitArrayNum) = yy;
            fitbNames{fitArrayNum} = fitspectrumobjects{i}(j).name;
            fitbInd(fitArrayNum) = fitArrayNum;
            fitArrayNum = fitArrayNum + 1;
        end
    end
    
    % Reshape the fit matrix
    fitMatrix = reshape(fitMatrix,size(fitMatrix,1)*size(fitMatrix,2),size(fitMatrix,3));

    % Fit each spectrum
    beta = zeros([size(fitMatrix,2) size(spectrumobject.yavg,3)]);
    betaError = zeros([size(fitMatrix,2) size(spectrumobject.yavg,3)]);
    for i = 1:size(spectrumobject.yavg,3)
        % Get the data
        dataY = reshape(spectrumobject.yavg(:,:,i),size(spectrumobject.yavg,1)*size(spectrumobject.yavg,2),1);
        
        % Remove the NaN Values
        nonnanvals = ~isnan(dataY) & ~isnan(sum(fitMatrix,2));
        dataYnonnan = dataY(nonnanvals);
        nonnanvalsFitMatrix = repmat(reshape(nonnanvals,[],1),1,size(fitMatrix,2));
        fitMatrixnonnan = reshape(fitMatrix(nonnanvalsFitMatrix),[],size(fitMatrix,2));

        % Perform the matrix division
        Y = dataYnonnan;
        M = fitMatrixnonnan;
        alpha = 0.05;
        [b,bError] = regress(Y,M./repmat(nanmean(fitMatrixnonnan,1),size(fitMatrixnonnan,1),1),alpha);
        beta(:,i) = b./reshape(nanmean(fitMatrixnonnan,1),[],1);
        betaError(:,i) = (bError(:,2)-bError(:,1))/2./reshape(nanmean(fitMatrixnonnan,1),[],1);
    end
    
    % Construct the fit object
    fitobjectout = fitsobjects.fitsobject();
    fitobjectout.name = spectrumobject.name;
    fitobjectout.y = spectrumobject.yavg;
    fitobjectout.yError = spectrumobject.ystderror;
    fitobjectout.t = spectrumobject.tavg;
    fitobjectout.wavenum = spectrumobject.wavenum;
    fitobjectout.fitM = fitMatrix;
    fitobjectout.fitb = beta;
    fitobjectout.fitbError = betaError;
    fitobjectout.fitbNames = fitbNames;
    fitobjectout.fitbNamesInd = fitbInd;
end