classdef ratesgraph < handle
    % Line Profile Browser Class
    properties
        % Parent imagesobject
        Parent
        
        % Variables
        simbioModel
        ratesMatrix
        
        % Handles
        biographObject
        sliderFigureObject
    end
    
    methods
        function this = ratesgraph(simbioModel,ratesMatrix)
            
            this.simbioModel = simbioModel;
            this.ratesMatrix = ratesMatrix;
            
            this.ratesPlot(1);
            
            % Figure Close Function
            function figCloseFunction(src,callbackdata)
                delete(gcf);
                delete(this);
            end
        end
        function delete(obj)
            % Remove figure handles
            delete(obj.biographObject);
        end
        function Update(this)
            % Save the previous value
            oldSliderValue = round(get(this.sliderHandle,'Value'));
            oldSliderMax = this.sliderHandle.Max;

            % Reset the slider bounds
            newSliderMax = numel(this.Parent.tavg);
            if newSliderMax == 0
                newSliderMax = 1;
            end
            if oldSliderMax == oldSliderValue || oldSliderValue > newSliderMax
                newSliderValue = newSliderMax;
            else
                newSliderValue = oldSliderValue;
            end

            % Apply the slider bounds
            this.sliderHandle.Value = newSliderValue;
            this.sliderHandle.Max = newSliderMax;
            this.sliderHandle.SliderStep = [1/newSliderMax 10/newSliderMax];

            % Hide the slider if necessary
            if newSliderMax == 1
                this.sliderHandle.Visible = 'off';
            else
                this.sliderHandle.Visible = 'on';
            end

            this.updateImagePlot();
        end
        
        % Internal Functions
        function ratesPlot(this,idx)
            sm = getstoichmatrix(this.simbioModel);
            vsection = repmat(this.ratesMatrix(idx,:),size(sm,1),1);
            vsection = abs(vsection);
            vsection(abs(vsection)<1e8) = 0;
            vsection(vsection>0) = round(log10(vsection(vsection>0)));
            cm = -(sm.*(sm<0).*sqrt(vsection))*(sm.*(sm>0).*sqrt(vsection))';
            cm((1:size(cm,1))+((1:size(cm,1))-1)*size(cm,1))=0;
            size(cm)
            
            %weights = 
            %cm = [0 1 1 0 0;1 0 0 1 1;1 0 0 0 0;0 0 0 0 1;1 0 1 0 0];
            %ids = {'M30931','L07625','K03454','M27323','M15390'};
            ids = get(this.simbioModel.Species,'Name');
            size(ids)
            nullindex = [];
            for i = 1:numel(ids)
                if strcmp(ids{i},'CO') ||...
                    strcmp(ids{i},'H2') || ...
                    strcmp(ids{i},'O3')
                    nullindex(end+1) = i;
                end
            end
            for i = 1:numel(nullindex)
                cm(nullindex(i),:) = 0;
                cm(:,nullindex(i)) = 0;
            end
            
            
            bgHandle = biograph(cm,ids,'ShowWeights','on');
            for i = 1:numel(bgHandle.Nodes)
                bgHandle.Nodes(i).Color = [1 1 1];
                bgHandle.Nodes(i).LineColor = [1 1 1];
            end
            this.biographObject = view(bgHandle);
        end
        function updateRatesPlot(this)
            this.biographObject.Edges(1).LineWidth = 9*rand+1;
        end
    end
end