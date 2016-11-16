classdef cameraSingleImage_fake()
	properties (Access = public, Dependent)
		images
		spectra
		wavenum
		time
	end
	methods (Access = public)
		function this = cameraSingleImage_fake(this,fringeX,fringeY,fringeImageSize,wavenum)
			this.fringeX = fringeX;
			this.fringeY = fringeY;
			this.fringeImageSize = fringeImageSize;
			this.wavenum = wavenum;
		end
		function acquireImages(this,averagingBoolean,referenceBoolean)
			
		end
		function acquireSpectra(this,averagingBoolean,referenceBoolean)
			
		end
		function stopAcquire(this)
			
		end
	end
	properties (Access = private)
		fringeX
		fringeY
		fringeImageSize
		wavenum
	end
	function [imageOut,timeOut,acquireTypeOut,referenceImagesBoolean] = cameraSingleImage_fake()
		load vipaImagesForBen.mat
		
		% Get bkg Image
		bkgImage = double(acqImages(:,:,1));

		% Find the indices of the bad pixels
		badPixelIndcs = find(double(bkgImage)<0.75*mean(bkgImage(:)) | double(bkgImage)>1.5*mean(bkgImage(:)));
		
		testImage = double(acqImages(:,:,2))-bkgImage;
		testImage(badPixelIndcs) = NaN;
		imageOut = testImage' + 100*rand(size(testImage'));
		timeOut = 0;
		acquireTypeOut = 'image';
		referenceImagesBoolean = false;
	end
end