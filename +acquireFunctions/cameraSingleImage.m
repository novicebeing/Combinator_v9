function [imageOut,timeOut,acquireTypeOut] = cameraSingleImage()
    imageOut = rand(256,320);
    timeOut = 0;
    acquireTypeOut = 'image';
end