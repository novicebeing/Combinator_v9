function [wavenum,returnSpectra,spectraTime] = createSpectra(self,returnImages,time,refImageBoolean)

        % Check if refImageBoolean is empty
        if isempty(refImageBoolean)
            refImageBoolean = zeros(size(time));
        end
        
        % Check to see if there are any reference images. Add one if not
        if sum(refImageBoolean) == 0
            % Check to see if we actually have a reference image
            if isempty(self.refImage)
                errordlg('Calibration Reference Image is not set','Calibration Error','modal');
                wavenum = [];
                returnSpectra = [];
                spectraTime = [];
                return
            end
                
            returnImages = cat(3,self.refImage,returnImages);
            refImageBoolean = [true; refImageBoolean(:)];
            time = [NaN; time(:)];
        end
        
        returnImages = permute(returnImages,[2 1 3]);
        numImages = size(returnImages,3);

        % Construct the indices for the image
        imageOffset = repmat(0:(numImages-1),[numel(self.spectrumIndcs) 1]);
        indcs = repmat(round(self.spectrumIndcs(:)),[1 numImages]);
        numElements = self.fringeImageSize(1)*self.fringeImageSize(2);
        spectrumIndcs = imageOffset*numElements + indcs;
        spectrumIndcs = reshape(spectrumIndcs,size(self.spectrumIndcs,1),size(self.spectrumIndcs,2),[]);
        
        % Construct the indices for the image
        imageOffset = repmat(0:(numImages-1),[numel(self.spectrumIndcs) 1]);
        indcs = repmat(round(self.spectrumIndcs(:))-1,[1 numImages]);
        numElements = self.fringeImageSize(1)*self.fringeImageSize(2);
        spectrumIndcsL = imageOffset*numElements + indcs;
        spectrumIndcsL = reshape(spectrumIndcsL,size(self.spectrumIndcs,1),size(self.spectrumIndcs,2),[]);
        
        % Construct the indices for the image
        imageOffset = repmat(0:(numImages-1),[numel(self.spectrumIndcs) 1]);
        indcs = repmat(round(self.spectrumIndcs(:))-2,[1 numImages]);
        numElements = self.fringeImageSize(1)*self.fringeImageSize(2);
        spectrumIndcs2L = imageOffset*numElements + indcs;
        spectrumIndcs2L = reshape(spectrumIndcs2L,size(self.spectrumIndcs,1),size(self.spectrumIndcs,2),[]);
        
        % Construct the indices for the image
        imageOffset = repmat(0:(numImages-1),[numel(self.spectrumIndcs) 1]);
        indcs = repmat(round(self.spectrumIndcs(:))-3,[1 numImages]);
        numElements = self.fringeImageSize(1)*self.fringeImageSize(2);
        spectrumIndcs3L = imageOffset*numElements + indcs;
        spectrumIndcs3L = reshape(spectrumIndcs3L,size(self.spectrumIndcs,1),size(self.spectrumIndcs,2),[]);
        
        % Construct the indices for the image
        imageOffset = repmat(0:(numImages-1),[numel(self.spectrumIndcs) 1]);
        indcs = repmat(round(self.spectrumIndcs(:))+1,[1 numImages]);
        numElements = self.fringeImageSize(1)*self.fringeImageSize(2);
        spectrumIndcsR = imageOffset*numElements + indcs;
        spectrumIndcsR = reshape(spectrumIndcsR,size(self.spectrumIndcs,1),size(self.spectrumIndcs,2),[]);
        
        % Construct the indices for the image
        imageOffset = repmat(0:(numImages-1),[numel(self.spectrumIndcs) 1]);
        indcs = repmat(round(self.spectrumIndcs(:))+2,[1 numImages]);
        numElements = self.fringeImageSize(1)*self.fringeImageSize(2);
        spectrumIndcs2R = imageOffset*numElements + indcs;
        spectrumIndcs2R = reshape(spectrumIndcs2R,size(self.spectrumIndcs,1),size(self.spectrumIndcs,2),[]);
        
        % Construct the indices for the image
        imageOffset = repmat(0:(numImages-1),[numel(self.spectrumIndcs) 1]);
        indcs = repmat(round(self.spectrumIndcs(:))+3,[1 numImages]);
        numElements = self.fringeImageSize(1)*self.fringeImageSize(2);
        spectrumIndcs3R = imageOffset*numElements + indcs;
        spectrumIndcs3R = reshape(spectrumIndcs3R,size(self.spectrumIndcs,1),size(self.spectrumIndcs,2),[]);
        
        % Construct the spectra
        if isempty(returnImages)
            returnSpectra = [];
        else
            returnSpectra = zeros(size(spectrumIndcs));
            returnSpectra(:) = NaN;
            returnSpectra(~isnan(spectrumIndcs)) = ...
                double(...
                returnImages(round(...
                spectrumIndcs(~isnan(spectrumIndcs))...
                )))/1;
%                 )) + ...
%                 1*returnImages(round(...
%                 spectrumIndcsR(~isnan(spectrumIndcsR))...
%                 )) + ...
%                 1*returnImages(round(...
%                 spectrumIndcs2R(~isnan(spectrumIndcs2R))...
%                 )) + ...
%                 1*returnImages(round(...
%                 spectrumIndcs3R(~isnan(spectrumIndcs3R))...
%                 )) + ...
%                 1*returnImages(round(...
%                 spectrumIndcsL(~isnan(spectrumIndcsL))...
%                 )) + ...
%                 1*returnImages(round(...
%                 spectrumIndcs2L(~isnan(spectrumIndcs2L))...
%                 )) + ...
%                 1*returnImages(round(...
%                 spectrumIndcs3L(~isnan(spectrumIndcs3L))...
%                 )))/7;
        end
        
        % Perform the log transformation
        returnSpectra(returnSpectra<0) = NaN;
        returnSpectra = -log(returnSpectra);
        
        % Set some nice functions
        diffNice = @(a,dim) filter([1 -1],1,a,[],dim); % [a(1); diff(a)]
        diffNiceInv = @(a,dim) cumsum(a,dim); % Inverse of above
        
        % Perform spectral stitching
        a = diffNice(round(self.fringeX),1);
        a(isnan(a)) = 0;
        a(1,:,:) = 0;
        a = circshift(a,0,1);
        
        % Take the difference vertically along the fringes
        returnSpectraNonNaN = returnSpectra;
        returnSpectraNonNaN(isnan(returnSpectra)) = 0;
        returnSpectraDiff = diffNice(returnSpectraNonNaN,1);
        %returnSpectraDiff(repmat(a,1,1,size(returnSpectraNonNaN,3)) ~= 0) = 0;
        returnSpectraNonNaN = diffNiceInv(returnSpectraDiff,1);
        returnSpectraNonNaN(isnan(returnSpectra)) = NaN;
        
        returnSpectra = reshape(returnSpectraNonNaN,[size(self.spectrumIndcs,1) size(self.spectrumIndcs,2) numImages]);
        
        % Find the reference for each signal image
            refIndex = zeros(size(refImageBoolean));
            % Next, iterate through the references
            refImageIndices = find(refImageBoolean);
            for i = 1:numel(refImageIndices)
                if i == 1
                    refIndex((1:numel(refIndex))<refImageIndices(1)) = refImageIndices(1);
                end
                refIndex((1:numel(refIndex))>refImageIndices(i)) = refImageIndices(i);
            end
            % Set the references to NaN
            refIndex(refImageBoolean) = NaN;
    
        %returnSpectra(returnSpectra<0) = NaN;
        returnSpectra = returnSpectra(:,:,~isnan(refIndex)) -returnSpectra(:,:,refIndex(~isnan(refIndex)));
        spectraTime = time(~isnan(refIndex));
        wavenum = self.xAxis_wavenumber;
end

