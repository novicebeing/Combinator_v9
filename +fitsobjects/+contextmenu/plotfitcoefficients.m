classdef plotfitcoefficients
	properties (Constant = true)
		menuitemName = 'plotfitcoefficients';
		menuitemText = 'Plot Fit Coefficients';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			WorkspaceList = Parent.FitsList;
			
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

			% Open the plot browsers
			for i = 1:length(plants)
				hfig = plants{i}.plotfitcoefficients();
				set(hfig,'Name',sprintf('Coeff:%s',plantnames{i}));
				set(hfig,'NumberTitle','off');
				Parent.TPComponent.addFigure(hfig);
			end
		end
	end
end