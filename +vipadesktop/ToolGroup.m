classdef ToolGroup < toolpack.component.component
  % Tool group component.
  %
  % Example:
  %   name = 'grp1';
  %   title = 'Test Application';
  %
  %   grp = toolpack.desktop.ToolGroup
  %   grp = toolpack.desktop.ToolGroup(name)
  %   grp = toolpack.desktop.ToolGroup(name, title)
  %
  %   grp.open
  %
  % See also toolpack.desktop.ToolStrip.
  
  % Author(s): Bora Eryilmaz
  % Revised:
  % Copyright 2010-2014 The MathWorks, Inc.
  
  % ----------------------------------------------------------------------------
  properties (Dependent, Access = public)
    % Component title (string, default = '')
    Title
  end
  
  properties (Dependent, GetAccess = public, SetAccess = private)
    % Component's tabs (nx1 cell array of strings, default = cell(0,1))
    TabNames
  end
  
  properties (Dependent, Access = public, SetObservable, AbortSet)
    % Name of the currently selected tab (string, default = '')
    SelectedTab
  end
  
  % ----------------------------------------------------------------------------
  properties (Access = private)
    % Handling of clients (figures) with contextual tabs
    ClientMap = cell(0,3) % {figure, tabgroup, selectedtab; ...}
    ClientActionListener
    ActiveClient
    ActiveClientTabs
    ActiveClientTabGroupListener
    
    % Holds the FigureDropTargetHandler object
    FiguresDropTargetHandler
  end
  
  % ----------------------------------------------------------------------------
  events
    % Event fired upon changes to the group's clients.
    ClientAction
    % Event fired upon changes to the group.
    GroupAction
  end
  
  % ----------------------------------------------------------------------------
  methods
    function this = ToolGroup(name, title)
      % Creates a tool group component.
      this = this@toolpack.component.component;
      cls = 'com.mathworks.toolbox.shared.controllib.desktop.ToolGroupWrapper';
      if nargin == 0
        % ToolGroup()
        this.Peer = javaObjectEDT(cls, 'name', 'Title'); % Title cannot be empty.
      elseif nargin == 1
        % ToolGroup(name)
        this.Peer = javaObjectEDT(cls, name, 'Title'); % Title cannot be empty.
      else
        % ToolTab(name, title)
        this.Peer = javaObjectEDT(cls, name, title);
      end
      addAttributeListener( this, {@handleAttribute, this} )
      addClientListener( this, {@handleClientAction, this} )
      addGroupListener( this,  {@handleGroupAction, this} )
      
      this.FiguresDropTargetHandler = toolpack.databrowser.FiguresDropTargetHandler;
    end
    
    function value = get.Title(this)
      % GET function for Title property.
      value = char(this.Peer.getTitle);
    end
    
    function set.Title(this, value)
      % SET function for Title property.
      if isempty(value)
        value = '';
      elseif ~ischar(value)
        ctrlMsgUtils.error('Controllib:toolpack:StringArgumentNeeded')
      end
      this.Peer.setTitle(value);
    end
    
    function value = get.SelectedTab(this)
      % GET function for SelectedTab property.
      value = char(this.Peer.getCurrentTab);
    end
    
    function set.SelectedTab(this, value)
      % SET function for SelectedTab property.
      if isempty(value)
        value = '';
      elseif ~ischar(value)
        ctrlMsgUtils.error('Controllib:toolpack:StringArgumentNeeded')
      end
      % Break Java --> MCOS -->x Java loop
      % if ~strcmp(value, char(this.Peer.getCurrentTab))
      %   drawnow
      this.Peer.setCurrentTab(value);
      %   drawnow;
      % end
    end
    
    function tabs = get.TabNames(this)
      % GET function for TabNames property.
      n = length(this.Children);
      tabs = cell(n,1);
      for k = 1:n
        tab = this.Children(k);
        m = this.Peer.indexOf( tab.Peer.getWrappedComponent ) + 1;
        tabs{m} = tab.Name;
      end
    end
    
    function tab = get(this, arg)
      % Returns the tab with specified name or index, or [] if not found.
      if ischar(arg)
        % get(name)
        name = arg;
      else
        % get(index)
        index = arg;
        name = char(this.Peer.get(index-1).getName);
      end
      tab = tree_search(this, name);
    end
    
    function varargout = add(this, tab, index)
      % Adds the specified tab at given index, if specified.
      % Returns true if component has been added.
      if nargin < 3
        % add(tab)
        added = this.Peer.add( tab.Peer.getWrappedComponent );
      else
        % add(tab, index)
        added = this.Peer.add( tab.Peer.getWrappedComponent, index-1 );
      end
      if added
        add@toolpack.component.component(this, tab);
      end
      if nargout > 0
        varargout{1} = added;
      end
    end
    
    function varargout = remove(this, tab)
      % Removes the specified tab.
      % Returns true if component has been removed.
      removed = this.Peer.remove( tab.Peer.getWrappedComponent );
      if removed
        remove@toolpack.component.component(this, tab);
      end
      if nargout > 0
        varargout{1} = removed;
      end
    end
    
    function moved = move(this, srcidx, dstidx)
      % Moves the tab at location SRCIDX to destination DSTIDX in original list.
      % Returns true if component has been moved.
      moved = this.Peer.move(srcidx-1, dstidx-1);
    end
  end
  
  methods
    function tab = addTab(this, name, title)
      % Adds a tab with the specified name and title.
      this.removeTab(name); % In case there is already a tab with same name.
      tab = toolpack.desktop.ToolTab(name, title);
      this.add(tab);
    end
    
    function tab = removeTab(this, name)
      % Removes the tab with the specified name.
      tab = this.get(name);
      if ~isempty(tab)
        this.remove(tab);
      end
    end
    
    function setCollapsible(this, collapsible)
      % Sets the visibility status of the collapse button.
      this.Peer.setCollapsable(collapsible);
    end
    
    function collapsible = isCollapsible(this)
      % Returns the visibility status of the collapse button.
      collapsible = this.Peer.isCollapsable;
    end
    
    function addActionComponent(this, c)
      % Adds the JAVA component to the actions panel on the tab bar.
      this.Peer.addActionsPanel(c);
    end
    
    function removeActionComponent(this, c)
      % Removes the JAVA component from the actions panel on tab bar.
      this.Peer.removeActionsPanel(c);
    end
  end
  
  methods
    function open(this)
      % Opens the desktop group.
      this.Peer.open
    end
    
    function close(this)
      % Removes the desktop group from the desktop.
      md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
      md.closeGroup(this.Name);
    end
    
    function delete(this)
      % Deletes the handle, also removing the group from the desktop.
      delete(this.Listeners) % Delete client and group listeners
      this.close;
    end
    
    function setWaiting(this, state, comps)
      % Sets the waiting state of the frame containing the tool group,
      % optionally keeping live access to specified components.
      %
      % If specified, COMPS is an array of toolpack.component.* objects.
      md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
      frame = md.getFrameContainingGroup(this.Name);
      if ~md.isGroupDocked(this.Name) && ~isempty(frame)
        gc = 'com.mathworks.mwswing.GlobalCursor';
        if state
          if nargin > 2 && ~isempty(comps)
            list = java.util.ArrayList;
            for n = 1:length(comps)
              list.add(comps(n).Peer);
            end
            javaMethodEDT('setWait', gc, frame, list);
          else
            javaMethodEDT('setWait', gc, frame);
          end
        else
          javaMethodEDT('clear', gc, frame);
        end
      end
    end
    
    function b = isClosingApprovalNeeded(this)
      % Return whether the group needs approval or veto before closing.
      b = this.Peer.isClosingApprovalNeeded;
    end
    
    function setClosingApprovalNeeded(this, b)
      % Set to true if the group needs approval or veto before closing.
      this.Peer.setClosingApprovalNeeded(b);
    end
    
    function approveClose(this)
      % Approve the closing of the ToolGroup. Call after receiving a group
      % CLOSING event.
      this.Peer.approveGroupClose;
    end
    
    function vetoClose(this)
      % Veto the closing of the ToolGroup. Call after receiving a group CLOSING
      % event.
      this.Peer.vetoGroupClose;
    end
    
    function setDefaultLocation(this)
      % Move the group to its default location.
      this.Peer.setDefaultLocation;
    end
    
    function setDataBrowser(this, panel)
      % Places the specified (Java) panel in the singleton client location.
      this.Peer.setPanel(panel);
      % REM: Modify to take a TSPanel object instead:
      % this.Peer.setPanel(panel.Peer)
    end
    
    function addFigure(this, fig)
      % Add figure to ToolGroup as a document client.
      set(fig, 'MenuBar', 'none')
      set(fig, 'ToolBar', 'none')
      hWarn = ctrlMsgUtils.SuspendWarnings('MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame'); %#ok<NASGU>
      jf = get(fig, 'JavaFrame');
      md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
      jf.setDesktopGroup(md, this.Name)
      set(fig, 'WindowStyle', 'Docked')
      this.FiguresDropTargetHandler.registerInterest(handle(fig));
    end

    function addClientTabGroup(this, client, tabgroup)
    % Sets association of contextual tabs with a client (figure).
      this.setClientTabGroup(client, tabgroup);
      if isempty(this.ClientActionListener)
        % Only one listener is sufficient.
        this.ClientActionListener = addlistener(this, 'ClientAction', ...
                                    @(hSrc,hData) handleClientModes(this,hData));
      end
    end
    
    function removeClientTabGroup(this, client)
    % Removes association of contextual tabs with a client (figure).
      if this.ActiveClient == client
        setActiveClient(this, [])
      end

      k = findClientIndex(this,client);
      if k > 0
          this.ClientMap(k,:) = [];
      end

      if isempty(this.ClientMap)
        % No clients left to listen to their actions
        delete(this.ClientActionListener)
        this.ClientActionListener = [];
      end
    end

    function value = isClientShowing(this, name)
      % Returns true if the client bearing the given name or title is currently
      % being shown by the desktop.  The fact the a client is "showing" in the
      % desktop doesn't mean it is actually visible on screen.  It may be in a
      % tabbed pane or in a minimized frame.
      md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
      value = md.isClientShowing(name, this.Name);
    end
    
    function showClient(this, name)
      % Shows and activates a client component referenced by its name or title.
      md = com.mathworks.mlservices.MatlabDesktopServices.getDesktop;
      md.showClient(name, this.Name);
    end
    
    function r = getFiguresDropTargetHandler(this)
      r = this.FiguresDropTargetHandler;
    end
  end
  
  methods (Access = private)
    function addAttributeListener(this, fcn)
      % Do not modify. Use as is to prevent Java memory leaks.
      L = addlistener(this.Peer.getAttributeCallback, 'delayed', fcn);
      this.Listeners = [this.Listeners; L];
    end
    
    function addClientListener(this, fcn)
      % Do not modify. Use as is to prevent Java memory leaks.
      L = addlistener(this.Peer.getClientCallback, 'delayed', fcn);
      this.Listeners = [this.Listeners; L];
    end
    
    function addGroupListener(this, fcn)
      % Do not modify. Use as is to prevent Java memory leaks.
      L = addlistener(this.Peer.getGroupCallback, 'delayed', fcn);
      this.Listeners = [this.Listeners; L];
    end

    function index = findClientIndex(this,client)
    % Returns the index of the client in the ClientMap, or 0 if client
    % is not listed in the ClientMap.
      index = 0;
      for k = 1:size(this.ClientMap,1)
          if this.ClientMap{k,1} == client
              index = k;
              return
          end
      end
    end
    
    function tabgroup = getClientTabGroup(this, client)
    % Returns the tab group associated with a client (figure) or [] if 
    % the client does not exist within the ToolGroup.
      tabgroup = [];
      k = findClientIndex(this,client);
      if k > 0
          tabgroup = this.ClientMap{k,2};
      end
    end
    
    function setClientTabGroup(this, client, tabgroup)
    % Sets the tab group for the specified client, either by replacing an
    % existing tab group or adding it for a new client.
      found = false;
      k = findClientIndex(this,client);
      if k > 0
          this.ClientMap{k,2} = tabgroup;
          found = true;
      end
      % Add new (client,tabgroup,selectedtab) tuple
      if ~found
        this.ClientMap = [this.ClientMap; {client, tabgroup, ''}];
      end
    end

    function handleClientModes(this, hData)
      % Handle contextual tabs in response to client events.
      data = hData.EventData;
      client = data.Client;
      
      % Only figure client actions should change contextual tabs
      if isempty(client)
        % Not a figure client
        return
      end
      
      if strcmp(data.EventType, 'ACTIVATED')
        activeClient = [];
        % Find new active client, if any.
        k = findClientIndex(this, client);
        if k > 0
            activeClient = client;
        end
        setActiveClient(this, activeClient)
      elseif strcmp(data.EventType, 'CLOSING')
        % Remove the closing client's tab group, if any.
        k = findClientIndex(this, client);
        if k > 0
            this.removeClientTabGroup(client);
        end
      end
    end
    
    function setActiveClient(this, client)
      if isempty(client)
        if ~isempty(this.ActiveClient)
          % Remove old active client's tabs
          tabs = this.ActiveClientTabs;
          for k = length(tabs):-1:1
            this.remove(tabs(k))
          end
        end
        this.ActiveClientTabs = [];
      else
        tabgroup = this.getClientTabGroup(client);
        
        if ~isempty(this.ActiveClient)
          if (this.ActiveClient ~= client)
            % Remove old active client's tabs
            tabs = this.ActiveClientTabs;
            for k = length(tabs):-1:1
              this.remove(tabs(k))
            end
         
            % Add new client's tabs
            tabs = tabgroup.Tabs;
            for k = 1:length(tabs)
              this.add(tabs(k))
            end
            
            % Update selected tab from tab group or client map from
            % selected tab.
            k = findClientIndex(this, client);
            if k > 0
                if ~isempty(tabgroup.SelectedTab)
                    this.SelectedTab = tabgroup.SelectedTab.Name;
                elseif ~isempty(this.ClientMap{k,3})
                    this.SelectedTab = this.ClientMap{k,3};
                else
                    this.ClientMap{k,3} = this.SelectedTab;
                end
            end
          end
        else
          % Add new client's tabs
          tabs = tabgroup.Tabs;
          for k = 1:length(tabs)
            this.add(tabs(k))
          end
          
          % Update selected tab from tab group or client map from
          % selected tab.
          k = findClientIndex(this, client);
          if k > 0
              if ~isempty(tabgroup.SelectedTab)
                  this.SelectedTab = tabgroup.SelectedTab.Name;
              elseif ~isempty(this.ClientMap{k,3})
                  this.SelectedTab = this.ClientMap{k,3};
              else
                  this.ClientMap{k,3} = this.SelectedTab;
              end
          end
        end
        this.ActiveClientTabs = tabgroup.Tabs;
      end
      this.ActiveClient = client;
      
      delete(this.ActiveClientTabGroupListener)
      this.ActiveClientTabGroupListener = [];
      if ~isempty(this.ActiveClient)
        tabgroup = this.getClientTabGroup(client);
        L = event.listener( tabgroup, 'TabsChanged', ...
                            @(hSrc,hData) handleActiveClientTabs(this) );
        this.ActiveClientTabGroupListener = L;
      end
    end
    
    function handleActiveClientTabs(this)
    % Refresh tabs of the active client if there are any changes reported
    % through a TabsChanged event.
      for t = this.ActiveClientTabs(:)'
        this.remove(t);
      end

      tabgroup = this.getClientTabGroup(this.ActiveClient);
      tabs = tabgroup.Tabs;
      for t = tabs(:)'
        this.add(t)
      end
      this.ActiveClientTabs = tabs;
      
      if ~isempty(tabgroup.SelectedTab)
        this.SelectedTab = tabgroup.SelectedTab.Name;
      end
    end
  end
end

% ------------------------------------------------------------------------------
function handleAttribute(~,ed,obj)
% SELECTED_TAB attribute has changed.
  tabname = char(ed.getNewValue);
  if ~isempty(obj.ActiveClient)
    % Update the active tab group's selected tab
    tabgroup = obj.getClientTabGroup(obj.ActiveClient);
    tabs = tabgroup.Tabs;
    tab = [];
    for k = 1:length(tabs)
      if strcmp(tabs(k).Name, tabname)
        tab = tabs(k);
        break
      end
    end
    tabgroup.SelectedTab = tab;
    % Update selected tab name in ClientMap
    k = findClientIndex(obj,obj.ActiveClient);
    if k > 0
        obj.ClientMap{k,3} = tabname;
    end
  end
end

function handleClientAction(~,ed,obj)
types = { ...
  'ACTIVATING', 'ACTIVATED', 'DEACTIVATED', 'DOCKING', ...
  'DOCKED', 'UNDOCKING', 'UNDOCKED', 'RELOCATED', ...
  'RESIZED', 'OPENED', 'CLOSING', 'CLOSED'};
c = ed.getClient;
title = char(c.getClientProperty(com.mathworks.widgets.desk.DTClientProperty.TITLE));
data = struct( ...
  'Client', utGetFigureHandleFromClient(c), ...
  'ClientName', char(c.getName), ...
  'ClientTitle', title, ...
  'EventType', types{ed.getType});
obj.notify('ClientAction', toolpack.ComponentEventData(data))
end

function handleGroupAction(~,ed,obj)
types = { ...
  'ACTIVATING', 'ACTIVATED', 'DEACTIVATED', 'DOCKING', ...
  'DOCKED', 'UNDOCKING', 'UNDOCKED', 'RELOCATED', ...
  'RESIZED', 'OPENED', 'CLOSING', 'CLOSED'};
g = ed.getPropertyProvider;
data = struct( ...
  'GroupName', char(g.getGroupName), ...
  'GroupTitle', char(g.getGroupTitle), ...
  'EventType', types{ed.getType});
obj.notify('GroupAction', toolpack.ComponentEventData(data))
end

function fig = utGetFigureHandleFromClient(client)
% Finds the figure that has the specified client or return empty if there is no
% matching figure.
hWarn = ctrlMsgUtils.SuspendWarnings('MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame'); %#ok<NASGU>
ch = allchild(0);
cls = 'com.mathworks.hg.peer.FigureClientProxy$FigureDTClientBase';
for i = 1:length(ch)
  fig = ch(i);
  jf = get(fig, 'JavaFrame');
  c = jf.getFigurePanelContainer;
  while ~( isempty(c) || isa(c,cls) )
    % Move up the hierarchy to find a figure client or a component with no
    % parent.
    c = c.getParent;
  end
  
  if isequal(c, client)
    % Found figure with matching client. Return with current FIG handle.
    return
  end
end
% No figure has a matching client.
fig = [];
end
