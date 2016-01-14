classdef DataBrowserModel < toolpack.AbstractCompositeComponent
    %DATABROWSERMODEL  A composite component providing a data browser model.
    %
    %   DATABROWSERMODEL by default holds models for the Base workspace and
    %   a local workspace. It also holds a variable preview model, as well
    %   as a text filter. You can use the methods inherited from the parent
    %   class toolpack.AbstractCompositeComponent.
    %
    %   See also DATABROWSERVIEW, ABSTRACTCOMPOSITECOMPONENT.
    
    %   Author(s): Murad Abu-Khalaf , July 30, 2010
    %   Copyright 2010-2011 The MathWorks, Inc.
    
    
    %% ------ MODEL CONSTRUCTION
    methods (Access = public)
        
        % Constructor
        function this = DataBrowserModel(varargin)
            
            % Call parent class constructor
            this = this@toolpack.AbstractCompositeComponent(varargin{:});
            
            output(this);
        end
        
    end
    
    
    %% ------ SERILIZATION
    methods
        
        % Overriding saveobj
        function S = saveobj(obj)
            S = saveobj@toolpack.AbstractCompositeComponent(obj);
            
            % Anything extra to save comes here
            % S.foo = obj.bar
        end
        
        % Overriding reload
        function obj = reload(obj, S)
            obj = reload@toolpack.AbstractCompositeComponent(obj, S);
            
            % Anything extra to reload comes here
            % obj.bar = S.foo
        end
        
    end
    
    methods (Static)
        
        function obj = loadobj(S)
            % Call constructor
            obj = toolpack.databrowser.DataBrowserModel;
            obj = reload(obj, S);
        end
        
    end
    
    %% ------ PORTS CONSTRUCTION AND HANDLING
    methods (Access = protected)
        % Implementing processInportEvents
        function processInportEvents(this, src, evnt) %#ok<INUSD,MANU>
        end
    end
    
    %% ------ STATES
    methods (Access = protected)
        
        % Implementing preAddTasks
        function preAddTasks(this, child)
            AllowComponents = {...
                'toolpack.databrowser.FilterModel',...
                'toolpack.databrowser.BaseWorkspaceAdapter',...
                'toolpack.databrowser.LocalWorkspaceModel',...
                'toolpack.databrowser.DisplayModel',...
                'toolpack.databrowser.SimulinkModelWorkspaceAdapter',...
                'vipadesktop.FilterModel',...
                'vipadesktop.BaseWorkspaceAdapter',...
                'vipadesktop.LocalWorkspaceModel',...
                'vipadesktop.DisplayModel',...
                'vipadesktop.SimulinkModelWorkspaceAdapter'};
            if ~strcmp(class(child),AllowComponents)
                ctrlMsgUtils.error('Controllib:databrowser:ComponentNotAllowed', class(this),class(child))
            end
        end
        
        % Implementing postAddTasks
        function postAddTasks(this, child)             %#ok<INUSD,MANU>
            
        end
        
        % Implementing preResetChildrenTasks
        function preResetChildrenTasks(this)
            this.Components_ = {};
            this.Connectors_ = {};
            this.Initialized = true;
        end
        
        % Implementing postResetChildrenTasks
        function postResetChildrenTasks(this)
            tc0 = toolpack.databrowser.FilterModel;
            tc0.Name = 'filter';
            
            tc1 = toolpack.databrowser.BaseWorkspaceAdapter;
            tc1.Name = 'base';
            
            tc2 = toolpack.databrowser.LocalWorkspaceModel;
            tc2.Name = 'local';
            
            tc3 = toolpack.databrowser.DisplayModel;
            tc3.Name = 'preview';
            
            this.add(tc0);
            this.add(tc1);
            this.add(tc2);
            this.add(tc3);
        end
        
        % Implementing preUpdateChildrenTasks
        function preUpdateChildrenTasks(this) %#ok<MANU>
        end
        
        % Implementing postUpdateChildrenTasks
        function  postUpdateChildrenTasks(this) %#ok<MANU>
        end
        
        % Implementing preOutputChildrenTasks
        function preOutputChildrenTasks(this) %#ok<MANU>
        end
        
        % Implementing postOutputChildrenTasks
        function postOutputChildrenTasks(this) %#ok<MANU>
        end        
        
    end
    
end