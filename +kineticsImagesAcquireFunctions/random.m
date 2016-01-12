function [images,time] = random()
    images = rand(256,320,15);
    time = (0:14)*4000;
end