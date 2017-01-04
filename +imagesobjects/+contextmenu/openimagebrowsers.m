classdef openimagebrowsers
	properties (Constant = true)
		menuitemName = 'openimagebrowsers';
		menuitemText = 'Open Image Browser(s)';
		menuitemMultiSelection = true;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			WorkspaceList = Parent.ImagesList;
			
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
			dupids = [];

			% Open the plot browsers
			for i = 1:length(plants)
				hfig = plants{i}.imagebrowser(Parent);
				Parent.TPComponent.addFigure(hfig);
			end
		end
	end
end