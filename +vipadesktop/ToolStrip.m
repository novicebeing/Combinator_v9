classdef ToolStrip < toolpack.component.component
  % Tool strip component.
  %
  % See also toolpack.desktop.ToolGroup, toolpack.desktop.ToolTab.
  
  % Author(s): Bora Eryilmaz
  % Revised:
  % Copyright 2010-2011 The MathWorks, Inc.
  
  % ----------------------------------------------------------------------------
  properties (Dependent, GetAccess = public, SetAccess = private)
    % Component's tabs (nx1 cell array of strings, default = cell(0,1))
    TabNames
  end
  
  properties (Dependent, Access = public)
    % Name of the currently selected tab (string, default = '')
    SelectedTab
  end
  
  % ----------------------------------------------------------------------------
  % Public methods
  methods
    function this = ToolStrip(name)
      % Creates a tool strip component.
      %
      % Example:
      %   name = 'ts1';
      %
      %   ts = toolpack.desktop.ToolStrip
      %   ts = toolpack.desktop.ToolStrip(name)
      
      this = this@toolpack.component.component;
      cls = 'com.mathworks.toolbox.shared.controllib.desktop.ToolStripWrapper';
      if nargin == 0
        % ToolStrip()
        this.Peer = javaObjectEDT(cls);
      else
        % ToolStrip(name)
        this.Peer = javaObjectEDT(cls, name);
      end
    end
    
    function value = get.SelectedTab(this)
      % GET function for CurrentTab property.
      value = char(this.Peer.getCurrentTab);
    end
    
    function set.SelectedTab(this, value)
      % SET function for CurrentTab property.
      if isempty(value)
        value = '';
      elseif ~ischar(value)
        ctrlMsgUtils.error('Controllib:toolpack:StringArgumentNeeded')
      end
      this.Peer.setCurrentTab(value);
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
end
