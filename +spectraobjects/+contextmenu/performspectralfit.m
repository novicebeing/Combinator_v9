classdef performspectralfit
	properties (Constant = true)
		menuitemName = 'performspectralfit';
		menuitemText = 'Perform Spectral Fit';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			% Get the spectra objects
			if isempty(plantids)
				return
			end
			if isnumeric(plantids)
				idx = plantids;
			else
				idx = [];
				for i = 1:length(plantids)
					idx = [idx;find(strcmp(this.PlantNames, plantids{i}))]; %#ok<AGROW>
				end
			end
			plants = this.Plants(idx);
		
			hwait = waitbar(0,'Fitting Spectra', 'WindowStyle', 'modal');
			itemNames = Parent.SpectraList.getItemNames(SelectedItems.Variables);
<<<<<<< HEAD
			for i = 1:numel(plants)
				fitobj = vipadesktop.linearSpectrumFit(plants{i},Parent.FitSpectraList.Plants,varargin{:},'instrumentGaussianFWHM',str2double(Parent.fittingtab.instrumentGaussianFWHMTextField.Text),'instrumentLorentzianFWHM',str2double(Parent.fittingtab.instrumentLorentzianFWHMTextField.Text));
				Parent.FitsList.addItem(fitobj,0,0,itemNames{i});
=======
			for i = 1:numel(SelectedItems.Variables)
				h = Parent.SpectraList.performSpectralFits(SelectedItems.Variables(i),Parent.FitSpectraList.Plants,'instrumentGaussianFWHM',str2double(Parent.fittingtab.instrumentGaussianFWHMTextField.Text),'instrumentLorentzianFWHM',str2double(Parent.fittingtab.instrumentLorentzianFWHMTextField.Text));
				Parent.FitsList.addItem(h,0,0,itemNames{i});
>>>>>>> 4707747a177acaed55c87af645ba1f550ff1e135
				waitbar(i/numel(SelectedItems.Variables),hwait);
			end
			close(hwait);
		end
	end
end