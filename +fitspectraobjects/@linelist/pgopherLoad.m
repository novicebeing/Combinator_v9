function pgopherLoad(this,pgopherfile)
    [classpath,~,~] = fileparts(mfilename('fullpath'));
    tempfile = tempname;
    command = sprintf('%s\\pgou64.exe Mixture.PrintLevel=CSV Mixture.OThreshold=0 --o "%s" "%s"',classpath,tempfile,pgopherfile);
    [status,cmdout] = dos(command);
    
    % Load in the file
    fid = fopen(tempfile);
    C = textscan(fid,[repmat('%*s',1,9) '%f %f' repmat('%*s',1,8)],'Delimiter',',','HeaderLines',2,'EndOfLine','\r\n');
    linelist = C{1};
    linestrength = C{2};
    this.lineposition = linelist;
    this.linestrength = linestrength;
end