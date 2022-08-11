# ebsd2ansys
This program generates an ABAQUS input file optimized for use with the ANSYS external model for a given EBSD map.
The ANSYS external model allows for loading of externally defined meshes. Only certain syntax and options for ABAQUS input files are supported by ANSYS, which is taken care of in the script. The script only supports the generation of simple brick elements. The mesh is divided into element groups with local coordinate sytems based on mean grain orientations (this is equivalent to grains in EBSD software). the script further generates element sets with individual grains, element sets with individual phases, sections with individual phases and node sets of faces for BCs.

## Credits

Adapted from 
- [ebsd2abaqus](https://github.com/latmarat/ebsd2abaqus.git)
- Marat I. Latypov (GT Lorraine)
- marat.latypov@georgiatech-metz.fr
- March 2015, revised July 2016

and 
- [ebsd2abaqusEuler](https://github.com/ngrilli/ebsd2abaqusEuler.git)
- Nicolo Grilli
- University of Oxford
- AWE project 2019

## Getting started

Run this script with the provided test EBSD data to check the functionality.
The script is to be used together with an EBSD dataset loaded into [MTEX](https://mtex-toolbox.github.io).
Make sure to include the entire folder and subfolder in the MATLAB path.

The script [main.m](https://github.com/frankNiessen/ebsd2ansys/blob/master/main.m) can be run as an example and also takes care of some pre-processing of the EBSD data in MTEX. The function [ebsd2ansys.m](https://github.com/frankNiessen/ebsd2ansys/blob/master/ebsd2ansys.m) contains the actual mesh and file generation and requires the following inputs:
 - ebsd  - ebsd object from MTEX
 - angle - threshold angle for grain reconstruction [°]
 - fName - Output filename ['xxx.inp']
 - elAR  - Element aspect ratio - option of elongating brick elements in z direction by factor 'elAR'
 
As an output the function returns:

- order: list of ebsd pixel indeces according to ABAQUS convention of the order of x,y and z coordinates. 
- grainsReconstructed: MTEX grains2d object containing the reconstructed grains that form the element groups in ANSYS.
- order - 
- grainsReconstructed - MTEX grains2D object containing the reconstructed grains
