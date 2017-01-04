classdef performspectralfit
	properties (Constant = true)
		menuitemName = 'performspectralfit';
		menuitemText = 'Perform Spectral Fit';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			hwait = waitbar(0,'Fitting Spectra', 'WindowStyle', 'modal');
			itemNames = Parent.SpectraList.getItemNames(SelectedItems.Variables);
			for i = 1:numel(SelectedItems.Variables)
				h = Parent.SpectraList.performSpectralFits(SelectedItems.Variables(i),Parent.FitSpectraList.Plants,'instrumentGaussianFWHM',str2double(this.fittingtab.instrumentGaussianFWHMTextField.Text),'instrumentLorentzianFWHM',str2double(this.fittingtab.instrumentLorentzianFWHMTextField.Text));
				Parent.FitsList.addItem(h,0,0,itemNames{i});
				waitbar(i/numel(SelectedItems.Variables),hwait);
			end
			close(hwait);
		end
	end
end