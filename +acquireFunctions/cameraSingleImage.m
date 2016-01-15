function [imageOut,timeOut,acquireTypeOut,referenceImagesBoolean] = cameraSingleImage()
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
    timeOut = 0;
    acquireTypeOut = 'image';
    referenceImagesBoolean = false;
end