classdef TSButton < toolpack.component.TSButtonBehavior
  % Toolstrip button.
  %
  % See also toolpack.component.TSSplitButton,
  % toolpack.component.TSDropDownButton.
  
  % Author(s): Bora Eryilmaz
  % Revised:
  % Copyright 2010-2011 The MathWorks, Inc.
  
  % ----------------------------------------------------------------------------
  properties (Dependent, Access = public)
    % Component's text (string, default = '')
    Text
    % Component's icon (Icon, default = Icon.empty)
    Icon
  end
  
  properties (Access = private)
    % Icon or [] for default Icon.empty
    Icon_
  end
  
  % ----------------------------------------------------------------------------
  events
    % Event sent upon button press.
    ActionPerformed
  end
  
  % ----------------------------------------------------------------------------
  methods
    function this = TSButton(text, icon)
      % Creates a toolstrip button.
      %
      % Example:
      %   text = 'Open';
      %   icon = toolpack.component.Icon.OPEN;
      %
      %   btn = toolpack.component.TSButton
      %   btn = toolpack.component.TSButton(icon)
      %   btn = toolpack.component.TSButton(text)
      %   btn = toolpack.component.TSButton(text, icon)
      
      this = this@toolpack.component.TSButtonBehavior;
      cls = 'com.mathworks.toolstrip.components.TSButton';
      if nargin == 0
        % TSButton();
        this.Peer = javaObjectEDT(cls, ''); % remove after g744816 fixed
      elseif nargin == 1
        if ischar(text)
          % TSButton(text)
          this.Peer = javaObjectEDT(cls, text);
        else
          % TSButton(icon)
          icon = text;
          this.Icon = icon;
          this.Peer = javaObjectEDT(cls, icon.Peer);
        end
      else
        % TSButton(text, icon)
        this.Icon = icon;
        this.Peer = javaObjectEDT(cls, text, icon.Peer);
      end
      % mnemonics is off by default
      this.Peer.setAutoMnemonicEnabled(false);
      addActionPerformedListener( this, {@LocalActionPerformed, this} )
    end
    
    function value = get.Text(this)
      % GET function for Text property.
      value = char(this.Peer.getText);
    end
    
    function set.Text(this, value)
      % SET function for Text property.
      if isempty(value)
        value = '';
      elseif ~ischar(value)
        ctrlMsgUtils.error('Controllib:toolpack:StringArgumentNeeded')
      end
      this.Peer.setText(value);
    end
    
    function value = get.Icon(this)
      % GET function for Icon property.
      value = this.Icon_;
      if isempty(value)
        value = toolpack.component.Icon.empty; % default
      end
    end
    
    function set.Icon(this, value)
      % SET function for Icon property.
      if isempty(value)
        value = [];
        this.Peer.setIcon(value)
      elseif isa(value, 'toolpack.component.Icon') || isa(value, 'matlab.ui.internal.toolstrip.Icon')
        this.Peer.setIcon(value.Peer)
      else
        ctrlMsgUtils.error('Controllib:toolpack:InvalidPropertyValue', 'Icon')
      end
      this.Icon_ = value;
    end
    
  end
  
  methods (Access = private)
    function addActionPerformedListener(this, fcn)
      % Do not modify. Use as is to prevent Java memory leaks.
      L = addlistener(this.Peer, 'ActionPerformed', fcn);
      this.Listeners = [this.Listeners; L];
    end
  end
end

% ------------------------------------------------------------------------------
function LocalActionPerformed(~,~,obj)
obj.notify('ActionPerformed')
end
