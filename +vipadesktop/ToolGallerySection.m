classdef ToolGallerySection < toolpack.component.component
    % Toolstrip gallery section
    %
    % Example:
    %   items(1) = struct(...
    %     'Title', 'Custom Plots', ...
    %     'Description', '', ...
    %     'Icon', [], ...
    %     'Header', true, ...
    %     'Callback',[]);
    %   items(2) = struct(...
    %     'Title', 'Remove Plot', ...
    %     'Description', 'Removes a plot', ...
    %     'Icon', toolpack.component.Icon.PRINT, ...
    %     'Header', false, ...
    %     'Callback', {{@(x,y)disp(y.Title)}});
    %
    %   options = struct(...
    %     'RowCount',1,...
    %     'MinColumnCount',5,...
    %     'LabelLineCount',1,...
    %     'ColumnWidth',1);
    %
    %   gallery = toolpack.desktop.ToolGallerySection('name', 'title', items)
    %   gallery = toolpack.desktop.ToolGallerySection('name', 'title', items, options)
    
    % Author(s): Erman Korkut
    % Revised: Bora Eryilmaz
    % Copyright 2010-2014 The MathWorks, Inc.
    
    % ----------------------------------------------------------------------------
    properties (Dependent, Access = public)
        % Index of currenly selected item (integer, default = 0)
        SelectedIndex
    end
    
    properties (Access = private)
        Gallery
        Model
        Actions
        ActionListeners = cell(0,1);
    end
    
    % ----------------------------------------------------------------------------
    % Public methods
    methods
        function this = ToolGallerySection(name, title, items, options)
            % Creates a toolstrip gallery associated with a component.
            
            this = this@toolpack.component.component;
            if nargin < 4
                % toolpack.component.ToolGallerySection(name,title,items)
                options = struct('RowCount',1,...
                    'MinColumnCount',5,...
                    'LabelLineCount',1,...
                    'ColumnWidth',1,...
                    'EnableSearch',true,...
                    'SupportFavorites',false);
            else
                % toolpack.component.ToolGallerySection(name,title,items, options)
                options.SupportFavorites = false; % No support for favorites yet
            end
            % Create the section
            cls = 'com.mathworks.toolbox.shared.controllib.desktop.ToolGallerySectionWrapper';
            this.Peer = javaObjectEDT(cls, name, title);
            % Create the model
            cls = 'com.mathworks.toolstrip.components.gallery.model.DefaultGalleryModel';
            this.Model = javaObjectEDT(cls);
            % Create the gallery
            resetItems(this,items);
            cls = 'com.mathworks.toolstrip.components.gallery.view.GalleryView';
            this.Gallery = javaObjectEDT(cls, this.Model, LocalCreateJavaOptions(options));
            % Add gallery to the section
            add(this.Peer,this.Gallery);
        end
        
        function resetItems(this,items)
            % resetItems(this, NEWITEMS) resets the gallery items to the
            % new set specified by NEWITEMS.
            
            % Reset current actions
            this.Actions = [];
            this.ActionListeners = cell(0,1);
            javaMethodEDT('clear',this.Model);
            for ct = 1:numel(items)
                if items(ct).Header
                    cls = 'com.mathworks.toolstrip.components.gallery.model.Category';
                    cat = javaObjectEDT(cls,items(ct).Title,items(ct).Title);
                else
                    cls = 'com.mathworks.toolbox.shared.controllib.desktop.GalleryAction';
                    action = javaObjectEDT(cls, items(ct).Title,items(ct).Description, items(ct).Icon.Peer);
                    cls = 'com.mathworks.toolstrip.components.gallery.model.Item';
                    thisitem = javaObjectEDT(cls, items(ct).Title, action, []);
                    javaMethodEDT('addItem',this.Model,cat,thisitem);
                    this.Actions = [this.Actions; action];
                    this.ActionListeners{end+1} = ...
                        handle.listener(handle(getCallback(action)), 'delayed',...
                        {@LocalCbBridge, items(ct), items(ct).Callback, this, action});
                end
            end
        end
        
        function setOverlayText(this,str)
            % SETOVERLAYTEXT Show overlay text on the Gallery
            if isempty(str)
                javaMethodEDT('setEnabled', this.Gallery,true);
                javaMethodEDT('setOverlayText', this.Gallery,[]);
            else
                javaMethodEDT('setEnabled', this.Gallery,false);
                javaMethodEDT('setOverlayText', this.Gallery,str);
            end
        end
        
        function setBusy(this,bool)
            % SETBUSY Show the busy indicator on the Gallery
            javaMethodEDT('setBusy', this.Gallery,bool);
        end
        
        function index = get.SelectedIndex(this)
            % GET function for SelectedIndex property.
            index = 0;
            actions = this.Actions;
            for k = 1:length(actions)
                if actions(k).isSelected
                    index = k;
                    return
                end
            end
        end
        
        function set.SelectedIndex(this, index)
            % SET function for SelectedIndex property.
            actions = this.Actions;
            if index < 0 || index > length(actions)
                error(message('Controllib:toolpack:InvalidPropertyValue', 'SelectedIndex'))
            elseif index == 0
                % Clear selection
                for k = 1:length(actions)
                    actions(k).setSelected(false);
                end
            else
                for k = 1:length(actions)
                    actions(k).setSelected(k==index);
                end
            end
        end
    end
    
    methods (Access = protected)
        function value = getEnabled_(this)
            % Overloaded to work with the GalleryView component instead of the Peer.
            value = this.Gallery.isEnabled;
        end
        
        function setEnabled_(this, value)
            % Overloaded to work with the GalleryView component instead of the Peer.
            this.Gallery.setEnabled(value);
        end
    end
end

% ------------------------------------------------------------------------------
% Local functions
function opt = LocalCreateJavaOptions(options)
cls = 'com.mathworks.toolstrip.components.gallery.GalleryOptions';
opt = javaObjectEDT(cls);
opts = fieldnames(options);
for ct = 1:numel(opts)
    javaMethodEDT(sprintf('set%s',opts{ct}),opt,options.(opts{ct}));
end

end

function LocalCbBridge(es,~,item,fcn,this,action)
for k = 1:length(this.Actions)
    this.Actions(k).setSelected(this.Actions(k)==action);
end
feval( fcn{1}, java(es), item, fcn{2:end} );
end
