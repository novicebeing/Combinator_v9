a = mfilename('fullpath');
[b,~,~] = fileparts(a);
dos(sprintf('notepad "%s\\vipaworkspacenotes.txt"',b));