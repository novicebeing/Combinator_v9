classdef openmultiplotbrowser
	properties (Constant = true)
		menuitemName = 'openmultiplotbrowser';
		menuitemText = 'Open Multi Plot Browser';
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
			dupids = [];

			% Open the multi plot browser
			obj = spectraobjects.multispectrabrowser(plants);
			hfig = obj.figureHandle;
		end
	end
end