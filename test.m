datafolder = './audio/';
ads0 = audioDatastore(datafolder,'IncludeSubfolders',true);
metadata = readtable(fullfile(datafolder, 'audio_data.csv'), 'FileType', 'text', 'Delimiter', ',');
head(metadata)

csvFiles = metadata.path;
adsFiles = ads0.Files;
%adsFiles = cellfun(@HelperGetFilePart,adsFiles,'UniformOutput',false);
[~,indA,indB] = intersect(adsFiles,csvFiles);

adsTrain = subset(ads0, indA);
species = metadata.label;
species = species(indB);
adsTrain.Labels = species;
adsTrain = shuffle(adsTrain);
countEachLabel(adsTrain);

[audio,adsInfo] = read(adsTrain);
Fs = adsInfo.SampleRate;

win = hamming(0.03*Fs,"periodic");
overlapLength = round(0.75*numel(win));
featureParams = struct("SampleRate",Fs, ...
                 "Window",win, ...
                 "OverlapLength",overlapLength);
extractor = audioFeatureExtractor('Window',win, ...
    'OverlapLength',overlapLength, ...
    'SampleRate',Fs, ...
    'SpectralDescriptorInput','melSpectrum', ...
    ...
    'gtcc',true, ...
    'gtccDelta',true, ...
    'gtccDeltaDelta',true, ...
    'spectralSlope',true, ...
    'spectralFlux',true, ...
    'spectralCentroid',true, ...
    'spectralEntropy',true, ...
    'pitch',true, ...
    'harmonicRatio',true);

T = tall(adsTrain);
segmentsTall = cellfun(@(x)HelperSegmentSpeech(x, Fs), T, 'UniformOutput', false);
segmentsPerFileTall = cellfun(@numel, segmentsTall);
featureVectorsTall = cellfun(@(x)HelperGetFeatureVectors(x, extractor), segmentsTall, 'UniformOutput', false);
[featureVectors, segmentsPerFile] = gather(featureVectorsTall, segmentsPerFileTall);
featureVectos = cat(2, featureVectors{:});
myLabels = adsTrain.Labels;
myLabels = repelem(myLabels, segmentsPerFile);
allFeatures = cat(2,featureVectors{:});
allFeatures(isinf(allFeatures)) = nan;
%for k = 1:length(allFeatures)
%    n_c = cell2mat(allFeatures(k));
%    n_c(isinf(n_c)) = nan;
%    allFeatures(k) = num2cell(n_c, [1 2]);
%end
M = mean(allFeatures,2,'omitnan');
S = std(allFeatures,0,2,'omitnan');
featureVectors = cellfun(@(x)(x-M)./S,featureVectors,'UniformOutput',false);
for ii = 1:numel(featureVectors)
    idx = find(isnan(featureVectors{ii}));
    if ~isempty(idx)
        featureVectors{ii}(idx) = 0;
    end
end
featureVectorsPerSequence = 20;
featureVectorOverlap = 10;
[featuresTrain,sequencePerSegment] = HelperFeatureVector2Sequence(featureVectors,featureVectorsPerSequence,featureVectorOverlap);
speciesTrain = repelem(myLabels, [sequencePerSegment{:}]);
%metadata = read