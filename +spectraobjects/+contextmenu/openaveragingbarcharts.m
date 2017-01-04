classdef openaveragingbarcharts
	properties (Constant = true)
		menuitemName = 'openaveragingbarcharts';
		menuitemText = 'Open Averaging Bar Charts';
		menuitemMultiSelection = false;
	end

	methods (Static)
		function menucallback(Parent,SelectedItems)
			h = Parent.SpectraList.openAveragingBarCharts(SelectedItems.Variables);
			Parent.TPComponent.addFigure(h);
		end
	end
end