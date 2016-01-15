function [imageOut,timeOut,acquireTypeOut,referenceImagesBoolean] = random()
    imageOut = rand(256,320);
    timeOut = 0;
    acquireTypeOut = 'image';
    referenceImagesBoolean = false;
end