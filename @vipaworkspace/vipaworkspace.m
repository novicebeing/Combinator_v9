classdef vipaworkspace < handle
    %PIDTOOLDESKTOP
    
    % Author(s): Baljeet Singh 20-Nov-2013
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        TPComponent
        TPComponent2
        PlantListBrowser
        PlantList
        PIDTuner
        SimulinkGateway
        PlantIdentifier
        OpenLoopRelinearizer
        ClosedLoopRelinearizer
        DataBrowser
        SpectraList
        SpectraList2
        TC
        TabGC
        hometab
    end
    properties (SetAccess = private)
        Type = 'MATLAB'
        StatusBar
    end
    properties(Access = private)
        Listeners
        GroupName
        MD
    end
    
    methods
        function this = vipaworkspace(varargin)
            %PIDTOOLDESKTOP
            %====================================================================================================(Plant List)
            this.SpectraList = vipadesktop.SpectraList();
            this.SpectraList2 = vipadesktop.SpectraList();
            this.DataBrowser = vipadesktop.VIPAdataBrowser();
            this.SpectraList.setDataBrowser(this.DataBrowser);
            this.SpectraList.addSpectra(0,0, 0,0);
            this.SpectraList2.setDataBrowser(this.DataBrowser);
            this.SpectraList2.addSpectra(0,0, 0,0);
            %=================================================================================================(Desktop Group)
            this.GroupName = tempname;
            this.TPComponent = vipadesktop.ToolGroup(this.GroupName,'VIPA Workspace');
            this.TPComponent.setDataBrowser(this.DataBrowser.View.getPanel);
            
            % Tab Control
            this.hometab = vipadesktop.hometab(this.TPComponent);
            this.TPComponent.add(this.hometab.TPComponent);
            addlistener(this.hometab,'OpenButtonPressed',@(~,~) this.openDialog());
            
            %=====================================================================================================(PID Tuner)
            %this.PIDTuner = pidtool.desktop.PIDTuner(this, desiredtype, baselinecontroller);
            %=======================================================================================(Initial design and Open)
            this.open();
            drawnow;
%             if this.PIDTuner.TC.DataSourcePlot.hasBaseline && ~this.PIDTuner.TC.DataSourcePlot.showBaseline
%                 if strcmp(this.Type, 'MATLAB')
%                     this.PIDTuner.TC.setStatusText(pidtool.utPIDgetStrings('cst','tunerdlg_unstablebase_warning'),'warning');
%                 else
%                     this.PIDTuner.TC.setStatusText(pidtool.utPIDgetStrings('scd','tunerdlg_unstableblock_warning'),'warning');
%                 end
%             end
%             this.PIDTuner.TC.oneClick();
%             this.PIDTuner.updateMessagePanel();
%             %=====================================================================================================(Listeners)
%             setClosingApprovalNeeded(this.TPComponent,true);
%             addlistener(this.TPComponent, 'GroupAction',@(src, evnt) cbCloseGroup(this, evnt));
%             addlistener(this.TPComponent, 'ClientAction',@(src, evnt) cbClientAction(this, evnt));
%             addlistener(this.PlantList, 'OpenLoopRelinearizationRequested', ...
%                 @(es,ed)showOpenLoopRelinearizationTab(this));
%             addlistener(this.PlantList, 'ClosedLoopRelinearizationRequested', ...
%                 @(es,ed)showClosedLoopRelinearizationTab(this));
%             addlistener(this.PlantList, 'PlantIdentificationRequested', ...
%                 @(es,ed)showIdentificationTab(this));
%             addlistener(this.PlantListBrowser, 'ComponentRequest', ...
%                 @(es,ed)cbPlantListBrowserRequest(this,ed));
        end
        function open(this)
            %OPEN
            this.TPComponent.open;
%             groupwidth = this.PIDTuner.TabGC.FrameWidth;
%             this.MD = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
%             loc = com.mathworks.widgets.desk.DTLocation.createExternal( int16(100), int16(100), int16(groupwidth), int16(710));
%             this.MD.setGroupLocation(this.TPComponent.Name, loc);
%             Frame = this.MD.getFrameContainingGroup(this.GroupName);
%             this.StatusBar = ctrluis.toolstrip.StatusMessage(Frame);
%             this.PIDTuner.TC.StatusBar = this.StatusBar;
%             this.PlantList.StatusBar = this.StatusBar;
%             if ~strcmp(this.Type, 'MATLAB')
%                 this.SimulinkGateway.StatusBar = this.StatusBar;
%             end
%             db = this.MD.getClient('DataBrowserContainer', this.TPComponent.Name);
%             db.setMinimized(true);
        end
        function close(this)
            %CLOSE
            this.PIDTuner.isGroupActionClosing = true;
            delete(this.PIDTuner.ResponsePlots);
            this.TPComponent.close;
        end
        function val = getPIDBlockHandle(this)
            %GETPIDBLOCKHANDLE
            val = this.SimulinkGateway.PIDBlockHandle;
        end
        function show(this)
            %SHOW
            if ~isempty( this.SimulinkGateway)
                this.SimulinkGateway.update();
            end
            this.TPComponent.open;
        end
        function configureTiling(this,src)
            
            if isempty(this.PIDTuner.ResponsePlots)
                return;
            end
            
            % get tile id of all pid tuner figures
            for i = 1:length(this.PIDTuner.ResponsePlots)
                pidfigurename = this.PIDTuner.ResponsePlots(i).Figure.Name;
                A(i) = this.MD.getClientLocation(pidfigurename).getTile;
            end
            
            % find tiles that have one and only one pid tuner figure
            a = unique(A);
            if length(a)==1
                pidtiles = a(length(A)==1);
            else
                pidtiles = a(hist(A,a)==1);
            end
            
            % find sysid tile
            if isempty(this.PlantIdentifier)
                sysidtile = -2;
            else
                sysidtile = this.MD.getClientLocation(this.PlantIdentifier.Figure.Name).getTile;
            end
            
            % find re-lin tool tile
            if isempty(this.ClosedLoopRelinearizer)
                cllintile = -2;
            else
                cllintile = this.MD.getClientLocation(this.ClosedLoopRelinearizer.Figure.Name).getTile;
            end
            
            % find tiles that have only one figure and the figure is for pid
            % tuner
            uniquepidtiles = pidtiles(pidtiles~=sysidtile & pidtiles~=cllintile);
            
            n = length(uniquepidtiles);
            N = this.MD.getDocumentTiledDimension(this.GroupName).width * this.MD.getDocumentTiledDimension(this.GroupName).height;
            
            if N==1 && n==1 % split screen
                this.MD.setDocumentArrangement(this.GroupName, this.MD.TILED, java.awt.Dimension(2,1));
            elseif N==2 && n==1 && ~isa(src,'pidtool.desktop.PIDTuner') % put new figure in non-pid tile
                if ~isempty(this.PlantIdentifier)
                    figure(this.PlantIdentifier.Figure);
                end
                if ~isempty(this.ClosedLoopRelinearizer)
                    figure(this.ClosedLoopRelinearizer.Figure);
                end
            end
        end
    end
end
%=================================================================================================================(Callbacks)
function cbCloseGroup(this, evnt)
%CBCLOSEGROUP
ET = evnt.EventData.EventType;
if strcmp(ET, 'CLOSING')
    this.PIDTuner.isGroupActionClosing = true;
    this.TPComponent.approveClose;
end
if strcmp(ET, 'CLOSED')
    L = this.Listeners;
    for ct = 1:numel(L)
        delete(L{ct})
    end
    delete(this);
end
end
function cbModelLinearizationChanged(this)
%CBMODELLINEARIZATIONCHANGED
this.PlantList.addPlant(this.SimulinkGateway.LinearizedPlant, 0, this.SimulinkGateway.InspectorData,'');
end
function cbClientAction(this, evnt)
% Selected tab changed callback
ET = evnt.EventData.EventType;
if strcmp(ET, 'ACTIVATED')
    fig = evnt.EventData.Client;
    if ~isempty(fig)
        tunertool = this.PIDTuner;
        plantidtool = this.PlantIdentifier;
        relintool = this.ClosedLoopRelinearizer;
        tooltag = get(fig,'Tag');
        if ~isempty(tunertool) && isvalid(tunertool) && strcmp(tooltag, 'PIDTunerFigure')
            tunertool.TC.updateStatusBar();
            tunertool.TC.DataSourcePlot.setActiveFigure(fig);
            tunertool.updateMessagePanel();
        elseif ~isempty(plantidtool) && isvalid(plantidtool) && ...
                strcmp(tooltag, sprintf('PIDIdentificationPlot:%s',plantidtool.Name))
            if ~strcmp(this.StatusBar.ParentTool,'plantid')
                this.StatusBar.setText('',[],'west');
                this.StatusBar.ParentTool = 'plantid';
            end
            showStatus(plantidtool.Data);
        elseif ~isempty(relintool) && isvalid(relintool) && strcmp(tooltag, 'RelinFigure')
            relintool.TC.updateStatusBar();
        else
            % ignore
        end
    end
end
end
function cbPlantListBrowserRequest(this,ed)
switch ed.Request
    case 'export'
        success = this.PIDTuner.TC.ExportDialogTC.exportControllerAndSelectedPlants('', ed.Variables);
        if success
            this.StatusBar.setText(pidtool.utPIDgetStrings('cst','strPlantExported'),'info','west');
            this.StatusBar.ParentTool = 'plantlistbrowser';
        else
            this.StatusBar.setText('',[],'west');
        end
    case 'select'
        this.PlantList.SelectedPlant = ed.Variables{1};
end
end
%====================================================================================(Launch Open Loop Re-Linearization Tool)
function showOpenLoopRelinearizationTab(this)
% show tab for plant identification
if isempty(this.OpenLoopRelinearizer) || ~isvalid(this.OpenLoopRelinearizer)
    relintc = pidtool.desktop.relinearizetool.ReLinTC(this.SimulinkGateway, 'openloop');
    relintc.StatusBar = this.StatusBar;
    this.OpenLoopRelinearizer = pidtool.desktop.RelinearizationTool(relintc,this);
    L = handle.listener(this.OpenLoopRelinearizer.hPlot, 'ObjectBeingDestroyed',...
        {@localReleaseOpenLoopRelinearizer,this});
    this.Listeners{1} = L;
else
    figure(this.OpenLoopRelinearizer.hPlot.AxesGrid.Parent);
end
this.OpenLoopRelinearizer.hPlot.Visible = 'on';
end
%==================================================================================(Launch Closed Loop Re-Linearization Tool)
function showClosedLoopRelinearizationTab(this)
% show tab for plant identification
if isempty(this.ClosedLoopRelinearizer) || ~isvalid(this.ClosedLoopRelinearizer)
    this.configureTiling([]);
    relintc = pidtool.desktop.relinearizetool.ReLinTC(this.SimulinkGateway, 'closedloop', this.StatusBar);
    this.ClosedLoopRelinearizer = pidtool.desktop.RelinearizationTool(relintc, this);
    L = handle.listener(this.ClosedLoopRelinearizer.hPlot, 'ObjectBeingDestroyed',...
        {@localReleaseClosedLoopRelinearizer,this});
    this.Listeners{2} = L;
else
    figure(this.ClosedLoopRelinearizer.hPlot.AxesGrid.Parent);
end
this.ClosedLoopRelinearizer.hPlot.Visible = 'on';
end
%========================================================================================================(Launch Sys-ID Tool)
function showIdentificationTab(this)
% show tab for plant identification

if ~controllibutils.isSITBInstalled
    TaskName = getString(message('Control:pidtool:strIdentifyNewPlant'));
    DlgMode = struct('WindowStyle','modal','Interpreter','tex');
    Msg = getString(message('Control:pidtool:requiresSITB',TaskName));
    errordlg(Msg,'',DlgMode)
    return
end
if strcmp(this.Type, 'Simulink')
    isMatlab = false;
    is2DOF = this.SimulinkGateway.is2DOF;
else
    isMatlab = true;
    is2DOF = false;
end
if isempty(this.PlantIdentifier) || ~isvalid(this.PlantIdentifier)
    this.configureTiling([]);
    Data = iduis.pid.TaskData(isMatlab,is2DOF,this.PlantList);
    Data.StatusBar = this.StatusBar;
    this.PlantIdentifier = iduis.pid.IdentificationPlot(pidtool.utPIDgetStrings('cst','strIdentification'),...
        Data, this.TPComponent);
    this.PlantIdentifier.DataGenerationMode.setSLGateway(this.SimulinkGateway);
    L1 = handle.listener(this.PlantIdentifier.hPlot, 'ObjectBeingDestroyed',...
        {@localReleaseIdentifier,this});
    this.Listeners{3} = L1;
else
    figure(this.PlantIdentifier.hPlot.AxesGrid.Parent);
end
this.PlantIdentifier.hPlot.Visible = 'on';
showInstructionBanner(this.PlantIdentifier, true)
end
%==================================================================================================================(Clean-up)
function localReleaseOpenLoopRelinearizer(~,~,this)
% Release plant identifier.
this.OpenLoopRelinearizer = [];
end
function localReleaseClosedLoopRelinearizer(~,~,this)
% Release plant identifier.
this.ClosedLoopRelinearizer = [];
end
function localReleaseIdentifier(~,~,this)
% Release plant identifier.
this.PlantIdentifier = [];
end

