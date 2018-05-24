% gsd-192 data reader
%
%  read data into a single Matlab struct
%  supported configuration: after Dec.2017
%
%  Rev.1.0 (2018/5/14)
%  + gsd parser from (https://github.com/rcjwoods/GSD-192_GUI/blob/master/gsd_parse.cc)
%
% Copyright 2018 Andrew Chuang (chuang.cp@gmail.com)
% $Revision: 1.0 $  $Date: 2018/05/14 $


function [pd_hist1] = read_gsd192(logtoopen)   %[addr, pd, td, ts, pd_hist1]

if nargin ~= 1
    fprintf('\nUsage : [log]=readedd_6bm("FILEtoOPEN")\n');
    fprintf('\n');
    return;
end

% open and read the file into memory
if isdir(logtoopen)
    [fpath, fname, ~] = fileparts(logtoopen);
    fullname= fullfile(logtoopen,sprintf('%s.dat',fname));
    fid=fopen(fullname);if fid == -1, error('Can''t find/open the input file.'); end
else
    fid=fopen(logtoopen);if fid == -1, error('Can''t open the input file.'); end
end

% read the data
t0 = tic;
raw = fread(fid,'uint32');
fclose(fid);
fprintf('\nReading data... %0.4f sec.\n', toc(t0));

% parse it
if exist('maia_parserawdata', 'file') == 3
    fprintf('Parsing data using mex function...');
    t0 = tic;
    [addr, pd, td, ts] = maia_parserawdata(length(raw),raw');
    %addr = addr';
    %td = td';
    %pd = pd';
    %ts = ts';
    fprintf('%0.4f sec.\n', toc(t0));
else
    %rawdata = uint32(vec2mat(raw,2));
    rawdata = uint32(reshape(raw,2,[])');
    fprintf('Parsing data... Please be patient...');
    t0 = tic;
    %address,td,pd,timestamp
    addr = bitsrl(bitand(hex2dec('7FC00000'),rawdata(:,1)),22);
    td = bitsrl(bitand(hex2dec('003FF000'),rawdata(:,1)),12);
    pd = bitand(hex2dec('00000FFF'),rawdata(:,1));
    ts = bitand(hex2dec('01FFFFFF'),rawdata(:,2));
    fprintf('done. %0.4f sec.\n', toc(t0));
end

% Check Addresses
if max(addr) > 383
    error('Somethin must be wrong. Address > 383')
end


%initialize pd histogram array - pixel(512) x energy/pulse height
pd_hist = zeros(4096, 512);
t0=tic;
for i=1:length(addr)
    pd_hist(pd(i), addr(i)+1) = pd_hist(pd(i), addr(i)+1) + 1;
end
fprintf('Preparing histogram. %0.4f sec.\n', toc(t0));

% only bank 1/3/5/7/9/11 have data (32 * 6 = 192)
mask = logical(cat(2, repmat([zeros(4096, 32) zeros(4096,32)+1],1,6), zeros(4096,32*4)));

% return just that
pd_hist1 = reshape(pd_hist(mask),4096, [])';


