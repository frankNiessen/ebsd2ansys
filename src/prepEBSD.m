function ebsd = prepEBSD(ebsd)
%Convert potential Hex-grid to Square-grid
if length(ebsd.unitCell) == 6                                              %Check if ebsd on hex grid and convert to sqr if so
    scrPrnt('Step','Converting hex to square grid'); 
    ebsd = reduce(fill(ebsd),1);                                           %Convert to square grid
    warning('EBSD was on hex grid and so was converted to sqr grid using fill function\n')
end
%Fill empty data points
nrNI = size(ebsd('notIndexed'),1);
if nrNI
    scrPrnt('Step','Filling empty ebsd data'); 
    ebsd('notIndexed') = [];
    ebsd = reduce(fill(ebsd),1);
    warning('EBSD had %d non-indexed pixels and so was filled using fill function\n', nrNI);
end