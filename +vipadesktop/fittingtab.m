classdef fittingtab < handle
   properties
       % Connection back to vipadesktop
       vipadesktop
       
       % ToolTab component
       TPComponent
       
       % Sections
       InstrumentParametersSection
       
       % Text Fields
       instrumentGaussianFWHMTextField
       instrumentLorentzianFWHMTextField
   end
   events
       OpenButtonPressed
   end
   methods
       function this = fittingtab(vipadesktop)
            % Add home tab
            this.TPComponent = toolpack.desktop.ToolTab('VIPAworkspaceFittingTab', 'Fitting');
            
            % Add Instrument Parameters Section
            this.InstrumentParametersSection = toolpack.desktop.ToolSection('instrumentparameters','Inst. Parameters');
            panel = toolpack.component.TSPanel('7px, f:p, 4px, f:p, 7px','3px, 20px, 4px, 20px, 4px, 22px');
            this.InstrumentParametersSection.add(panel);
            l = toolpack.component.TSLabel('Inst. Gaussian FWHM [cm-1]');
            panel.add(l,'xy(2,2,''r,c'')');
            l = toolpack.component.TSLabel('Inst. Lorentz FWHM [cm-1]');
            panel.add(l,'xy(2,4,''r,c'')');
            l = toolpack.component.TSLabel('');
            panel.add(l,'xy(2,6,''r,c'')');
            this.instrumentGaussianFWHMTextField = toolpack.component.TSTextField('0',8);
            this.instrumentGaussianFWHMTextField.Editable = true;
            %addlistener(this.instrumentGaussianFWHMTextField,'ActionPerformed',@(~,~) setTextFieldText(this.imageDestTextField,'none'));
            panel.add(this.instrumentGaussianFWHMTextField,'xywh(4,2,1,1)');
            this.instrumentLorentzianFWHMTextField = toolpack.component.TSTextField('0.02997',8);
            this.instrumentLorentzianFWHMTextField.Editable = true;
            %addlistener(this.calibrationTextField,'ActionPerformed',@(~,~) setTextFieldText(this.calibrationTextField,'none'));
            panel.add(this.instrumentLorentzianFWHMTextField,'xywh(4,4,1,1)');
            this.TPComponent.add(this.InstrumentParametersSection);
            
            this.vipadesktop = vipadesktop;
       end
        function val = getPanelWidth(this)
            val = this.Panel.Peer.getPreferredSize.getWidth;
        end
        function setPanelWidth(this, val)
            this.Panel.Peer.setPreferredSize(java.awt.Dimension(val,79));
        end
   end
end