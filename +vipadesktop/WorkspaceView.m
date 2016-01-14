classdef WorkspaceView < toolpack.AbstractGraphicalComponent & JavaVisible
    %WORKSPACEVIEW  Creates and manages the view for workspace table.
    %
    %   WORKSPACEVIEW(TC) takes the workspace model TC as input, and
    %   creates a graphical component that displays the workspace variables
    %   in a tabular form.
    %
    %   WORKSPACEVIEW Methods:
    %      openvar                 - opens a variable editor dialog
    %      hilite                  - highlights the provided workspace variable
    %      showColumn              - shows a workspace table column
    %      hideColumn              - hides a workspace table column
    %      setTitle                - sets a title for the workspace view
    %
    %   See also LocalWorkspaceModel.
    
    %   Author(s): Murad Abu-Khalaf , July 30, 2010
    %   Revised:
    %   Copyright 2010-2014 The MathWorks, Inc.
    
    % Properties
    properties (Access = private)
        filterPattern
        fNoSelectionPopupMenu
        fSelectionPopupMenu
    end
    
    %% ------ VIEW CONSTRUCTION
    methods
        
        function this = WorkspaceView(tc)
            % WORKSPACEVIEW  The constructor of the graphical component
            % that provides workspace functionalities.
            
            this = this@toolpack.AbstractGraphicalComponent(tc,350,500);
            
            % Add Inports/Outports
            this.addInport('1');  % View Filter Pattern
            this.addOutport('1'); % Text for selected entries
            
            vBuild(this);
            vUpdate(this);
        end
        
        function delete(this)
            % WorkspaceView deletes objects it creates
            
            % Check if objects have already been deleted
            if isvalid(this.fNoSelectionPopupMenu)
                delete(this.fNoSelectionPopupMenu);
            end
            if isvalid(this.fSelectionPopupMenu)
                delete(this.fSelectionPopupMenu);
            end
            
            % NOTE: The ISVALID check is needed. Otherwise, if handles are
            % all available at the command line, and a clear is executed.
            % MATLAB marks all three objects for deletion, but may not
            % start by deleting WorkspaceView first. This results in
            % multiple calls to the deletion of PopupMenu objects.
        end
        
    end
    
    %% ------ PORTS CONSTRUCTION AND HANDLING
    methods (Access = protected)
        % Implementing processInportEvents
        function processInportEvents(this, src, evnt)  %#ok<INUSL>
            this.filterPattern = evnt.PortData;
            vUpdate(this);
        end
    end
    
    %% Component's UI management
    methods (Access = protected)
        
        % Implementing vBuild
        function vBuild(this)
            % Construct UI and propagate GUI changes to clientTC component data.
            this.setPeer( javaObjectEDT('com.mathworks.toolbox.shared.controllib.databrowser.TCWorkspaceTable') );
            
            % Construct NoSelectionPopupMenu
            this.fNoSelectionPopupMenu = toolpack.databrowser.NoSelectionPopupMenu(this.getPeer.getNoSelectionPopupMenu,this);
            
            % Construct SelectionPopupMenu
            this.fSelectionPopupMenu = toolpack.databrowser.SelectionPopupMenu(this.getPeer.getSelectionPopupMenu,this);
            
            % MCOS-FORUM: While it is not currently documented, MCOS does
            % support the Java Bean interface using the UDDObject
            % interface.  On the MATLAB side, the MCOS class must inherit
            % from JavaVisible, which gives it the java method. Calling the
            % java method will create a Java bean. In order to use this
            % interface, the class must also be a handle object.
            javaMethodEDT('setMATLABPeer',this.getPeer,this.java);
            
            % Attach listeners to the Java peer
            cb = this.getPeer.getTCWorkspaceModel.getEventsToMATLAB;
            addGUIListener( this, cb, {@ModelUpdate,this} ); % Register a listener to the Java GUI and store it in a property.
            
            % Attach listeners to the Java peer
            cb = this.getPeer.getTransferEventsToMATLAB;
            addGUIListener( this, cb, {@TransferEventsProcessing,this} ); % Register a listener to the Java GUI and store it in a property.
            
            % Attach listeners to the Java peer
            cb = this.getPeer.getVariableSelectionEventsToMATLAB;
            addGUIListener( this, cb, {@VariableSelectionProcess,this} ); % Register a listener to the Java GUI and store it in a property.
            
        end
        
        % Implementing vUpdate
        function vUpdate(this, varargin)
            % Update Java GUI with changes made to the model
            if ischar(this.filterPattern)
                data = this.getModel.whos('-regexp',this.filterPattern);
            else
                data = this.getModel.whos;
            end
            % Push filtered data to the View
            varValues = cell(1,numel(data));
            for i=1:numel(data)
                varValues{i} = this.getModel.evalin(data(i).name);
            end
            javaMethodEDT('setTCWhosInformation',...
                this.getPeer.getTCWorkspaceModel,...
                getTCWhosInformation(data,varValues));
        end
        
        % Implementing removePanelFromParent
        function removePanelFromParent(this)
            if ~isempty(this.getPeer)
                this.getPeer.removePanelFromParent;
            end
        end
    end
    
    methods (Access = public)
        
        function openvar(this, varname)
            % OPENVAR  Open workspace variable in tool for graphical editing.
            %
            %   OPENVAR(OBJ,VARNAMES) Open workspace variable in tool for
            %   graphical editing, with VARNAME a variable name. After
            %   editing, the edited value of the workspace variable is
            %   stored back in the LocalWorkspaceModel object OBJ.
            %
            %   See also HILITE.
            
            model = getModel(this);
            val = evalin(model,varname);
            invoker = this;
            
            handled = false;
            try
                openVariableEditor(val,model,varname,invoker);
                handled = true;
            catch E  %#ok<NASGU>
                try
                    if (isa(val, 'handle') || isa(val, 'opaque'))
                        inspect(val);
                        handled = true;
                    end
                catch E2 %#ok<NASGU>
                    % At this point, handled must be false
                end
            end
            
            if ~handled
                toolpack.databrowser.VariableEditorManager.getInstance.openDialog(this.getModel,varname,invoker)
            end
            
        end
        
        function hilite(this, varname)
            % HILITE  Highlights the provided workspace variable.
            %
            %   HILITE(OBJ,VARNAME) highlights the workspace variable
            %   VARNAME.
            %
            %   See also OPENVAR.
            
             this.getPeer.hilite(varname);
        end
        
        function showColumn(this, name)
            % SHOWCOLUMN  Shows a workspace table column.
            %
            %   SHOWCOLUMN(OBJ,COLNAME) shows the column identified by
            %   COLNAME. COLNAME is a string that can be CLASS, SIZE,
            %   or BYTES only.            
            %
            %   See also HIDECOLUMN.
            this.getPeer.showColumn(name);
        end
        
        function hideColumn(this, name)
            % HIDECOLUMN  Hides a workspace table column.
            %
            %   HIDECOLUMN(OBJ,COLNAME) hides the column identified by
            %   COLNAME. COLNAME is a string that can be CLASS, SIZE,
            %   or BYTES only.            
            %
            %   See also SHOWCOLUMN.
            this.getPeer.hideColumn(name);
        end
        
        function setTitle(this, title)
            % SETTITLE  Sets a title for the workspace view that could be
            % used by parent containers.
            %
            %   SETTITLE(OBJ,TITLE) sets the title to the string TITLE.
            %   This is utilized by the container. Note that the container
            %   does not listen to this change. For example, a
            %   DatabrowserView will have to be reset so that the title is
            %   used by the relevant toggle panel.
            %
            %   See also DATABROWSERVIEW.
            setTitle@toolpack.AbstractGraphicalComponent(this,title);
            this.getPeer.setTitle(title);
        end
        
        function r = getNoSelectionPopupMenu(this)
            % GETNOSELECTIONPOPUPMENU  Returns a handle to the NoSelectionPopupMenu.
            %
            %   GETNOSELECTIONPOPUPMENU(OBJ) returns a handle to the
            %   NoSelectionPopupMenu.
            %
            %   See also NOSELECTIONPOPUPMENU.
            
            r = this.fNoSelectionPopupMenu;
        end
        
        function r = getSelectionPopupMenu(this)
            % GETSELECTIONPOPUPMENU  Returns a handle to the SelectionPopupMenu.
            %
            %   GETSELECTIONPOPUPMENU(OBJ) returns a handle to the
            %   NoSelectionPopupMenu.
            %
            %   See also SELECTIONPOPUPMENU.
            
            r = this.fSelectionPopupMenu;
        end
        
    end
    
end

%% ------ Local functions
function ModelUpdate(source,data,varargin) %#ok<INUSL>
% Update the workspace model in response to changes in the view.
gc = varargin{1};
ws = gc.getModel;
action = char(data.action);
actionInfo = cell(data.actionInfo);
try
    switch upper(action)
        case 'DELETE'
            ws.clear(actionInfo{:});
        case 'RENAME'
            % This get called after adding a new variable?
            ws.rename(actionInfo{1},actionInfo{2});
        case 'CREATE'
            varname = workspacefunc('getnewname',ws.who);
            createfunction = ws.NewVariableFunction;
            ws.assignin(varname,createfunction());
        case 'DUPLICATE'
            ws.duplicate(actionInfo{:});
        case 'REFRESH'
            ws.update;
        case 'OPEN'
            if ~isempty(actionInfo)
                gc.openvar(actionInfo{1});
            end
    end
catch E
    msgbox(E.message,ctrlMsgUtils.message('Controllib:databrowser:ComponentError','Workspace',upper(action)),'warn','modal');
end
end

function TransferEventsProcessing(source,data,varargin) %#ok<INUSL>
targetGC = varargin{1};
targetTC = targetGC.getModel;
% If the object passed in is a UDDObject, it's already been
% converted to a handle and we need to grab the underlying
% object. Calling handle with no args will do that.
% if isa(obj,'com.mathworks.jmi.bean.UDDObject')
%     obj = handle(obj);
% end
try
    sourceGC = handle(data.graphicalcomponent);
    sourceTC = sourceGC.getModel;
catch E %#ok<NASGU>
    % DO NOTHING IF GC/MODEL ARE MISSING UPON PASTING
    return;
end

varNames = cell(data.selected_variables);

if eq(sourceGC,targetGC)
    if strcmp(data.action,'PASTE')
        targetGC.getModel.duplicate(varNames{:});
        return;
    else
        % This is a Drop. Ignore copying when dropping on the same table.
        return;
    end
end

% Return is names are empty. This is robust against Drops that has no
% names. Could happen if Ctrl key is pressed and clicking on a variable
% already selected, which will deselect it, and hence the drop info has no
% names, but a UDD object. (Similar protection is added in JAVA)
if isempty(varNames)
    return;
end

n = numel(varNames);
arg = {};
for i=1:n
    varname = varNames{i};
    try
        value = evalin(sourceTC,varname);
        arg = [arg {varname,value}]; %#ok<AGROW>
    catch E %#ok<NASGU>
        % varname may have been deleted from source workspace.
        continue;
    end
end

% Return if nothing got evaluated.
if isempty(arg)
    return;
end

% Assign data in the target workspace
targetTC.assignin(arg{:});

% REVISE: DO not clear if move is not successful.
if strcmp(data.action,'MOVE')
    sourceTC.clear(varNames{:});
end

end

function VariableSelectionProcess(source,data,varargin) %#ok<INUSL>
gc = varargin{1};
if ischar(data)
    varNames = {data};
else
    varNames = cell(data);
end
value = gc.getModel.evalin(varNames{1});
name = varNames{1};
try
    str = displayShort(value);
    gc.writeToOutport('1',str);
catch E %#ok<NASGU>
    try
        str = getDisplayString(name,value);
        gc.writeToOutport('1',str);
    catch E %#ok<NASGU>
    end
end
end

function out = getTCWhosInformation(in,vars)
if numel(in) == 0
    out = com.mathworks.toolbox.shared.controllib.databrowser.TCWhosInformation;
else
    s = size(in);
    siz = cell(s);
    val = cell(s);
    for i = 1:length(in)
        siz{i} = int64(in(i).size);
        v = workspacefunc('getshortvalueobjectswithevalj',{'vars{i}'});
        val{i} = v(1);
    end
    inname = {in.name};
    inbytes = [in.bytes];
    inclass = {in.class};
    insparse = [in.sparse];
    incomplex = [in.complex];
    out = com.mathworks.toolbox.shared.controllib.databrowser.TCWhosInformation(...
        inname,siz, inbytes, inclass, insparse, incomplex, val);
end
end

function r = getDisplayString(name,value) %#ok<INUSD>
% This method is used because a new variable is created called name. We do
% not want this name to class with say 'gc' in the VariableSelectionProcess
% workspace, and then loose the handle to the graphical component.
r = evalc([name '= value']);
end