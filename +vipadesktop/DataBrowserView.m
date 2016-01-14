classdef DataBrowserView < toolpack.AbstractGraphicalComponent & toolpack.Container
    %DATABROWSERVIEW  Manages variable editor of the databrowser.
    %
    %   DATABROWSERVIEW tracks the number of open dialogs, and
    %   prevents openning multiple instances of a variable if it is aleady
    %   available.
    %
    %   DATABROWSERVIEW Methods:
    %      setDividerLocation      - repositions the divider of a split pane
    %      open                    - toggles on a toggle panel
    %      close                   - toggles off a toggle panel
    %      move                    - reorder a toggle panel
    %      reset                   - rebuild the view
    %
    %   You can also use methods inherited from
    %   toolpack.AbstractGraphicalComponent and toolpack.Container.
    %   See also DATABROWSERMODEL, ABSTRACTGRAPHICALCOMPONENT, CONTAINER.
    
    %   Author(s): Murad Abu-Khalaf , July 30, 2010
    %   Copyright 2010-2011 The MathWorks, Inc.
    
    %% ------ View CONSTRUCTION
    methods
        
        function this = DataBrowserView(tc)
            % DATABROWSERVIEW  The constructor of the graphical
            % component that manages a view of the client tool component
            % WorkspaceTableEditorTC.
            this = this@toolpack.AbstractGraphicalComponent(tc,350,500);
            this = this@toolpack.Container;
            vBuild(this);
            vUpdate(this);
        end
        
    end
    
    %% ------ PORTS CONSTRUCTION AND HANDLING
    methods (Access = protected)
        % Implementing processInportEvents
        function processInportEvents(this, src, evnt) %#ok<INUSD,MANU>
        end
    end
    
    %% Component's UI management
    methods (Access = protected)
        
        % Implementing vBuild
        function vBuild(this)
            % Construct UI and propagate GUI changes to clientTC component data.
            this.setPeer( javaObjectEDT('com.mathworks.toolbox.shared.controllib.databrowser.TCDataBrowser'));
        end
        
        % Implementing vUpdate
        function vUpdate(this, varargin)
            this.getPeer.reset;
            
            % Get underlying models from composite component
            m = this.getModel.getComponents;
            
            % Remove views, if any, that are invalid (deleted, etc...), to
            % make sure objects held here have assumed view methods.
            v = this.getComponents;
            for i=1:numel(v)
                view = v{i};
                if ~view.isvalid
                    this.remove(view);
                end
            end
            
            % Remove views that do not have a model peer. This must be here
            % to avoid name conflict when adding a GC that somehow has a
            % name similar to one held here that has no model peer.
            v = this.getComponents;
            for i=1:numel(v)
                view = v{i};
                if ~this.hasModel(view)
                    this.remove(view);
                end
            end
            
            % Create graphical components
            
            % Add the text filter first. Only one is allowed.
            for i=1:numel(m)
                model = m{i};
                if strcmp('toolpack.databrowser.FilterModel',class(model))
                    if ~this.hasView(model)
                        gc = toolpack.databrowser.FilterView(model);
                        this.add(gc);
                    end
                    gc = this.getView(model);
                    this.getPeer.setWorkspaceTextSearch(gc.getPeer);
                end
            end
            
            % Add WorkspaceView(s)
            for i=1:numel(m)
                model = m{i};
                if strcmp('toolpack.databrowser.BaseWorkspaceAdapter',class(model))
                    if ~this.hasView(model)
                        gc = toolpack.databrowser.WorkspaceView(model);
                        title = ctrlMsgUtils.message('Controllib:databrowser:BaseWS');
                        gc.setTitle(title);
                        this.add(gc);
                    end
                    gc = this.getView(model);
                    panel = gc.getPanel;
                    panel.setVisible(true);
                    this.getPeer.addPanel(gc.Name,gc.getTitle,panel);
                elseif strcmp('toolpack.databrowser.LocalWorkspaceModel',class(model)) || strcmp('vipadesktop.LocalWorkspaceModel',class(model))
                    if ~this.hasView(model)
                        gc = vipadesktop.WorkspaceView(model);%toolpack.databrowser.WorkspaceView(model);
                        title = ctrlMsgUtils.message('Controllib:databrowser:LocalWS');
                        gc.setTitle(title);
                        this.add(gc);
                    end
                    gc = this.getView(model);
                    panel = gc.getPanel;
                    panel.setVisible(true);
                    this.getPeer.addPanel(gc.Name,gc.getTitle,panel);
                elseif strcmp('toolpack.databrowser.SimulinkModelWorkspaceAdapter',class(m{i}))
                    if ~this.hasView(model)
                        gc = toolpack.databrowser.WorkspaceView(model);
                        gc.setTitle(model.getOwnerName);
                        this.add(gc);
                    end
                    gc = this.getView(model);
                    panel = gc.getPanel;
                    panel.setVisible(true);
                    this.getPeer.addPanel(gc.Name,gc.getTitle,panel);                
                end
            end
            
            % Add Variable Preview displays            
            for i=1:numel(m)
                model = m{i};
                if strcmp('toolpack.databrowser.DisplayModel',class(m{i}))
                    if ~this.hasView(model)
                        gc = toolpack.databrowser.DisplayView(model);
                        gc.Name = model.Name;
                        title = ctrlMsgUtils.message('Controllib:databrowser:VariablePreview');
                        gc.setTitle(title);
                        this.add(gc);
                    end
                    gc = this.getView(model);
                    panel = gc.getPanel;
                    panel.setVisible(true);
                    this.getPeer.addPanel(gc.Name,gc.getTitle,panel);
                end
            end            
            
            % Wire graphical components as follows by doing the following
            % for each WorkspaceView:
            %
            % - WorkspaceView Inport is connected to the Outport of each
            %   FilterView.
            %
            % - WorkspaceView Outport is connected to the Inport of each
            % DisplayView.
            
            fltviews = this.getComponentsOfClass('toolpack.databrowser.FilterView');
            wksviews = this.getComponentsOfClass('toolpack.databrowser.WorkspaceView');
            dispviews = this.getComponentsOfClass('toolpack.databrowser.DisplayView');
            
            for i=1:numel(wksviews)
                src = [wksviews{i}.Name '/1'];
                for j = 1:numel(dispviews)
                    dest = [dispviews{j}.Name '/1'];
                    this.connect(src,dest);
                end
            end
            
            for i=1:numel(fltviews)
                src = [fltviews{i}.Name '/1'];
                for j = 1:numel(wksviews)
                    dest = [wksviews{j}.Name '/1'];
                    this.connect(src,dest);
                end
            end
            
        end
        
        % Implementing removePanelFromParent
        function removePanelFromParent(this)
            if ~isempty(this.getPeer)
                this.getPeer.removePanelFromParent;
            end
        end
    end
    
    methods (Access = public)
        
        function setDividerLocation(this,idx, percentage)
            % SETDIVIDERLOCATION  Repositions the divider of a split pane.
            %
            %   SETDIVIDERLOCATION(OBJ,IDX,RATIO) repositions the divider
            %   of index IDX such that the upper pane is shown according to
            %   the ratio RATIO [0, 1]. The index IDX is 1-based.
            %
            %   Each divider has a top pane and a lower pane. The top pane
            %   is the immediately upper pane, while the lower pane
            %   includes everything below it including those that has other
            %   dividers.
            %
            %   See also MOVE.
            this.getPeer.setDividerLocation(idx-1,percentage);
        end
        
        function open(this,name)
            % OPEN  Toggles on a toggle panel.
            %
            %   OPEN(OBJ,NAME) opens the panel provided its name NAME.
            %
            %   See also CLOSE.
            
            this.getPeer.open(name);
        end
        
        function close(this,name)
            % CLOSE  Toggles off a toggle panel.
            %
            %   CLOSE(OBJ,NAME) closes the panel provided its name NAME.
            %
            %   See also OPEN.
            
            this.getPeer.close(name);
        end
        
        function move(this, srcidx, dstidx)
            % MOVE  Reorder a toggle panel.
            %
            %   MOVE(OBJ,SRCIDX,DSTIDX) removes the panel at SRCIDX from
            %   its position, and add it at DSTIDX. All indices are MATLAB
            %   1-based.
            %
            %   See also SETDIVIDERLOCATION.
            
            this.getPeer.move(srcidx-1,dstidx-1);
        end
        
        function reset(this)
            % RESET  Rebuilds the Data Browser view.
            %
            %   RESET(OBJ) will ignore previous MOVE and
            %   setDividerLocation commands. This method will make sure
            %   that the text filter is on top, workspace views are in the
            %   middle, and at the end is the variable preview pane.
            %
            %   See also SETDIVIDERLOCATION, MOVE.
            
            this.vUpdate;
        end
        
    end
    
    methods (Access = private)
        function r = getComponentsOfClass(this,aclass)
            classes  = cellfun(@class , this.Components_,'UniformOutput',false);
            idx = strcmp(aclass,classes);
            r = this.Components_(idx);
        end
        function r = hasView(this,model)
            equals = cellfun(@(c) eq(model,c.getModel), this.Components_,'UniformOutput',true);
            r = any(equals);
        end
        function r = hasModel(this,view)
            models = this.getModel.getComponents;
            equals = cellfun(@(c) eq(view.getModel,c), models,'UniformOutput',true);
            r = any(equals);
        end
        function r = getView(this,model)
            equals = cellfun(@(c) eq(model,c.getModel), this.Components_,'UniformOutput',true);
            r = this.Components_{equals};
        end
    end
end