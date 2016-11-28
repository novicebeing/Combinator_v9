classdef cameraSingleImage
	properties (Access = public)
		referenceImage
		fringeX
		fringeY
		wavenum
	end

	methods
		function this = cameraSingleImage()
			
		end
		function startImageAcquire(this)
			
		end
		function startSpectrumAcquire(this)
			
		end
		function stopAcquire(this)
			
		end
		function [imageOut,timeOut] = getImages(this)

			% Start Acquisition thread
			CAM_width = 320;
			CAM_height = 256;
			numImages = 18;
			[~,~] = pleoraAcquireFunctions.pleora_acquireMultipleImagesPersistent_v3(uint16(CAM_width),uint16(CAM_height),uint16(numImages));
			pause(0.2);
			
			% Get the images
			[collectedImageArray,timestampOut] = pleoraAcquireFunctions.pleora_acquireMultipleImagesPersistent_v3();
			timestamp = double(timestampOut).*480e-6/4;
			indBkg = find(abs(diff(timestamp)-3) < 0.1)+1;
			
			collectedImageArray = double(reshape(collectedImageArray,[CAM_width CAM_height numImages]));
			
			bkgImage = collectedImageArray(:,:,indBkg(1))';
			sigImage = collectedImageArray(:,:,indBkg(1)-1)';
			
			% Find the indices of the bad pixels
			badPixelIndcs = find(double(bkgImage)<0.75*mean(bkgImage(:)) | double(bkgImage)>1.5*mean(bkgImage(:)));
			
			bkgImage(badPixelIndcs) = NaN;
			sigImage(badPixelIndcs) = NaN;
			
			imageOut = sigImage - bkgImage;
			
			% Normalize by variance of background image stripes
			%imageOut = imageOut./repmat(nanvar(bkgImage,0,1),256,1);
			
			timeOut = 0;
			acquireTypeOut = 'image';
			referenceImagesBoolean = false;
			
			assignin('base','bkgImage',bkgImage);
			%figure(10);plot(1:size(bkgImage,2),bkgImage(100,:));
			
		end
		function [spectra,time] = getSpectra(this)
			[images,time] = this.getImages();
			specImage = -log(images./this.referenceImage);
			specImage(images./this.referenceImage < 0) = NaN;
			spectra = this.image2spectrumStatic(this.fringeX,this.fringeY,specImage,2);
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
   end
end