classdef linelist < handle
    % Line List Class
    
    properties
        name = '';
        
        % Line List Parameters
        lineposition;
        linestrength;
    end
    methods (Static)
        areaNormGaussian;
        areaNormLorentzian;
        areaNormPseudoVoigt;
        areaNormVoigt;
    end
    methods
        function obj = linelist(varargin)
            
        end
    end
end

