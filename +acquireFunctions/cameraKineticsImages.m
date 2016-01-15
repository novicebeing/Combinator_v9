function [imageOut,timeOut,acquireTypeOut,referenceImagesBoolean] = cameraKineticsImages()
    % Set the photolysis delay
    photolysisOffset = 0;
    timeBetweenImages = 4000;
    warning('Not actually setting the photolysis delay')

    % Start Acquisition thread
    CAM_width = 320;
    CAM_height = 256;
    numImages = 75;
    [~,~] = pleoraAcquireFunctions.pleora_acquireMultipleImagesPersistent_v3(uint16(CAM_width),uint16(CAM_height),uint16(numImages));
    pause(1);
    
    % Get the images
    [collectedImageArray,timestampOut] = pleoraAcquireFunctions.pleora_acquireMultipleImagesPersistent_v3();
    timestamp = double(timestampOut).*480e-6/4;
    
    % Convert spectra to double
    collectedImageArray = double(reshape(collectedImageArray,CAM_width,CAM_height,numImages));
    
    % Initialize timestamp label array
    timestampLabel = NaN*ones(size(timestamp));
    
    % Find Reference Image Indices
    indRef = find(abs(diff(timestamp)-7) < 0.1)+1;
    indBkg = find(abs(diff(timestamp)-3) < 0.1)+1;
    indSig = find(abs(diff(timestamp)-1) < 0.1)+1;

    % Label the background images
    timestampLabel(indBkg) = -10;
    
    % Construct an average background image
    bkgImage = mean(double(collectedImageArray(:,:,indBkg)),3);
    
    % Find the bad pixels in the background image
    badPixelIndcs = find(double(bkgImage)<0.75*mean(bkgImage(:)) | double(bkgImage)>1.5*mean(bkgImage(:)));
    
    % Find all of the signal and reference images
    for i = 1:numel(indRef)
        if indRef(i) < numel(timestamp)
            maxIndex = min([indRef(i)+15 numel(timestamp)]);
            timeDifference = diff(timestamp(indRef(i):maxIndex));
            if max(abs((timeDifference-1))) < 0.1
                timestampLabel(indRef(i):maxIndex) = -1:(maxIndex-indRef(i)-1);
            end
        end
    end
    
    % Find the reference for each signal image
    refIndex = zeros(size(timestampLabel));
    lastRef = NaN;
    for i = 1:numel(timestampLabel)
        if timestampLabel(i) == -1
            lastRef = i;
            refIndex(i) = NaN;
        elseif timestampLabel(i)>=0
            refIndex(i) = lastRef;
        else
            refIndex(i) = NaN;
        end
    end
    
    % Construct output
    indOut = find(timestampLabel>=-1 & ~isnan(timestampLabel));
    timeDelay = timestampLabel(indOut)*timeBetweenImages + photolysisOffset; % In microseconds
    
    % Construct image output
    imageOut = zeros([size(collectedImageArray,1) size(collectedImageArray,2) numel(indOut)]);
    for i = 1:numel(indOut)
        A = double(collectedImageArray(:,:,indOut(i)))-double(bkgImage);
        A(badPixelIndcs) = NaN;
        imageOut(:,:,i) = A;
    end
    
    referenceImagesBoolean = (timestampLabel(indOut) == -1);
    timeOut = timeDelay;
    acquireTypeOut = 'image';
end