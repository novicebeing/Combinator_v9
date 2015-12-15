classdef VIPAdataBrowser < handle
    %PLANTLISTBROWSER
    
    % Author(s): Baljeet Singh 05-Sep-2013
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        Model
        View
        LocalWorkspace
        LocalWorkspaceView
    end
    events
        ComponentRequest
    end
    methods
        function obj = VIPAdataBrowser()
            %PLANTLISTBROWSER
            
            obj.Model = toolpack.databrowser.DataBrowserModel;
            obj.Model.remove('base');
            obj.Model.remove('filter');
            obj.Model.remove('preview');
            obj.View = toolpack.databrowser.DataBrowserView(obj.Model);
            setTitle(getComponent(obj.View,'local'),pidtool.utPIDgetStrings('cst','strPlantList'));
            reset(obj.View);
            obj.LocalWorkspace = obj.Model.getComponent('local');
            obj.LocalWorkspaceView = obj.View.getComponent('local');
            selectionPopupMenu = obj.LocalWorkspaceView.getSelectionPopupMenu;
            nonselectionPopupMenu = obj.LocalWorkspaceView.getNoSelectionPopupMenu;
            WarningState = warning('off','MATLAB:Containers:Map:NoKeyToRemove');
            selectionPopupMenu.removeMenuItem('RecordCopyingMenuItem');
            s.Text = pidtool.utPIDgetStrings('cst','strExport');
            s.Name = 'exportplant';
            s.Callback = @(x)localExportPlantCb(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,1);
            s.Text = pidtool.utPIDgetStrings('cst','strSelectForTuning');
            s.Name = 'selectplant';
            s.Callback = @(x)localSelectPlantCb(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,2);
            nonselectionPopupMenu.removeMenuItem('RecordCreationMenuItem');
            nonselectionPopupMenu.removeMenuItem('PasteMenuItem');
            warning(WarningState);
            showColumn(obj.LocalWorkspaceView,'Value');
            hideColumn(obj.LocalWorkspaceView,'Class');
            hideColumn(obj.LocalWorkspaceView,'Size');
            hideColumn(obj.LocalWorkspaceView,'Bytes');
        end
    end
end

function localExportPlantCb(obj,src)
notify(obj,'ComponentRequest',pidtool.desktop.pidtuner.tc.PlantListBrowserEventData('export',src.Variables));
end
function localSelectPlantCb(obj,src)
notify(obj,'ComponentRequest',pidtool.desktop.pidtuner.tc.PlantListBrowserEventData('select',src.Variables));
end