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
        ImagesList
        CalibrationList
        SpectraList
        FitSpectraList
        FitsList
        TC
        TabGC
        
        % Tabs
        hometab
        acquiretab
        fittingtab
        fitanalysistab
        figuretab
        
        % Image Acquire Functions Library
        acquireOperations
        acquireFunctions
        singleImageAcquireFunctions
        kineticsImagesAcquireFunctions
        fitAnalysisFunctions
        
        % Acquire Functions
        acquireOperation
        acquireFunction % Takes no arguments, returns images or spectra, timestamps, {'images','spectra'}
        singleImageAcquireFunction % Takes no arguments, returns a single image
        kineticsImagesAcquireFunction % Takes no arguments, returns multiple images, timestamps
        fitAnalysisFunction % Takes three arguments: time, moleculeConcentrations, moleculeLabels
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
            this.ImagesList = vipadesktop.ImagesList();
            this.CalibrationList = vipadesktop.CalibrationList();
            this.SpectraList = vipadesktop.SpectraList();
            this.FitSpectraList = vipadesktop.FitSpectraList();
            this.FitsList = vipadesktop.FitsList();
%             this.SpectraList2 = vipadesktop.SpectraList();
            this.DataBrowser = vipadesktop.VIPAdataBrowser();
            this.ImagesList.setWorkspace(this.DataBrowser.imagesWorkspace);
            this.CalibrationList.setWorkspace(this.DataBrowser.calibrationWorkspace);
            this.SpectraList.setWorkspace(this.DataBrowser.spectraWorkspace);
            this.FitSpectraList.setWorkspace(this.DataBrowser.fitspectraWorkspace);
            this.FitsList.setWorkspace(this.DataBrowser.fitsWorkspace);
            %this.SpectraList.addSpectra(0,0, 0,'test1');
%             this.SpectraList2.setDataBrowser(this.DataBrowser);
%             this.SpectraList2.addSpectra(0,0, 0,0);
            %=================================================================================================(Desktop Group)
            this.GroupName = tempname;
            this.TPComponent = vipadesktop.ToolGroup(this.GroupName,'VIPA Workspace');
            this.TPComponent.setDataBrowser(this.DataBrowser.View.getPanel);
            
            % Get Image Acquire Operations
            this.acquireOperations = {'add','replace','average','averageWithRestart'};
            this.acquireOperation = this.acquireOperations{1};
            
            % Get Image Acquire functions
            acquireFunctionsPackage = what('acquireFunctions');
            singleImageAcquireFunctionsPackage = what('singleImageAcquireFunctions');
            kineticsImagesAcquireFunctionsPackage = what('kineticsImagesAcquireFunctions');
            fitAnalysisFunctionsPackage = what('fitAnalysisFunctions');
            
            this.acquireFunctions = {};
            for i = 1:numel(acquireFunctionsPackage.m)
                [~,b,~] = fileparts(acquireFunctionsPackage.m{i});
                this.acquireFunctions{end+1} = str2func(sprintf('%s.%s','acquireFunctions',b));
            end
            if numel(this.acquireFunctions) > 0
                this.acquireFunction = this.acquireFunctions{1};
            end
            
            this.singleImageAcquireFunctions = {};
            for i = 1:numel(singleImageAcquireFunctionsPackage.m)
                [~,b,~] = fileparts(singleImageAcquireFunctionsPackage.m{i});
                this.singleImageAcquireFunctions{end+1} = str2func(sprintf('%s.%s','singleImageAcquireFunctions',b));
            end
            if numel(this.singleImageAcquireFunctions) > 0
                this.singleImageAcquireFunction = this.singleImageAcquireFunctions{1};
            end
            
            this.kineticsImagesAcquireFunctions = {};
            for i = 1:numel(kineticsImagesAcquireFunctionsPackage.m)
                [~,b,~] = fileparts(kineticsImagesAcquireFunctionsPackage.m{i});
                this.kineticsImagesAcquireFunctions{end+1} = str2func(sprintf('%s.%s','kineticsImagesAcquireFunctions',b));
            end
            if numel(this.kineticsImagesAcquireFunctions) > 0
                this.kineticsImagesAcquireFunction = this.kineticsImagesAcquireFunctions{1};
            end
            
            this.fitAnalysisFunctions = {};
            for i = 1:numel(fitAnalysisFunctionsPackage.m)
                [~,b,~] = fileparts(fitAnalysisFunctionsPackage.m{i});
                this.fitAnalysisFunctions{end+1} = str2func(sprintf('%s.%s','fitAnalysisFunctions',b));
            end
            if numel(this.fitAnalysisFunctions) > 0
                this.fitAnalysisFunction = this.fitAnalysisFunctions{1};
            end
            
            % Tab Controls
            this.hometab = vipadesktop.hometab(this.TPComponent);
            this.TPComponent.add(this.hometab.TPComponent);
            this.acquiretab = vipadesktop.acquiretab(this.TPComponent,this.acquireFunctions,this.singleImageAcquireFunctions,this.kineticsImagesAcquireFunctions);
            this.TPComponent.add(this.acquiretab.TPComponent);
            addlistener(this.acquiretab,'AcquireFunctionBoxAction',@(~,~) this.setAcquireFunction(this.acquiretab.acquireFunctionComboBox.SelectedItem));
            addlistener(this.acquiretab,'AcquireOperationBoxAction',@(~,~) this.setAcquireOperation(this.acquiretab.acquireOperationComboBox.SelectedItem));
            
            this.fittingtab = vipadesktop.fittingtab(this.TPComponent);
            this.TPComponent.add(this.fittingtab.TPComponent);
            this.fitanalysistab = vipadesktop.fitanalysistab(this.TPComponent,this.fitAnalysisFunctions);
            this.TPComponent.add(this.fitanalysistab.TPComponent);
            this.figuretab = vipadesktop.figuretab(this.TPComponent);
            this.TPComponent.add(this.figuretab.TPComponent);
            addlistener(this.hometab,'NewButtonPressed',@(~,~) this.newDialog());
            addlistener(this.hometab,'OpenButtonPressed',@(~,~) this.openDialog());
            addlistener(this.hometab,'OpenButtonKineticsObjectPressed',@(~,~) this.openDialogKineticsObject());
            
            % Add Spectrum acquire listener
            addlistener(this.acquiretab,'AcquireButtonPressed',@(~,~) this.acquire());
            
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
            addlistener(this.DataBrowser, 'ComponentRequest', ...
                @(es,ed)cbPlantListBrowserRequest(this,ed));
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
        
        % Get Set functions
        function setAcquireFunction(this,acquireFunctionString)
            this.acquireFunction = str2func(sprintf('%s.%s','acquireFunctions',acquireFunctionString));
        end
        function setAcquireOperation(this,acquireOperationString)
            this.acquireOperation = acquireOperationString;
        end
    end
end

%=================================================================================================================(Callbacks)
function cbPlantListBrowserRequest(this,ed)
switch ed.Request
    % Image Acquire Events
    case 'acquiresingleimage'
        image = this.singleImageAcquireFunction();
        this.ImagesList.setImages(ed.Variables,image,0);
    case 'acquirekineticsimages'
        [images,time] = this.kineticsImagesAcquireFunction();
        this.ImagesList.setImages(ed.Variables,images,time);
        
    % Image Calibration Events
    case 'createcalibration'
        itemNames = this.ImagesList.getItemNames(ed.Variables);
        h = this.ImagesList.createCalibration(ed.Variables);
        this.CalibrationList.addItem(h,0,0,itemNames);
    
    % Save Events
    case 'imageslist_savetofile'
        this.ImagesList.saveToFile(ed.Variables);
    case 'fitslist_savetofile'
        this.FitsList.saveToFile(ed.Variables);
    case 'fitslist_setinitialconditions'
        this.FitsList.setInitialConditions(ed.Variables);
    
    % Other functions
    case 'openplotbrowser'
        hwait = waitbar(0,'Opening Plot Browsers...', 'WindowStyle', 'modal');
        for i = 1:numel(ed.Variables)
            h = this.SpectraList.openPlotBrowsers(ed.Variables(i));
            this.TPComponent.addFigure(h);
            waitbar(i/numel(ed.Variables),hwait);
        end
        close(hwait);
    case 'openimagebrowser'
        h = this.ImagesList.openImageBrowsers(ed.Variables);
        this.TPComponent.addFigure(h);
    case 'openfitbrowser'
        h = this.FitsList.openFitBrowsers(ed.Variables);
        this.TPComponent.addFigure(h);
    case 'openfitbrowserwithresiduals'
        h = this.FitsList.openFitBrowsersWithResiduals(ed.Variables);
        this.TPComponent.addFigure(h);
    case 'plotfitcoefficients'
        hwait = waitbar(0,'Plotting Fit Coefficients...', 'WindowStyle', 'modal');
        for i = 1:numel(ed.Variables)
            h = this.FitsList.plotFitCoefficients(ed.Variables(i));
            this.TPComponent.addFigure(h);
            waitbar(i/numel(ed.Variables),hwait);
        end
        close(hwait);
    case 'plotgroupedfitcoefficients'
        hs = this.FitsList.plotGroupedFitCoefficients(ed.Variables);
        for h = hs
            this.TPComponent.addFigure(h);
        end
    case 'exportDOCOglobals'
        this.FitsList.exportDOCOglobals(ed.Variables);
    case 'exportToSimBiology'
        this.FitsList.exportToSimBiology(ed.Variables);
    case 'performspectralfit'
        hwait = waitbar(0,'Fitting Spectra', 'WindowStyle', 'modal');
        for i = 1:numel(ed.Variables)
            h = this.SpectraList.performSpectralFits(ed.Variables(i),this.FitSpectraList.Plants,0);
            this.FitsList.addItem(h,0,0,strrep(h.name,' ','_'));
            waitbar(i/numel(ed.Variables),hwait);
        end
        close(hwait);
    case 'imageslist_setacquiredestination'
        itemNames = this.ImagesList.getItemNames(ed.Variables);
        this.acquiretab.imageDestTextField.Text = itemNames;
    case 'calibrationlist_setacquirecalibration'
        itemNames = this.CalibrationList.getItemNames(ed.Variables);
        this.acquiretab.calibrationTextField.Text = itemNames;
    case 'spectralist_setacquiredestination'
        itemNames = this.SpectraList.getItemNames(ed.Variables);
        this.acquiretab.spectraDestTextField.Text = itemNames;
    case 'calibrationlist_collectfringes'
        this.CalibrationList.collectFringes(ed.Variables);
    case 'imageslist_createspectra'
        calibrationobjid = {this.acquiretab.calibrationTextField.Text};
        hwait = waitbar(0,'Creating Spectra...', 'WindowStyle', 'modal');
        for i = 1:numel(ed.Variables)
            itemNames = this.ImagesList.getItemNames(ed.Variables(i));
            [images,time] = this.ImagesList.getImages(ed.Variables(i));
            h = this.CalibrationList.createSpectraObject(calibrationobjid,images,time);
            this.SpectraList.addItem(h,0,0,strrep(itemNames,' ','_'));
            waitbar(i/numel(ed.Variables),hwait);
        end
        close(hwait);
    case 'imageslist_useasrefimage'
        calibrationobjid = {this.acquiretab.calibrationTextField.Text};
        [images,time] = this.ImagesList.getImages(ed.Variables(1));
        this.CalibrationList.setRefImage(calibrationobjid,images(:,:,1));
    case 'imageslist_averageimages'
        itemNames = this.ImagesList.getItemNames(ed.Variables(1));
        h = this.ImagesList.averageImages(ed.Variables(1));
        this.ImagesList.addItem(h,0,0,strrep(sprintf('%s_avg',itemNames),' ','_'));
    case 'imageslist_useassigimage'
        calibrationobjid = {this.acquiretab.calibrationTextField.Text};
        [images,time] = this.ImagesList.getImages(ed.Variables(1));
        this.CalibrationList.setSigImage(calibrationobjid,images(:,:,1));
    case 'calibrationlist_exporttobaseworkspace'
        assignin('base','hobj',this.CalibrationList.Plants);
    case 'imageslist_openlineprofilebrowser'
        h = this.ImagesList.openLineProfileBrowsers(ed.Variables);
        this.TPComponent.addFigure(h);
    case 'select'
        this.PlantList.SelectedPlant = ed.Variables{1};
end
end
