function featureVectors = HelperGetFeatureVectors(x,extractor)

x = x(:,1);
featureVectors = cell(size(x));

for ii = 1:numel(x)
    fV = extract(extractor,x{ii});
    featureVectors{ii} = fV';
end

end