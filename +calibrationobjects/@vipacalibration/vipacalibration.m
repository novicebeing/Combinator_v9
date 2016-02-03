classdef vipacalibration < handle
    % X Axis Calibration Class
    
    properties
        name = '';
        
        % Calibration Status
        fringesCalibrated = false;
        xaxisCalibrated = false;
        yaxisCalibrated = false;
        
        % Image Specific Parameters
        imageDimensions;
        
        % Fringe Parameters
        fringeImage;
        fringeX;
        fringeY;
        fringeImageSize;
        spectrumIndcs;
        
        % X and Y axis calibration
        refImage;
        sigImage;
        calibrationSpectrum;
        
        % X Axis Calibration
        xAxis_wavenumber;
        
        % Y Axis Calibration
        yAxis_pathlength;
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

