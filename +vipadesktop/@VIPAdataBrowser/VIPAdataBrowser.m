classdef VIPAdataBrowser < handle
    %PLANTLISTBROWSER
    
    % Author(s): Baljeet Singh 05-Sep-2013
    % Copyright 2013 The MathWorks, Inc.
    
    properties
		Parent
        Model
        View
        imagesWorkspace
        imagesWorkspaceView
        spectraWorkspace
        spectraWorkspaceView
        fitsWorkspace
        fitsWorkspaceView
        fitspectraWorkspace
        fitspectraWorkspaceView
        calibrationWorkspace
        calibrationWorkspaceView
        kineticsmodelsWorkspace
        kineticsmodelsWorkspaceView
    end
    events
        ComponentRequest
    end
    methods
        function obj = VIPAdataBrowser(Parent)
            %PLANTLISTBROWSER
            this.Parent = Parent;
			
            % Construct the basic model
            obj.Model = vipadesktop.DataBrowserModel;%toolpack.databrowser.DataBrowserModel;
            obj.Model.remove('base');
            obj.Model.remove('filter');
            obj.Model.remove('preview');
            obj.Model.remove('local');
            
            % Add the necessary sections
            tc = vipadesktop.LocalWorkspaceModel;%toolpack.databrowser.LocalWorkspaceModel;
            tc.Name = 'images';
            tc.NewVariableFunction = @imagesobjects.imagesobject;
            tc.NewVariableBaseName = 'images';
            obj.Model.add(tc);
            tc = vipadesktop.LocalWorkspaceModel;%toolpack.databrowser.LocalWorkspaceModel;
            tc.Name = 'calibration';
            tc.NewVariableFunction = @calibrationobjects.vipacalibration;
            tc.NewVariableBaseName = 'calibration';
            %obj.Model.add(tc);
            tc = vipadesktop.LocalWorkspaceModel;%toolpack.databrowser.LocalWorkspaceModel;
            tc.Name = 'spectra';
            tc.NewVariableFunction = @spectraobjects.spectraobject;
            tc.NewVariableBaseName = 'spectra';
            obj.Model.add(tc);
            tc = vipadesktop.LocalWorkspaceModel;%toolpack.databrowser.LocalWorkspaceModel;
            tc.Name = 'fitspectra';
            tc.NewVariableFunction = @fitspectraobjects.linelist;
            tc.NewVariableBaseName = 'linelist';
            obj.Model.add(tc);
            tc = vipadesktop.LocalWorkspaceModel;%toolpack.databrowser.LocalWorkspaceModel;
            tc.Name = 'fits';
            tc.NewVariableFunction = @fitsobjects.fitsobject;
            tc.NewVariableBaseName = 'fits';
            obj.Model.add(tc);
            tc = vipadesktop.LocalWorkspaceModel;%toolpack.databrowser.LocalWorkspaceModel;
            tc.Name = 'kineticsmodels';
            tc.NewVariableFunction = @kineticsmodelobjects.simbiologymodelobject;
            tc.NewVariableBaseName = 'kineticsmodels';
            obj.Model.add(tc);
            
            % Set View Parameters
            obj.View = vipadesktop.DataBrowserView(obj.Model);%toolpack.databrowser.DataBrowserView(obj.Model);
            setTitle(getComponent(obj.View,'images'),'Images');
            %setTitle(getComponent(obj.View,'calibration'),'Calibration');
            setTitle(getComponent(obj.View,'spectra'),'Spectra');
            setTitle(getComponent(obj.View,'fitspectra'),'Fit Spectra');
            setTitle(getComponent(obj.View,'fits'),'Fits');
            setTitle(getComponent(obj.View,'kineticsmodels'),'Kinetics Models');
            reset(obj.View);
            
            % Set internal parameters
            obj.imagesWorkspace = obj.Model.getComponent('images');
            obj.imagesWorkspaceView = obj.View.getComponent('images');
            obj.calibrationWorkspace = obj.Model.getComponent('calibration');
            %obj.calibrationWorkspaceView = obj.View.getComponent('calibration');
            obj.spectraWorkspace = obj.Model.getComponent('spectra');
            obj.spectraWorkspaceView = obj.View.getComponent('spectra');
            obj.fitspectraWorkspace = obj.Model.getComponent('fitspectra');
            obj.fitspectraWorkspaceView = obj.View.getComponent('fitspectra');
            obj.fitsWorkspace = obj.Model.getComponent('fits');
            obj.fitsWorkspaceView = obj.View.getComponent('fits');
            obj.kineticsmodelsWorkspace = obj.Model.getComponent('kineticsmodels');
            obj.kineticsmodelsWorkspaceView = obj.View.getComponent('kineticsmodels');
            
            % Set Images popup parameters
            selectionPopupMenu = obj.imagesWorkspaceView.getSelectionPopupMenu;
            nonselectionPopupMenu = obj.imagesWorkspaceView.getNoSelectionPopupMenu;
            WarningState = warning('off','MATLAB:Containers:Map:NoKeyToRemove');
            selectionPopupMenu.removeMenuItem('RecordCopyingMenuItem');
            s.Text = 'Set Acquire Destination';
            s.Name = 'imageslist_setacquiredestination';
            s.Callback = @(x)imageslist_setacquiredestination(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,1);
            s.Text = 'Open Line Profile Browser';
            s.Name = 'imageslist_openlineprofilebrowser';
            s.Callback = @(x)imageslist_openlineprofilebrowser(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,3);
            s.Text = 'Acquire Single Image';
            s.Name = 'acquiresingleimage';
            s.Callback = @(x)acquiresingleimage(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,4);
            s.Text = 'Acquire Kinetics Images';
            s.Name = 'acquirekineticsimages';
            s.Callback = @(x)acquirekineticsimages(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,4);
            s.Text = 'Create Calibration';
            s.Name = 'createcalibration';
            s.Callback = @(x)createcalibration(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,5);
            s.Text = 'Collect Fringes';
            s.Name = 'collectfringes';
            s.Callback = @(x)collectfringes(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,6);
            s.Text = 'Save To File...';
            s.Name = 'imageslist_savetofile';
            s.Callback = @(x)imageslist_savetofile(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,7);
            s.Text = 'Create Spectra';
            s.Name = 'imageslist_createspectra';
            s.Callback = @(x)imageslist_createspectra(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,8);
            s.Text = 'Use As Ref Image';
            s.Name = 'imageslist_useasrefimage';
            s.Callback = @(x)imageslist_useasrefimage(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,9);
            s.Text = 'Use As Sig Image';
            s.Name = 'imageslist_useassigimage';
            s.Callback = @(x)imageslist_useassigimage(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,10);
            s.Text = 'Average Images';
            s.Name = 'imageslist_averageimages';
            s.Callback = @(x)imageslist_averageimages(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,11);
            s.Text = 'Export To Base Workspace';
            s.Name = 'imageslist_exporttobaseworkspace';
            s.Callback = @(x)imageslist_exporttobaseworkspace(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,11);
            s.Text = 'Inspect';
            s.Name = 'imageslist_inspect';
            s.Callback = @(x)imageslist_inspect(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,12);
			
			% Add context menu items
			menuitems = vipadesktop.getpackagemfiles('imagesobjects.contextmenu');
			for i = 1:numel(menuitems)
				s.Text = eval(sprintf('%s.menuitemText',menuitems{i}));
				s.Name =  eval(sprintf('%s.menuitemName',menuitems{i}));
				f = str2func(sprintf('%s.menucallback',menuitems{i}));
				s.Callback =  @(selecteditems) f(this.Parent,selecteditems);
				s.MultiSelection = eval(sprintf('%s.menuitemMultiSelection',menuitems{i}));
				selectionPopupMenu.addMenuItem(s);
				%itemIndex = itemIndex + 1;
			end
			
            %nonselectionPopupMenu.removeMenuItem('RecordCreationMenuItem');
            nonselectionPopupMenu.removeMenuItem('PasteMenuItem');
            warning(WarningState);
            hideColumn(obj.imagesWorkspaceView,'Value');
            hideColumn(obj.imagesWorkspaceView,'Class');
            hideColumn(obj.imagesWorkspaceView,'Size');
            hideColumn(obj.imagesWorkspaceView,'Bytes');
            
            % % Set Calibration popup parameters
            % selectionPopupMenu = obj.calibrationWorkspaceView.getSelectionPopupMenu;
            % nonselectionPopupMenu = obj.calibrationWorkspaceView.getNoSelectionPopupMenu;
            % WarningState = warning('off','MATLAB:Containers:Map:NoKeyToRemove');
            % selectionPopupMenu.removeMenuItem('RecordCopyingMenuItem');
            % s.Text = 'Set Active Calibration';
            % s.Name = 'calibrationlist_setacquirecalibration';
            % s.Callback = @(x)calibrationlist_setacquirecalibration(obj,x);
            % s.MultiSelection = false;
            % selectionPopupMenu.addMenuItem(s,1);
            % s.Text = 'Open Plot Browser';
            % s.Name = 'openplotbrowser';
            % s.Callback = @(x)openplotbrowser(obj,x);
            % s.MultiSelection = false;
            % selectionPopupMenu.addMenuItem(s,2);
            % s.Text = 'Save To File...';
            % s.Name = 'calibrationlist_savetofile';
            % s.Callback = @(x)calibrationlist_savetofile(obj,x);
            % s.MultiSelection = true;
            % selectionPopupMenu.addMenuItem(s,3);
            % s.Text = 'Collect Fringes';
            % s.Name = 'calibrationlist_collectfringes';
            % s.Callback = @(x)calibrationlist_collectfringes(obj,x);
            % s.MultiSelection = false;
            % selectionPopupMenu.addMenuItem(s,4);
            % s.Text = 'Export To Base Workspace';
            % s.Name = 'calibrationlist_exporttobaseworkspace';
            % s.Callback = @(x)calibrationlist_exporttobaseworkspace(obj,x);
            % s.MultiSelection = false;
            % selectionPopupMenu.addMenuItem(s,5);
            % s.Text = 'Calibrate X Axis';
            % s.Name = 'calibrationlist_calibratexaxis';
            % s.Callback = @(x)calibrationlist_calibratexaxis(obj,x);
            % s.MultiSelection = false;
            % selectionPopupMenu.addMenuItem(s,6);
            % s.Text = 'Calibrate Y Axis';
            % s.Name = 'calibrationlist_calibrateyaxis';
            % s.Callback = @(x)calibrationlist_calibrateyaxis(obj,x);
            % s.MultiSelection = false;
            % selectionPopupMenu.addMenuItem(s,7);
            % s.Text = 'Inspect';
            % s.Name = 'calibrationlist_inspect';
            % s.Callback = @(x)calibrationlist_inspect(obj,x);
            % s.MultiSelection = true;
            % selectionPopupMenu.addMenuItem(s,8);
            % %nonselectionPopupMenu.removeMenuItem('RecordCreationMenuItem');
            % nonselectionPopupMenu.removeMenuItem('PasteMenuItem');
            % warning(WarningState);
            % hideColumn(obj.calibrationWorkspaceView,'Value');
            % hideColumn(obj.calibrationWorkspaceView,'Class');
            % hideColumn(obj.calibrationWorkspaceView,'Size');
            % hideColumn(obj.calibrationWorkspaceView,'Bytes');
            
            % Set Spectra popup parameters
            selectionPopupMenu = obj.spectraWorkspaceView.getSelectionPopupMenu;
            nonselectionPopupMenu = obj.spectraWorkspaceView.getNoSelectionPopupMenu;
            WarningState = warning('off','MATLAB:Containers:Map:NoKeyToRemove');
            selectionPopupMenu.removeMenuItem('RecordCopyingMenuItem');
            s.Text = 'Set Acquire Destination';
            s.Name = 'spectralist_setacquiredestination';
            s.Callback = @(x)spectralist_setacquiredestination(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,1);
            s.Text = 'Open Multi Plot Browser';
            s.Name = 'spectralist_openmultiplotbrowser';
            s.Callback = @(x)spectralist_openmultiplotbrowser(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,3);
            s.Text = 'Open FFTPlot Browser';
            s.Name = 'openfftplotbrowser';
            s.Callback = @(x)openfftplotbrowser(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,4);
            s.Text = 'Use for Wavenum Calibration';
            s.Name = 'spectralist_useforwavenumcalibration';
            s.Callback = @(x)spectralist_useforwavenumcalibration(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,5);
            s.Text = 'Perform Spectral Fit';
            s.Name = 'performspectralfit';
            s.Callback = @(x)performspectralfit(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,6);
            s.Text = 'Save To File...';
            s.Name = 'spectralist_savetofile';
            s.Callback = @(x)spectralist_savetofile(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,7);
            s.Text = 'Open Averaging Bar Chart';
            s.Name = 'spectralist_openaveragingbarchart';
            s.Callback = @(x)spectralist_openaveragingbarchart(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,9);
            s.Text = 'Inspect';
            s.Name = 'spectralist_inspect';
            s.Callback = @(x)spectralist_inspect(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,10);
            s.Text = 'Auto Correct DOCO X Axis';
            s.Name = 'spectralist_autocorrectdocoxaxis';
            s.Callback = @(x)spectralist_autocorrectdocoxaxis(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,11);
            s.Text = 'Use X Axis for all spectra';
            s.Name = 'spectralist_usexaxisforallspectra';
            s.Callback = @(x)spectralist_usexaxisforallspectra(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,12);
            s.Text = 'Correct X Axis';
            s.Name = 'spectralist_correctxaxis';
            s.Callback = @(x)spectralist_correctxaxis(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,13);
            
			% Add menu items from contextmenu directory
			%itemIndex = 14;
			menuitems = vipadesktop.getpackagemfiles('spectraobjects.contextmenu');
			for i = 1:numel(menuitems)
				s.Text = eval(sprintf('%s.menuitemText',menuitems{i}));
				s.Name =  eval(sprintf('%s.menuitemName',menuitems{i}));
				f = str2func(sprintf('%s.menucallback',menuitems{i}));
				s.Callback =  @(selecteditems) f(this.Parent,selecteditems);
				s.MultiSelection = eval(sprintf('%s.menuitemMultiSelection',menuitems{i}));
				selectionPopupMenu.addMenuItem(s);
				%itemIndex = itemIndex + 1;
			end
			
            %nonselectionPopupMenu.removeMenuItem('RecordCreationMenuItem');
            nonselectionPopupMenu.removeMenuItem('PasteMenuItem');
            warning(WarningState);
            hideColumn(obj.spectraWorkspaceView,'Value');
            hideColumn(obj.spectraWorkspaceView,'Class');
            hideColumn(obj.spectraWorkspaceView,'Size');
            hideColumn(obj.spectraWorkspaceView,'Bytes');
            
            % Set Fit Spectra popup parameters
            selectionPopupMenu = obj.fitspectraWorkspaceView.getSelectionPopupMenu;
            nonselectionPopupMenu = obj.fitspectraWorkspaceView.getNoSelectionPopupMenu;
            WarningState = warning('off','MATLAB:Containers:Map:NoKeyToRemove');
            selectionPopupMenu.removeMenuItem('RecordCopyingMenuItem');
            s.Text = 'Open Stem Browser';
            s.Name = 'fitspectralist_openstembrowser';
            s.Callback = @(x)fitspectralist_openstembrowser(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,1);
            s.Text = 'Open Simulation Browser';
            s.Name = 'fitspectralist_opensimulationbrowser';
            s.Callback = @(x)fitspectralist_opensimulationbrowser(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,2);
            s.Text = 'Save To File...';
            s.Name = 'fitspectralist_savetofile';
            s.Callback = @(x)fitspectralist_savetofile(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,3);
            s.Text = 'Inspect';
            s.Name = 'fitspectralist_inspect';
            s.Callback = @(x)fitspectralist_inspect(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,4);
            %nonselectionPopupMenu.removeMenuItem('RecordCreationMenuItem');
            nonselectionPopupMenu.removeMenuItem('PasteMenuItem');
            warning(WarningState);
            hideColumn(obj.fitspectraWorkspaceView,'Value');
            hideColumn(obj.fitspectraWorkspaceView,'Class');
            hideColumn(obj.fitspectraWorkspaceView,'Size');
            hideColumn(obj.fitspectraWorkspaceView,'Bytes');
            
            % Set Fits popup parameters
            selectionPopupMenu = obj.fitsWorkspaceView.getSelectionPopupMenu;
            nonselectionPopupMenu = obj.fitsWorkspaceView.getNoSelectionPopupMenu;
            WarningState = warning('off','MATLAB:Containers:Map:NoKeyToRemove');
            selectionPopupMenu.removeMenuItem('RecordCopyingMenuItem');
            s.Text = 'Open Fit Browser';
            s.Name = 'openfitbrowser';
            s.Callback = @(x)openfitbrowser(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,1);
            s.Text = 'Open Fit Browser with Residuals';
            s.Name = 'openfitbrowserwithresiduals';
            s.Callback = @(x)openfitbrowserwithresiduals(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,2);
            s.Text = 'Open Fit Browser with colors';
            s.Name = 'fitslist_openfitbrowserwithcolors';
            s.Callback = @(x)fitslist_openfitbrowserwithcolors(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,3);
            s.Text = 'Plot Fit Coefficients';
            s.Name = 'plotfitcoefficients';
            s.Callback = @(x)plotfitcoefficients(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,4);
            s.Text = 'Plot Grouped Fit Coefficients';
            s.Name = 'plotgroupedfitcoefficients';
            s.Callback = @(x)plotgroupedfitcoefficients(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,5);
            s.Text = 'Export DOCO Globals';
            s.Name = 'exportDOCOglobals';
            s.Callback = @(x)exportDOCOglobals(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,6);
            s.Text = 'Export to SimBiology';
            s.Name = 'exportToSimbiology';
            s.Callback = @(x)exportToSimBiology(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,7);
            s.Text = 'Run Fit Analysis Function';
            s.Name = 'runfitanalysisfunction';
            s.Callback = @(x)runfitanalysisfunction(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,8);
            s.Text = 'Save To File...';
            s.Name = 'fitslist_savetofile';
            s.Callback = @(x)fitslist_savetofile(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,9);
            s.Text = 'Set Initial Conditions';
            s.Name = 'fitslist_setinitialconditions';
            s.Callback = @(x)fitslist_setinitialconditions(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,10);
            s.Text = 'Inspect';
            s.Name = 'fitslist_inspect';
            s.Callback = @(x)fitslist_inspect(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,11);
            %nonselectionPopupMenu.removeMenuItem('RecordCreationMenuItem');
            nonselectionPopupMenu.removeMenuItem('PasteMenuItem');
            warning(WarningState);
            hideColumn(obj.fitsWorkspaceView,'Value');
            hideColumn(obj.fitsWorkspaceView,'Class');
            hideColumn(obj.fitsWorkspaceView,'Size');
            hideColumn(obj.fitsWorkspaceView,'Bytes');
            
            % Set Kinetics Models Parameters
            selectionPopupMenu = obj.kineticsmodelsWorkspaceView.getSelectionPopupMenu;
            nonselectionPopupMenu = obj.kineticsmodelsWorkspaceView.getNoSelectionPopupMenu;
            WarningState = warning('off','MATLAB:Containers:Map:NoKeyToRemove');
            selectionPopupMenu.removeMenuItem('RecordCopyingMenuItem');
            s.Text = 'Open Simulation Browser';
            s.Name = 'kineticsmodelslist_opensimulationbrowser';
            s.Callback = @(x)kineticsmodelslist_opensimulationbrowser(obj,x);
            s.MultiSelection = false;
            selectionPopupMenu.addMenuItem(s,1);
            s.Text = 'Save To File...';
            s.Name = 'kineticsmodelslist_savetofile';
            s.Callback = @(x)kineticsmodelslist_savetofile(obj,x);
            s.MultiSelection = true;
            selectionPopupMenu.addMenuItem(s,2);
            %nonselectionPopupMenu.removeMenuItem('RecordCreationMenuItem');
            nonselectionPopupMenu.removeMenuItem('PasteMenuItem');
            warning(WarningState);
            hideColumn(obj.kineticsmodelsWorkspaceView,'Value');
            hideColumn(obj.kineticsmodelsWorkspaceView,'Class');
            hideColumn(obj.kineticsmodelsWorkspaceView,'Size');
            hideColumn(obj.kineticsmodelsWorkspaceView,'Bytes');
        end
    end
end

function openimagebrowser(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('openimagebrowser',src.Variables));
end

function openplotbrowser(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('openplotbrowser',src.Variables));
end

function openfftplotbrowser(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('openfftplotbrowser',src.Variables));
end

function performspectralfit(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('performspectralfit',src.Variables));
end

function openfitbrowser(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('openfitbrowser',src.Variables));
end

function openfitbrowserwithresiduals(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('openfitbrowserwithresiduals',src.Variables));
end

function plotfitcoefficients(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('plotfitcoefficients',src.Variables));
end

function plotgroupedfitcoefficients(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('plotgroupedfitcoefficients',src.Variables));
end

function exportDOCOglobals(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('exportDOCOglobals',src.Variables));
end

function exportToSimBiology(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('exportToSimBiology',src.Variables));
end

function acquiresingleimage(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('acquiresingleimage',src.Variables));
end

function acquirekineticsimages(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('acquirekineticsimages',src.Variables));
end

function createcalibration(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('createcalibration',src.Variables));
end

function collectfringes(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('collectfringes',src.Variables));
end

function runfitanalysisfunction(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('fitslist_runfitanalysisfunction',src.Variables));
end

function fitslist_savetofile(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('fitslist_savetofile',src.Variables));
end

function fitspectralist_savetofile(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('fitspectralist_savetofile',src.Variables));
end

function spectralist_savetofile(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('spectralist_savetofile',src.Variables));
end

function calibrationlist_savetofile(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('calibrationlist_savetofile',src.Variables));
end

function imageslist_savetofile(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('imageslist_savetofile',src.Variables));
end

function fitslist_setinitialconditions(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('fitslist_setinitialconditions',src.Variables));
end

function imageslist_setacquiredestination(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('imageslist_setacquiredestination',src.Variables));
end

function calibrationlist_setacquirecalibration(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('calibrationlist_setacquirecalibration',src.Variables));
end

function spectralist_setacquiredestination(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('spectralist_setacquiredestination',src.Variables));
end

function calibrationlist_collectfringes(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('calibrationlist_collectfringes',src.Variables));
end

function imageslist_createspectra(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('imageslist_createspectra',src.Variables));
end

function imageslist_useasrefimage(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('imageslist_useasrefimage',src.Variables));
end

function imageslist_useassigimage(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('imageslist_useassigimage',src.Variables));
end

function calibrationlist_exporttobaseworkspace(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('calibrationlist_exporttobaseworkspace',src.Variables));
end

function imageslist_exporttobaseworkspace(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('imageslist_exporttobaseworkspace',src.Variables));
end

function spectralist_exporttobaseworkspace(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('spectralist_exporttobaseworkspace',src.Variables));
end

function imageslist_averageimages(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('imageslist_averageimages',src.Variables));
end

function imageslist_openlineprofilebrowser(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('imageslist_openlineprofilebrowser',src.Variables));
end

function calibrationlist_calibratexaxis(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('calibrationlist_calibratexaxis',src.Variables));
end

function calibrationlist_calibrateyaxis(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('calibrationlist_calibrateyaxis',src.Variables));
end

function fitspectralist_opensimulationbrowser(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('fitspectralist_opensimulationbrowser',src.Variables));
end

function fitspectralist_openstembrowser(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('fitspectralist_openstembrowser',src.Variables));
end

function spectralist_openaveragingbarchart(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('spectralist_openaveragingbarchart',src.Variables));
end

function spectralist_useforwavenumcalibration(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('spectralist_useforwavenumcalibration',src.Variables));
end

function imageslist_inspect(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('imageslist_inspect',src.Variables));
end

function calibrationlist_inspect(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('calibrationlist_inspect',src.Variables));
end

function spectralist_inspect(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('spectralist_inspect',src.Variables));
end

function fitspectralist_inspect(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('fitspectralist_inspect',src.Variables));
end

function fitslist_inspect(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('fits_inspect',src.Variables));
end

function spectralist_autocorrectdocoxaxis(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('spectralist_autocorrectdocoxaxis',src.Variables));
end

function spectralist_correctxaxis(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('spectralist_correctxaxis',src.Variables));
end

function fitslist_openfitbrowserwithcolors(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('fitslist_openfitbrowserwithcolors',src.Variables));
end

function spectralist_usexaxisforallspectra(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('spectralist_usexaxisforallspectra',src.Variables));
end

function spectralist_openmultiplotbrowser(obj,src)
    notify(obj,'ComponentRequest',vipadesktop.DataBrowserEventData('spectralist_openmultiplotbrowser',src.Variables));
end