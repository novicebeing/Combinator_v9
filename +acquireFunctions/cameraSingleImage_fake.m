function [imageOut,timeOut,acquireTypeOut] = cameraSingleImage_fake()
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
end