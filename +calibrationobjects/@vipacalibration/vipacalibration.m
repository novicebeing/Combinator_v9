classdef vipacalibration < handle
    % X Axis Calibration Class
    
    properties
        name = '';
        
        % Image Specific Parameters
        imageDimensions;
        
        % Fringe Parameters
        fringeImage;
        fringeX;
        fringeY;
        fringeImageSize;
    end
    methods
        function obj = vipacalibration(varargin)
            
        end
        function h = displayFringes()
            % Not implemented yet
            error('Not implemented yet');
        end
        function [spectra,wavenumber] = spectraFromImages(images)
            % Not implemented yet
            error('Not implemented yet');
        end
    end
end

