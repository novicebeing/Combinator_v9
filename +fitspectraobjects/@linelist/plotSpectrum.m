function h = plotSpectrum(obj,wavenum,varargin)
    figure;
    plot(wavenum,obj.createSpectrum(wavenum,varargin{:}))
end