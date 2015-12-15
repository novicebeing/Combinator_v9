classdef ToolTab < toolpack.component.component
  % Tool tab component.
  %
  % See also toolpack.desktop.ToolStrip, toolpack.desktop.ToolSection.
  
  % Author(s): Bora Eryilmaz
  % Revised:
  % Copyright 2010 The MathWorks, Inc.
  
  % ----------------------------------------------------------------------------
  properties (Dependent, GetAccess = public, SetAccess = private)
    % Component's sections (nx1 cell array of strings, default = cell(0,1))
    SectionNames
  end
  
  properties (Dependent, Access = public)
    % Component title (string, default = '')
    Title
  end
  
  % ----------------------------------------------------------------------------
  % Public methods
  methods
    function this = ToolTab(name, title)
      % Creates a tool tab component.
      %
      % Example:
      %   name = 'tab1';
      %   title = 'Tools';
      %
      %   tab = toolpack.desktop.ToolTab
      %   tab = toolpack.desktop.ToolTab(name)
      %   tab = toolpack.desktop.ToolTab(name, title)
      
      this = this@toolpack.component.component;
      cls = 'com.mathworks.toolbox.shared.controllib.desktop.ToolTabWrapper';
      if nargin == 0
        % ToolTab()
        this.Peer = javaObjectEDT(cls, '', '');
      elseif nargin == 1
        % ToolTab(name)
        this.Peer = javaObjectEDT(cls, name);
      else
        % ToolTab(name, title)
        this.Peer = javaObjectEDT(cls, name, title);
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
    
    function sections = get.SectionNames(this)
      % GET function for SectionNames property.
      n = length(this.Children);
      sections = cell(n,1);
      for k = 1:n
        section = this.Children(k);
        m = this.Peer.indexOf( section.Peer.getWrappedComponent ) + 1;
        sections{m} = section.Name;
      end
    end
    
    function section = get(this, arg)
      % Returns the section with specified name or index, or [] if not found.
      if ischar(arg)
        % get(name)
        name = arg;
      else
        % get(index)
        index = arg;
        name = char(this.Peer.get(index-1).getName);
      end
      section = tree_search(this, name);
    end
    
    function varargout = add(this, section, index)
      % Adds the specified section at given index, if specified.
      % Returns true if component has been added.
      if nargin < 3
        % add(section)
        added = this.Peer.add( section.Peer.getWrappedComponent );
      else
        % add(section, index)
        added = this.Peer.add( section.Peer.getWrappedComponent, index-1 );
      end
      if added
        add@toolpack.component.component(this, section);
      end
      if nargout > 0
        varargout{1} = added;
      end
    end
    
    function varargout = remove(this, section)
      % Removes the specified section
      % Returns true if component has been removed.
      removed = this.Peer.remove( section.Peer.getWrappedComponent );
      if removed
        remove@toolpack.component.component(this, section);
      end
      if nargout > 0
        varargout{1} = removed;
      end
    end
    
    function moved = move(this, srcidx, dstidx)
      % Moves the section at location SRCIDX to destination DSTIDX in original
      % list.
      % Returns true if component has been moved.
      moved = this.Peer.move(srcidx-1, dstidx-1);
    end
  end
  
  methods
    function section = addSection(this, name, title)
      % Adds a section with the specified name and title.
      this.removeSection(name); % In case there is already a section with same name.
      section = toolpack.desktop.ToolSection(name, title);
      this.add(section);
    end
    
    function section = removeSection(this, name)
      % Removes the section with the specified name.
      section = this.get(name);
      if ~isempty(section)
        this.remove(section);
      end
    end
  end
end
