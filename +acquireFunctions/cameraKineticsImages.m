function [imageOut,timeOut,acquireTypeOut,referenceImagesBoolean] = cameraKineticsImages()
    % Set the photolysis delay
    photolysisOffset = randsample([-50 -25 0 10 20 30 40 50 75 100 125 150 200 250 300 400 500 750 1000 1500 2000 2500 3000],1);
    timeBetweenImages = 4000;
    %warning('Not actually setting the photolysis delay')

    % Set photolysis delay
    % Create a GPIB object.
    obj1 = instrfind('Type', 'gpib', 'BoardIndex', 1, 'PrimaryAddress', 4, 'Tag', '');

    % Create the GPIB object if it does not exist
    % otherwise use the object that was found.
    if isempty(obj1)
        obj1 = gpib('NI', 1, 4);
    else
        fclose(obj1);
        obj1 = obj1(1);
    end

    % Connect to instrument object, obj1.
    fopen(obj1);
    
    % Set the photolysis delay
    % Communicating with instrument object, obj1.
    timeDelaySetting = 201e-6 + photolysisOffset*1e-6;
    fwrite(obj1, sprintf('DT 2,1,%f\r\n',timeDelaySetting));
    
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
    collectedImageArray = permute(double(reshape(collectedImageArray,CAM_width,CAM_height,numImages)),[2 1 3]);
    
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
    
%     Make some bkg image stats
%     bkgImageA = double(collectedImageArray(:,:,indBkg(1)));
%     bkgImageB = double(collectedImageArray(:,:,indBkg(2)));
%     bkgImageSubtract = bkgImageA - bkgImageB;
%     
%     vertStd = mean(std(bkgImageSubtract,[],2),1);
%     horizStd = mean(std(bkgImageSubtract,[],1),2);
%     fprintf('vert:%f,horiz:%f\n',vertStd,horizStd);
    
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
    %referenceImagesBoolean = false(size(indOut));
    timeOut = timeDelay;
    acquireTypeOut = 'image';
end