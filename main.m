
% *************************************************************************
% ebsd2ansys
% *************************************************************************
% Frank Niessen, University of Wollongong, EMC, 02/2020
% contactnospam@fniessen.com (remove the nospam to make this email address
% work)
% .........................................................................
% This program generates an ABAQUS input file optimized for use with the
% ANSYS external model for given EBSD map.
% .........................................................................
% The mesh is divided into element groups with local coordinate sytems
% based on mean grain orientations
% .........................................................................
% Run this script with the provided test EBSD data check the functionality
% .........................................................................
% Requires installation of the crystallographic toolbox MTEX
% .........................................................................
% MIT license file attached
% -------------------------------------------------------------------------
    % Adapted from ebsd2abaqus
    % Marat I. Latypov (GT Lorraine)
    % marat.latypov@georgiatech-metz.fr
    % March 2015, revised July 2016
    % (https://github.com/latmarat/ebsd2abaqus.git)
    % --------------------------
	% and ebsd2abaqusEuler
    % Nicolo Grilli
	% University of Oxford
	% AWE project 2019
    % (https://github.com/ngrilli/ebsd2abaqusEuler.git)
	% --------------------------
%% Startup
clc; clear vars; clear hidden; close all                                        %Clean up
scrPrnt('StartUp','ebsd2ansys');                                           %ScreenPrint
startup_mtex;                                                              %Startup m-tex
%% Declaration
rBin = 1;                                                                  %Binning factor to reduce spatial resolutuion of EBSD data
ang = 10;                                                                  %Angular criterion for grain boundary determination [�]
elAR = 30;                                                                 %Aspect ratio of elements (l_z = elAR*l_x OR l_y)
%% Initialization
Dat.inPath = [fileparts(mfilename('fullpath')),'\data\input'];             %Default input folder EBSD data
Dat.outPath = [fileparts(mfilename('fullpath')),'\data\output\inpFiles'];  %Default input folder EBSD data
%% Import data and identify phases
ebsd = readCPR([Dat.inPath,'\ebsd']);                                      %Import EBSD data
[~,fName,~] = fileparts(ebsd.opt.fName);                                   %Filename
%% Prepare EBSD data
ebsd = reduce(ebsd,rBin);                                                  %Reduce EBSD data
ebsd = prepEBSD(ebsd);                                                     %Prepare EBSD data for grid creation
%Plot
figure;
plot(ebsd);
drawnow
%% Write *.inp file
[order,grains] = ebsd2ansys(ebsd,ang,[Dat.outPath,'\',fName,'.inp'],elAR); %Write input file
tileFigs;
scrPrnt('Step',regexprep(['Input file was written to ',Dat.outPath,'\',fName,'.inp'],'\','\\\'));
