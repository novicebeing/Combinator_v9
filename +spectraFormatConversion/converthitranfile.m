function converthitranfile()
    [filename, pathname] = uigetfile( ...
        {'*.par','HITRAN files (*.par)'}, ...
           'Choose a file...');
       
     [~,~,fileext] = fileparts(filename);
       
     if isempty(filename)
         return
     elseif strcmp(fileext,'.par')
         % The file is a *.par file - we need to convert it
        disp 'Loading File'
        fid = fopen (fullfile(pathname,filename),'rt'); %open file
        A = fscanf(fid,'%161c',[161 inf]); % read values
        fclose(fid);
        disp 'Done'
        
        %Transpose A
        A=A';

        s.igas= str2num(A(:,1:2));
        s.iso= str2num(A(:,3:3));
        s.wnum= str2num(A(:,4:15));
        s.int= str2num(A(:,16:25));
        s.Acoeff=str2num(A(:,26:35));
        s.abroad=str2num(A(:,36:40));
        s.sbroad=str2num(A(:,41:45));
        s.els=str2num(A(:,46:55));
        s.abcoef=str2num(A(:,56:59));
        s.tsp=str2num(A(:,60:67));
        s.gn=str2num(A(:,157:160));
        
        % Save to file
        [oldfilepath,oldfilename,~] = fileparts(fullfile(pathname,filename));
        newfilename = fullfile(oldfilepath,oldfilename,'.mat');
        [matfilename,matfilepath] = uiputfile('*.mat','Save MATLAB file',newfilename);
        if ~isempty(matfilename)
            save(fullfile(matfilepath,matfilename),'-struct','s');
        end
	end
end