classdef vipatabs < handle
    %PIDTUNERTC
    
    % Author(s): Baljeet Singh 05-Sep-2013
    % Copyright 2013 The MathWorks, Inc.
    
    properties
        PlantList
        ControllerList
        InputVariables
        DataSourcePlot
        ImportDialogTC
        ExportDialogTC
        InspectorTC
        NeedsIntegrator
        IsTunedStable
        SLGateway
        ToolType = 'MATLAB'
        AutoUpdateMode = false
        NyquistFreq
    end
    properties(SetObservable = true)
        DesignFocus = 'balanced'
    end
    properties (Dependent = true)
        IsBaselineStable
    end
    properties
        StatusBar
    end
    properties(Access = private)
        PIDTuningData
        addingNewPlant = false
        selectedNewPlant = false
    end
    methods
        function this = vipatabs(type)
            %PIDTUNERTC
            
            this.build();
            
%             this.DataSourcePlot = pidtool.desktop.pidtuner.tc.DataSourcePlot(this);
%             if strcmp(this.ToolType, 'MATLAB')
%                 this.ImportDialogTC = pidtool.desktop.pidtuner.tc.ImportDialogTC(this);
%             else
%                 this.ImportDialogTC = slctrlguis.pidtuner.tc.ImportDialogTC(this);
%             end
%             this.ExportDialogTC = pidtool.desktop.pidtuner.tc.ExportDialogTC(this);
%             addlistener(this.DataSourcePlot, 'QuickRefreshMode', 'PostSet', @(~,~) this.updateBlockParameters(true));
        end
        function build(this)
            %BUILD
            
            %this.InspectorTC = this.PlantList.SelectedPlantInspectorData();
            %this.setPIDTuningData();
            %this.oneClick();
        end
        function setPIDTuningData(this)
            %SETPIDTUNINGDATA
            
            PID = ltipack.getPIDfromType(this.ControllerList.DesiredType,...
                this.ControllerList.DesiredForm,...
                this.PlantList.SelectedPlantSampleTime,...
                this.PlantList.SelectedPlantTimeUnit);
            PID.IFormula = this.ControllerList.DesiredIFormula;
            PID.DFormula = this.ControllerList.DesiredDFormula;
            Options = pidtuneOptions('NumUnstablePoles',this.PlantList.SelectedPlantNUP,...
                'DesignFocus',this.DesignFocus);
            if isempty(this.PlantList.SelectedPlant)
                G = tf(0);
            else
                G = this.PlantList.SelectedPlant;
            end
            this.PIDTuningData = getPIDTuningData(G,PID,Options);
            Ts = G.Ts;
            if Ts > 0
                this.NyquistFreq = 3.14159/G.Ts;
            else
                this.NyquistFreq = realmax;
            end
        end
        function oneClick(this)
            %ONECLICK
            
            PM = this.InputVariables.PM;
            if ~isempty(this.SLGateway) && this.SLGateway.is2DOF
                [PIDdata, bc, info] = tune2DOF(this.PIDTuningData,pidtuneOptions('PhaseMargin',PM));
            else
                [PIDdata, info] = tune(this.PIDTuningData,pidtuneOptions('PhaseMargin',PM));
                bc = [1 1];
            end
            if strcmp(this.ControllerList.DesiredForm,'parallel')
                PID = pid.make(PIDdata);
            else
                PID = pidstd.make(PIDdata);
            end
            PID.TimeUnit = this.PlantList.SelectedPlantTimeUnit;
            PID.InputName = 'e';
            PID.OutputName = 'ufb';
            this.clearWaitBar();
            this.ControllerList.TunedBC = bc;
            this.ControllerList.TunedController = PID;
            this.IsTunedStable = info.Stable;
            this.NeedsIntegrator = info.NeedsIntegrator;
            this.InputVariables.setWC_(info.wc);
            this.InputVariables.resetMinMaxWC();
            
            if (this.addingNewPlant || this.selectedNewPlant) && isa(this.PlantList.SelectedPlant,'frd')...
                    && strcmp(this.DataSourcePlot.ActiveFigureType,'Step')
                this.setStatusText(pidtool.utPIDgetStrings('cst', 'strUseBodeWarn'), 'warn');
                this.addingNewPlant = false;
                this.selectedNewPlant = false;
                return;
            end
            
            if this.addingNewPlant
                this.setStatusText(ctrlMsgUtils.message('Control:pidtool:strAddedPlantInfo',this.PlantList.SelectedPlantName),'info');
                this.addingNewPlant = false;
            elseif this.selectedNewPlant
                this.setStatusText(ctrlMsgUtils.message('Control:pidtool:strSelectedPlantChangedInfo',this.PlantList.SelectedPlantName),'info');
                this.selectedNewPlant = false;
            else
            end
            if ~this.IsTunedStable
                this.setStatusText(ctrlMsgUtils.message('Control:pidtool:strInitialControllerUnstable',this.PlantList.SelectedPlantName),'warning');
            elseif this.NeedsIntegrator
                this.setStatusText(ctrlMsgUtils.message('Control:design:pidtune11'),'warning');
            else
            end
            
        end
        function fastDesign(this)
            %FASTDESIGN
            
            WC = this.InputVariables.WC;
            PM = this.InputVariables.PM;
            if ~isempty(this.SLGateway) && this.SLGateway.is2DOF
                [PIDdata,bc,info] = tune2DOF(this.PIDTuningData, pidtuneOptions('PhaseMargin',PM,'CrossoverFrequency',WC));
            else
                [PIDdata,info] = tune(this.PIDTuningData, pidtuneOptions('PhaseMargin',PM,'CrossoverFrequency',WC));
                bc = [1 1];
            end
            if strcmp(this.ControllerList.DesiredForm,'parallel')
                PID = pid.make(PIDdata);
            else
                PID = pidstd.make(PIDdata);
            end
            PID.TimeUnit = this.PlantList.SelectedPlantTimeUnit;
            PID.InputName = 'e';
            PID.OutputName = 'ufb';
            this.ControllerList.TunedBC = bc;
            this.ControllerList.TunedController = PID;
            this.IsTunedStable = info.Stable;
            this.NeedsIntegrator = info.NeedsIntegrator;
            
            if ~this.IsTunedStable
                this.setStatusText(pidtool.utPIDgetStrings('cst','strControllerUnstable'),'warning');
            elseif this.NeedsIntegrator
                this.setStatusText(ctrlMsgUtils.message('Control:design:pidtune11'),'warning');
            else
                this.clearStatusText();
            end
        end
        function set.ControllerList(this, val)
            %SET
            
            this.ControllerList = val;
            addlistener(this.ControllerList, 'DesiredController', 'PostSet', @(~,~)cbDesiredControllerChanged(this));
        end
        function set.InputVariables(this, val)
            %SET
            
            this.InputVariables = val;
            addlistener(this.InputVariables,'WC', 'PostSet', @(x,y)fastDesign(this));
            addlistener(this.InputVariables,'PM', 'PostSet', @(x,y)fastDesign(this));
        end
        function set.PlantList(this, val)
            %SET
            
            this.PlantList = val;
            addlistener(this.PlantList, 'SelectedPlantIndex', 'PostSet', @this.callbackSelectedPlantIndex);
            addlistener(this.PlantList,'PlantsEvent', @this.callbackPlants);
            addlistener(this.PlantList, 'SampleTime', 'PostSet', @this.callbackSampleTime);
        end
        function val = get.IsBaselineStable(this)
            C = this.ControllerList.BaselineController;
            G = this.PlantList.SelectedPlant;
            NUP = this.PlantList.SelectedPlantNUP;
            if ~isempty(C) && G.Ts == C.Ts
                val = checkNyquistStability(G*C,-1,NUP);
            else
                val = 2;
            end
        end
        function set.DesignFocus(this,val)
            this.DesignFocus = val;
            this.setPIDTuningData();
            this.fastDesign();
            this.setStatusText(ctrlMsgUtils.message('Control:pidtool:strDesignFocusInfo',val),'info');
        end
        function updateBlockParameters(this, auto)
            
            if auto
                if this.AutoUpdateMode && ~this.DataSourcePlot.QuickRefreshMode
                    this.SLGateway.setPIDBlockController(this.ControllerList.TunedController,this.ControllerList.TunedBC);
                end
            else
                this.SLGateway.setPIDBlockController(this.ControllerList.TunedController,this.ControllerList.TunedBC);
            end
        end
        
        function updateStatusBar(this)
            if isempty(this.StatusBar)
                return
            else
                if ~strcmp(this.StatusBar.ParentTool, 'pidtuner')
                    this.clearStatusText();
                    this.StatusBar.ParentTool = 'pidtuner';
                end
                this.DataSourcePlot.showPIDGains();
            end
        end
        function clearStatusText(this, val)
            if isempty(this.StatusBar) || this.StatusBar.isWestMessageClear
                return
            else
                if nargin == 1
                    this.StatusBar.setText('',[],'west');
                elseif this.StatusBar.isWestMessageText(val)
                    this.StatusBar.setText('',[],'west');
                end
            end
        end
        function clearWaitBar(this)
            if isempty(this.StatusBar)
                return
            else
                this.StatusBar.hideWaitBar();
            end
        end
        function setStatusText(this, text, type)
            if isempty(this.StatusBar)
                return
            elseif ~isempty(text)
                this.StatusBar.setText(text,type,'west');
            else
                reset(this.StatusBar);
            end
        end
        function callbackSelectedPlantIndex(this, ~,~)
            this.DataSourcePlot.handleSelectedPlantIndexEvent();
            this.selectedNewPlant = true;
            this.build();
            this.DataSourcePlot.update(true, true); % update controller data
            this.DataSourcePlot.QuickRefreshMode = false;
        end
        function callbackPlants(this, ~,evnt)
            this.DataSourcePlot.handlePlantsEvent(evnt);
            this.addingNewPlant = true;
        end
        function callbackSampleTime(this, ~,~)
            this.DataSourcePlot.updatePlantsInfo();
            this.selectedNewPlant = false;
            this.addingNewPlant = false;
            this.build();
        end
    end
end

function cbPIDBlockDataChanged(this)
this.PlantList.SampleTime = this.SLGateway.PIDBlockData.CompiledSampleTime;
this.ControllerList.BaselineController = this.SLGateway.PIDBlockController;
this.ControllerList.DesiredForm = this.SLGateway.PIDBlockData.Form;
this.ControllerList.DesiredType = this.SLGateway.PIDBlockData.Controller;
this.ControllerList.BaselineBC = [this.SLGateway.PIDBlockData.b this.SLGateway.PIDBlockData.c];
end

function cbDesiredControllerChanged(this)
this.setPIDTuningData();
this.fastDesign();
end
