classdef DataBrowserEventData < event.EventData
    
    properties
        Request
        Variables
    end
    methods
        function data = DataBrowserEventData(request,vars)
            
            data.Request = request;
            data.Variables = vars;
        end
    end
end
