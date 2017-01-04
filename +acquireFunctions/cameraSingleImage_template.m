classdef cameraSingleImage_template < handle
	properties (Access = public)
		referenceImage
		fringeX
		fringeY
		wavenum
		averaging = true
		referenceType = 'staticReference'
	end
	
	properties (Access = private)
		ySum = [];
		wSum = [];
	end
	
	methods
		function this = cameraSingleImage_template()
			
		end
		function startImageAcquire(this)
			
		end
		function startSpectrumAcquire(this)
			
		end
		function stopAcquire(this)
			
		end
		function [imageOut,timeOut] = getImages(this)
			load vipaImagesForBen.mat
			
			% Get bkg Image
			bkgImage = double(acqImages(:,:,1));

			% Find the indices of the bad pixels
			badPixelIndcs = find(double(bkgImage)<0.75*mean(bkgImage(:)) | double(bkgImage)>1.5*mean(bkgImage(:)));
			
			testImage = double(acqImages(:,:,2))-bkgImage;
			testImage(badPixelIndcs) = NaN;
			imageOut = testImage' + 100*rand(size(testImage'));
			timeOut = 0;
		end
		function [spectra,time] = getSpectra(this)
			[images,time] = this.getImages();
			specImage = -log(images./this.referenceImage);
			specImage(images./this.referenceImage < 0) = NaN;
			
			if this.averaging == true
				y = this.image2spectrumStatic(this.fringeX,this.fringeY,specImage,2);
				[y,deltay] = this.assignyerror(this.wavenum,y);
				w = 1./deltay.^2;
				if isempty(this.ySum)
					this.ySum = w.*y;
					this.wSum = w;
				else
					this.ySum = this.ySum + w.*y;
					this.wSum = this.wSum + w;
				end
				spectra = this.ySum./this.wSum;
			else
				y = this.image2spectrumStatic(this.fringeX,this.fringeY,specImage,2);
				[yout,deltay] = this.assignyerror(this.wavenum,y);
				spectra = yout;
			end
		end
	end
	methods (Static)
		function spectrumOut = image2spectrumStatic(fringeX,fringeY,theImages,columnsToSum)
			indcsX = round(fringeX);
			indcsY = round(fringeY);
			nonnanindcs = ~isnan(indcsX);
			spectrumOut = zeros(size(indcsX,1),size(indcsX,2),size(theImages,3));
			%spectrumOut(repmat(~nonnanindcs,1,1,size(spectrum,3))) = NaN;
			for j = 1:size(theImages,3)
				spectrum = zeros(size(indcsX));
				spectrum(~nonnanindcs) = NaN;
				for i = -columnsToSum:columnsToSum
					spectrum(nonnanindcs) = spectrum(nonnanindcs) + theImages(sub2ind(size(theImages),indcsY(nonnanindcs),indcsX(nonnanindcs)+i,j.*ones(sum(sum(nonnanindcs)),1)));
				end
				spectrumOut(:,:,j) = spectrum;
			end
		end
		function [yout,deltay] = assignyerror(wavenum,yin)

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
		end
   end
end