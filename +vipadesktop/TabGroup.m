classdef TabGroup < handle
  % Tab group component to store a number of related, contextual tabs.
  %
  % Example:
  %   tabgrp = toolpack.desktop.TabGroup;
  %   tab1 = toolpack.desktop.ToolTab('tab1', 'Tab 1');
  %   tab2 = toolpack.desktop.ToolTab('tab2', 'Tab 2');
  %   tabgrp.Tabs = [tab1, tab2];
  %
  % See also toolpack.desktop.ToolTab
  
  % Author(s): Bora Eryilmaz
  % Revised:
  % Copyright 2013 The MathWorks, Inc.
  
  % ----------------------------------------------------------------------------
  properties (Dependent, Access = public)
    % Tabs in the tab group (nx1 array of ToolTab objects, default = [])
    Tabs
    
    % The selected tab within the tab group (ToolTab, default = [])
    SelectedTab = [];
  end
  
  properties (Access = private)
    Tabs_
    SelectedTab_
  end
  
  % ----------------------------------------------------------------------------
  events
    TabsChanged
  end
  
  % ----------------------------------------------------------------------------
  methods
    function this = TabGroup()
      % Creates a tab group component.
    end
    
    function value = get.Tabs(this)
      % GET function for Tabs property.
      value = this.Tabs_;
    end
    
    function set.Tabs(this, tabs)
      % SET function for Tabs property
      if isempty(tabs)
        tabs = [];
      elseif ~isa(tabs, 'toolpack.desktop.ToolTab')
        error(message('Controllib:toolpack:InvalidPropertyValue', 'Tabs'))
      end
      this.Tabs_ = tabs(:);
      
      % Don't change the selected tab, unless it is not there anymore.
      if ~isempty(this.SelectedTab_) && ~any(this.SelectedTab_ == tabs)
        this.SelectedTab_ = [];
      end
    end
    
    function value = get.SelectedTab(this)
      % GET function for SelectedTab property.
      value = this.SelectedTab_;
    end
    
    function set.SelectedTab(this, value)
      % SET function for SelectedTab property.
      if isempty(value)
        value = [];
      elseif ~isa(value, 'toolpack.desktop.ToolTab') || ~any(this.Tabs_ == value)
        error(message('Controllib:toolpack:InvalidPropertyValue', 'SelectedTab'))
      end
      this.SelectedTab_ = value;
    end
  end
end
