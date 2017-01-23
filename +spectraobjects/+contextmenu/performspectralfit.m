classdef performspectralfit
	properties (Constant = true)
		menuitemName = 'performspectralfit';
		menuitemText = 'Perform Spectral Fit';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			WorkspaceList = Parent.SpectraList;
			
			% Get the objects
			if isempty(SelectedItems.Variables)
				return
			end
			if isnumeric(SelectedItems.Variables)
				idx = SelectedItems.Variables;
			else
				idx = [];
				for i = 1:length(SelectedItems.Variables)
					idx = [idx;find(strcmp(WorkspaceList.PlantNames, SelectedItems.Variables{i}))]; %#ok<AGROW>
				end
			end
			plants = WorkspaceList.Plants(idx);
			plantnames = WorkspaceList.PlantNames(idx);
			dupids = [];
		
			paramsToFit = [Parent.fittingtab.instrumentGaussianFWHMFittingCheckbox.Selected,...
							Parent.fittingtab.instrumentLorentzianFWHMFittingCheckbox.Selected];
		
			hwait = waitbar(0,'Fitting Spectra', 'WindowStyle', 'modal');
			itemNames = Parent.SpectraList.getItemNames(SelectedItems.Variables);
			for i = 1:numel(SelectedItems.Variables)
				if any(paramsToFit)
					options = optimoptions('lsqnonlin','Display','iter');
					beta = lsqnonlinWithFixedParams( ...
							@(b) funLineshape(plants{i},Parent.FitSpectraList.Plants,b(1),b(2)),...
							paramsToFit,...
							[str2double(Parent.fittingtab.instrumentGaussianFWHMTextField.Text),str2double(Parent.fittingtab.instrumentLorentzianFWHMTextField.Text)],...
							[0 0],[inf inf],options);
					beta
					Parent.fittingtab.instrumentGaussianFWHMTextField.Text = num2str(beta(1));
					Parent.fittingtab.instrumentLorentzianFWHMTextField.Text = num2str(beta(2));
				end
				
				fitobj = vipadesktop.linearSpectrumFit(plants{i},Parent.FitSpectraList.Plants,'instrumentGaussianFWHM',str2double(Parent.fittingtab.instrumentGaussianFWHMTextField.Text),'instrumentLorentzianFWHM',str2double(Parent.fittingtab.instrumentLorentzianFWHMTextField.Text));
				Parent.FitsList.addItem(fitobj,0,0,itemNames{i});
				waitbar(i/numel(SelectedItems.Variables),hwait);
			end
			close(hwait);
			
			function residuals = funLineshape(inputSpectra,fitSpectra,gaussianFWHM,lorentzianFWHM)
				fitobj = vipadesktop.linearSpectrumFit(inputSpectra,fitSpectra,'instrumentGaussianFWHM',gaussianFWHM,'instrumentLorentzianFWHM',lorentzianFWHM);
				residuals = reshape(reshape(fitobj.y,[],size(fitobj.y,3))-fitobj.fitM*fitobj.fitb,[],1);
				residuals(isnan(residuals))=0;
			end
			
			function beta = lsqnonlinWithFixedParams(fun,fitindcs,beta0,lowerLim,upperLim,options)
				beta = beta0;
				S.type = '()';
				S.subs = {logical(fitindcs)};
				beta(fitindcs) = lsqnonlin(@(b) fun(subsasgn(beta0,S,b)),beta0(fitindcs),...
									lowerLim(fitindcs),upperLim(fitindcs),options);
			end
		end
	end
end