function vipaworkspacegitshell()
    a = mfilename('fullpath');
    [b,~,~] = fileparts(a);
    %dos(sprintf('start cmd.exe /k "%s\\vipaworkspacegitshell.bat"',b));
    dos(sprintf('%%LOCALAPPDATA%%\\GitHub\\GitHub.appref-ms --open-shell=%s',b));
	%dos(sprintf('start cmd.exe',b));
end