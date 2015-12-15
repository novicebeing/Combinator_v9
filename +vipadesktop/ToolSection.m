classdef ToolSection < toolpack.component.component
  % Tool section component.
  %
  % See also toolpack.desktop.ToolTab.
  
  % Author(s): Bora Eryilmaz
  % Revised:
  % Copyright 2010 The MathWorks, Inc.
  
  % ----------------------------------------------------------------------------
  properties (Dependent, Access = public)
    % Component's title (string, default = '')
    Title
  end
  
  % ----------------------------------------------------------------------------
  % Public methods
  methods
    function this = ToolSection(name, title, comp)
      % Creates a tool section component.
      %
      % Example:
      %   name = 'sec1';
      %   title = 'Tool Settings';
      %   comp = toolpack.component.TSButton('Apply')
      %
      %   sec = toolpack.desktop.ToolSection
      %   sec = toolpack.desktop.ToolSection(name)
      %   sec = toolpack.desktop.ToolSection(name, title)
      %   sec = toolpack.desktop.ToolSection(name, title, comp)
      
      this = this@toolpack.component.component;
      cls = 'com.mathworks.toolbox.shared.controllib.desktop.ToolSectionWrapper';
      if nargin == 0
        % ToolSection()
        this.Peer = javaObjectEDT(cls, '', '');
      elseif nargin == 1
        % ToolSection(name)
        this.Peer = javaObjectEDT(cls, name, '');
      elseif nargin == 2
        % ToolSection(name, title)
        this.Peer = javaObjectEDT(cls, name, title);
      else
        % ToolSection(name, title, comp)
        this.Peer = javaObjectEDT(cls, name, title);
        add(this, comp);
      end
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
    
    function component = get(this)
      % Returns the component in the section or [] if there isn't one.
      if ~isempty(this.Peer.get)
        name = char(this.Peer.get.getName);
        component = tree_search(this, name);
      else
        component = [];
      end
    end
    
    function varargout = add(this, comp)
      % Adds the specified component to the section.
      % Returns true if component has been added.
      if ~isempty(this.get)
        % Remove current component, if any.
        this.remove(this.get)
      end
      added = this.Peer.add(comp.Peer);
      if added
        add@toolpack.component.component(this, comp);
      end
      if nargout > 0
        varargout{1} = added;
      end
    end
    
    function varargout = remove(this, comp)
      % Removes the specified component from the section.
      % Returns true if component has been removed.
      removed = this.Peer.remove(comp.Peer);
      if removed
        remove@toolpack.component.component(this, comp);
      end
      if nargout > 0
        varargout{1} = removed;
      end
    end
  end
end
