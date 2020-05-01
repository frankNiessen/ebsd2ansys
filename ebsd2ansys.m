function [order,grainsReconstructed] = ebsd2ansys(ebsd,angle,fName,elAR)
% *ebsd2ansys* generates ABAQUS input file optimized for use with the
% ANSYS external model for given EBSD map
% *** Syntax
% ebsd2ansys(ebsd,angle,fname,elAR)
% *** Input
% ebsd  - ebsd object from MTEX
% angle - threshold angle for grain reconstruction [°]
% fName - Output filename ['xxx.inp']
% elAR  - Element aspect ratio - option of elongating brick elements in
% z direction by factor 'elAR'

% % Output
% ebsd.inp file which contains
% - element sets with individual grains
% - element sets with individual phases
% - sections with individual phases
% - node sets of faces for BCs

scrPrnt('SegmentStart','Writing *.inp file')
if strcmp(ebsd.scanUnit,'um')
    fac = 1e-6;
elseif strcmp(ebsd.scanUnit,'nm')
    fac = 1e-9;
end
roundxyz = 1e-4;

%%  Get step size from input
dxy = max(ebsd.unitCell) - min(ebsd.unitCell);
step(1) = dxy(1);
step(2) = dxy(2);
step(3) = min(dxy); 
%%  Reconstruct grains
scrPrnt('Step','Reconstructing grains');
[grainsReconstructed,ebsd.grainId,ebsd.mis2mean] = calcGrains(ebsd,'angle',angle*degree);
phases = ebsd.phase;
grains = ebsd.grainId; % grain index for each point of the EBSD
%%  Get coordinates
scrPrnt('Step','Getting coordinates');
xyz = zeros(numel(ebsd.x),3);
xyz(:,1) = ebsd.x;
xyz(:,2) = ebsd.y;
xyz(:,3) = zeros(numel(xyz(:,1)),1);

% sort the coordinate array
[~,order] = sortrows(xyz,[1,3,2]);

% reorder grain IDs and Euler angles according to ABAQUS convention
% but same grain ID correspond to same Euler angles
% so no need to reorder grainsReconstructed
phases = phases(order);
grains = grains(order);

% get the number of voxels along x, y, z
xVox = size(unique(round(xyz(:,1).*roundxyz^(-1))*roundxyz),1);
yVox = size(unique(round(xyz(:,2).*roundxyz^(-1))*roundxyz),1);
zVox = size(unique(round(xyz(:,3).*roundxyz^(-1))*roundxyz),1);

% get step size and boundaries for the mesh
boxmin = zeros(1,3);
boxmax = zeros(1,3);
for ii = 1:3
    boxmin(ii) = min(xyz(:,ii))-step(ii)/2;
    boxmax(ii) = max(xyz(:,ii))+step(ii)/2;
end
boxmin(3) = boxmin(3)*elAR;
boxmax(3) = boxmax(3)*elAR;
%% Generate 3D mesh
scrPrnt('Step','Generating 3D mesh');
% generate nodes 
[x,y,z] = meshgrid(boxmin(1):step(1):boxmax(1),boxmin(2):step(2):boxmax(2),boxmin(3):step(3)*elAR:boxmax(3));
numNodes = numel(x);
coord = [reshape(x,numNodes,1), reshape(y,numNodes,1), reshape(z,numNodes,1)];
coord = coord.*fac;
nodes = [(1:numNodes)', sortrows(coord,[1,3,2])];

% allocate array for elements
elem = zeros(size(xyz,1),9);
count = 1;

% start loop over voxel dimensions
for ix = 1:xVox
    for iz = 1:zVox
        for iy = 1:yVox

            % get element label
            elem(count,1) = count;

            % nodes on the plane with lower x
            elem(count,2) = iy + (iz-1)*(yVox+1) + (ix-1)*(yVox+1)*(zVox+1);
            elem(count,3) = elem(count,2) + 1;
            elem(count,4) = elem(count,3) + yVox + 1;
            elem(count,5) = elem(count,2) + yVox + 1;

            % nodes on the plane with higher x
            elem(count,6) = iy + (iz-1)*(yVox+1) + ix*(yVox+1)*(zVox+1);
            elem(count,7) = elem(count,6) + 1;
            elem(count,8) = elem(count,7) + yVox + 1;
            elem(count,9) = elem(count,6) + yVox + 1;

            count = count+1;
        end
    end
end

%% Write inp file
scrPrnt('Step','Writing *.inp file');
% open inp file and write keywords 
inpFile = fopen(fName,'wt');
fprintf(inpFile,'**PARTS\n**\n');
fprintf(inpFile,'*Part, name=SAMPLE\n');

% write nodes
fprintf(inpFile,'*NODE, NSET=AllNodes\n');
fprintf(inpFile,'%d,\t%e,\t%e, \t%e\n',nodes');

% write elements
fprintf(inpFile,'*Element, type=C3D8, ELSET=AllElements\n');
fprintf(inpFile,'%d,\t%d,\t%d,\t%d,\t%d,\t%d,\t%d,\t%d,\t%d\n',elem');

% write orientations
scrPrnt('SubStep','...');
figure;
plot(grainsReconstructed.boundary);
for ii = 1:numel(unique(grains))
    Mrot = grainsReconstructed(ii).meanOrientation.matrix;
    cntr = grainsReconstructed(ii).centroid;
    fprintf(inpFile,'\n*ORIENTATION, NAME=CS-%d, SYSTEM=RECTANGULAR, DEFINITION=COORDINATES',ii);
    fprintf(inpFile,'\n%6.5f,%6.5f,%6.5f,%6.5f,%6.5f,%6.5f,%6.5f,',Mrot(1,1),Mrot(1,2),Mrot(1,3),Mrot(2,1),Mrot(2,2),Mrot(2,3),cntr(1)*fac);
    fprintf(inpFile,'%6.5f,%6.5f',cntr(2)*fac,0);
    %Plot  
    hold on
    quiver(grainsReconstructed(ii),vector3d(Mrot(1,1),Mrot(1,2),Mrot(1,3)),'color','r');
    quiver(grainsReconstructed(ii),vector3d(Mrot(2,1),Mrot(2,2),Mrot(2,3)),'color','g');
    quiver(grainsReconstructed(ii),vector3d(Mrot(3,1),Mrot(3,2),Mrot(3,3)),'color','b');
end

fprintf(inpFile,'\n');  
% create materials
scrPrnt('SubStep','...');
uniPhases = unique(phases);
phaseNames = ebsd.mineralList;
phaseNames = phaseNames(~strcmp(phaseNames,'notIndexed') & ~strcmp(phaseNames,'notIndexed'));
for ii = 1:numel(uniPhases)
    fprintf(inpFile,'\n*MATERIAL, NAME=%s',phaseNames{ii});
    fprintf(inpFile,'\n*ELASTIC, TYPE = ANISOTROPIC');   
end

fprintf(inpFile,'\n');    
% create element sets containing grains
scrPrnt('SubStep','...');
for ii = 1:numel(unique(grains))
    fprintf(inpFile,'\n*ELSET=Grain-%d\n',ii);
    fprintf(inpFile,'%d, %d, %d, %d, %d, %d, %d, %d, %d\n',elem(grains==ii)');
    fprintf(inpFile,'\n*SHELL SECTION, ELSET=Grain-%d, ORIENTATION=CS-%d, MATERIAL=%s\n',ii,ii,ebsd(grains==ii).mineral);      
end   

fprintf(inpFile,'\n');  
% create element sets containing phases
scrPrnt('SubStep','...');
for ii = 1:numel(unique(phases))
    fprintf(inpFile,'\n*ELSET=Phase-%s\n',phaseNames{ii});
    fprintf(inpFile,'%d, %d, %d, %d, %d, %d, %d, %d, %d\n',elem(phases==uniPhases(ii))');
end

fprintf(inpFile,'\n');  
% create sections for phases
scrPrnt('SubStep','...');
for ii = 1:numel(uniPhases)
    fprintf(inpFile,'\n**Section: Section-%s\n*Solid Section, elset=Phase-%s, material=%s\n',phaseNames{ii},phaseNames{ii},phaseNames{ii});
end

fprintf(inpFile,'\n');
% create element sets containing grains
scrPrnt('SubStep','...');
for ii = 1:numel(unique(grains))
    fprintf(inpFile,'\n*Elset, elset=Grain-%d, ORIENTATION=CS-%d, MATERIAL=%s, RESPONSE=TRACTION SEPARATION\n',ii,ii,ebsd(ebsd.grainId==ii).mineral);
    fprintf(inpFile,'%d, %d, %d, %d, %d, %d, %d, %d, %d\n',elem(grains==ii)');
end  

fprintf(inpFile,'\n');  
% create node sets containing surface nodes for BCs
scrPrnt('SubStep','...');
for ii = 1:3
    fprintf(inpFile,'\n**\n*Nset, nset=NODES-%d\n',ii);
    fprintf(inpFile,'%d, %d, %d, %d, %d, %d, %d, %d, %d\n',nodes(nodes(:,ii+1)==boxmin(ii))');
    fprintf(inpFile,'\n**\n*Nset, nset=NODES+%d\n',ii);
    fprintf(inpFile,'%d, %d, %d, %d, %d, %d, %d, %d, %d\n',nodes(nodes(:,ii+1)==boxmax(ii))');
end

% write closing 
fprintf(inpFile,'\n**\n*End Part\n');
% close the file
fclose(inpFile); 
scrPrnt('Step','Finished writing *.inp file');
end
