function [imageOut,timeOut,acquireTypeOut] = random()
    imageOut = rand(256,320);
    timeOut = 0;
    acquireTypeOut = 'image';
end