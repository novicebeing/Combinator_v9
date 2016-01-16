function [imageOut,timeOut,acquireTypeOut,referenceImagesBoolean] = cameraKineticsImages_fake()
    load vipaImagesForBen.mat
    
    % Set the image offset
    photolysisOffset = randsample([0:20:100 500 1000 1500 2000 3000],1);
    
    % Get bkg Image
    bkgImage = double(acqImages(:,:,1));

    % Find the indices of the bad pixels
    badPixelIndcs = find(double(bkgImage)<0.75*mean(bkgImage(:)) | double(bkgImage)>1.5*mean(bkgImage(:)));
    
    testImages = double(acqImages(:,:,2:15))-repmat(bkgImage,1,1,numel(2:15));
    for i = 1:size(testImages,3)
        testImages(badPixelIndcs+size(testImages,1)*size(testImages,2)*(i-1)) = NaN;
    end
    imageOut = permute(testImages + 1000*rand(size(testImages)),[2 1 3]);
    timeOut = (-1:12)*4000 + photolysisOffset;
    acquireTypeOut = 'image';
    referenceImagesBoolean = logical([1 0 0 0 0 0 0 0 0 0 0 0 0 0]);
end