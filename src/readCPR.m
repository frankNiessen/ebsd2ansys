function ebsd = readCPR(inPath,varargin)
%% Varargin
phStr = '';                                                                % Phase strings
for argidx = 2:2:(nargin + nargin(mfilename)+1)
   switch lower(varargin{argidx-1})
       case 'phasenames'
            phStr = varargin{argidx};
   end
end

scrPrnt('SegmentStart','Reading in EBSD data')
%% Define Mtex plotting convention as X = right, Y = up
setMTEXpref('xAxisDirection','east');
setMTEXpref('zAxisDirection','outOfPlane');
setMTEXpref('FontSize',16);
%% Loading Cpr file
scrPrnt('Step',sprintf('Loading ''cpr'' file containing EBSD and optionally EDS data'));
[FileName,inPath] = uigetfile([inPath,'/','*.cpr'],'EBSD-Data Input - Open *.cpr file');
if FileName == 0
star    error('The program was terminated by the user');
else
    scrPrnt('Step',sprintf('Loading file ''%s''',FileName));
    [ebsd] = loadEBSD_crc([inPath FileName],'interface','crc','convertSpatial2EulerReferenceFrame');
    ebsd = ebsd.gridify;
    scrPrnt('Step',sprintf('Loaded file ''%s'' succesfully',FileName));
end
%% Renaming Phases (Minerals)
if ~isempty(phStr)
    phases = unique(ebsd('indexed').phase);
    if ~isempty(intersect(ebsd('indexed').mineralList,phStr)) && all(strcmp(intersect(ebsd('indexed').mineralList,phStr),phStr)) %Check if all phase names agree with name in EBSD data set
        scrPrnt('Step',sprintf('Phases %sautomatically identified',sprintf('''%s'' ',phStr{:}))); 
    else
        scrPrnt('Step','Identifying phases');
        for i = 1:size(phases,1)
           mineral = ebsd(num2str(phases(i))).mineral;
           scrPrnt('SubStep',sprintf('''%s''',mineral));
           [ind,~] = listdlg('PromptString',['Find phase name corresponding to ''',mineral,''':'],...
                                   'SelectionMode','single','ListString',phStr,...
                                   'ListSize',[300 150]);
            ebsd.CSList{end-size(phases,1)+i}.mineral = phStr{ind};                %Rename phases
        end
    end
end
%% Save output data
ebsd.opt.fName = FileName;                                                 %Save filename
%ebsd.opt.cprData = cpr;                                                    %Save cpr data