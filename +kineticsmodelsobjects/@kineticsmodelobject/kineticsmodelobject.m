classdef kineticsmodelobject < handle
    %kineticsobject
    
    properties
        name;
        
		t = [];
		moleculeNames = {};
        concentrations = [];
        
		initialConditionsTable = [];
		
		fitVariableNames = {};
		fitVariableType = {};
		fitStartingPoint = [];
		fitFunction;
		fitFunctionOutputs = {};
		
		fitb = [];
		fitbError = [];
    end
    properties (Transient = true)
        % Live Image Views
        plotHandles;
    end
    methods
        function obj = kineticsmodelobject(varargin)
        end
        function delete(obj)
            % Remove deleted plot handles
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            
            for i = 1:numel(obj.plotHandles)
                delete(obj.plotHandles{i});
            end
        end
        function updatePlots(obj)
            % Remove deleted plot handles
            if ~isempty(obj.plotHandles)
                obj.plotHandles = obj.plotHandles(cellfun(@isvalid,obj.plotHandles)); % Clean up the plot handles
            else
                obj.plotHandles = {};
            end
            
            for i = 1:numel(obj.plotHandles)
                obj.plotHandles{i}.Update();
            end
        end
		function bfit = performfit(obj)
			tindcs = find(obj.t <= 60);
		
			% Construct the data array
			data = [obj.concentrations(1,tindcs) obj.concentrations(2,tindcs)]/1e15;
			f = @(b) obj.fitFunction(b,obj.t(tindcs))-data;

            lb = [-inf 0 0 0 0];
            ub = [inf inf inf inf inf];
            b0 = [1    0.005    0.01    0.001 0.5];
            options = optimoptions(@lsqnonlin,'Algorithm','trust-region-reflective');
            options.TolFun = 1e-7;
			bfit = lsqnonlin(f,b0,lb,ub,options);
			
			obj.fitb = bfit;
		end
		function plot(obj)
			teval = linspace(min(obj.t),max(obj.t),50000);
			fitData = reshape(obj.fitFunction(obj.fitb,teval),numel(teval),[]);
		
			hf = figure;
			for i = 1:2%size(obj.concentrations,1)
				plot(obj.t,obj.concentrations(i,:),'x'); hold on;
				plot(teval,fitData(:,i)*1e15);
			end
		end
    end
end

