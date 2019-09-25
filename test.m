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

[audio, adsInfo] = read(adsTrain);
audio = audio(:,1);
Fs = adsInfo.SampleRate;
timeVector = (1/Fs) * (0:numel(audio)-1);
audio = audio ./ max(abs(audio));
windowLength = 50e-3 * Fs;
segments = buffer(audio, windowLength);
win = hann(windowLength, 'periodic');
signalEnergy = sum(segments.^2, 1) / windowLength;
centroid = spectralCentroid(segments,Fs,'Window',win,'OverlapLength',0);
T_E = mean(signalEnergy)/2;
T_C = 5000;
isSpeechRegion = (signalEnergy >= T_E); %& (centroid <= T_C);

regionStartPos = find(diff([isSpeechRegion(1) - 1, isSpeechRegion]));

RegionLengths = diff([regionStartPos, numel(isSpeechRegion) + 1]);

isSpeechRegion = isSpeechRegion(regionStartPos) == 1;
regionStartPos = regionStartPos(isSpeechRegion);
RegionLengths = RegionLengths(isSpeechRegion);

startIndices = zeros(1, numel(RegionLengths));
endIndices= zeros(1, numel(RegionLengths));
for index = 1:numel(RegionLengths)
    startIndices(index) = max(1, (regionStartPos(index) - 5) * windowLength + 1);
    endIndices(index) = min(numel(audio), (regionStartPos(index) + RegionLengths(index) + 5) * windowLength);
end

activeSegment = 1;
isSegmentActive = zeros(1, numel(startIndices));
isSegmentActive(1) = 1;
for index = 2:numel(startIndices)
    if startIndices(index) <= endIndices(activeSegment)
        if endIndices(index) > endIndices(activeSegment)
            endIndices(activeSegment) = endIndices(index);
        end
    else
        activeSegment = index;
        isSegmentActive(index) = 1;
    end
end
numSegments = sum(isSegmentActive);
segments = cell(1, numSegments);
limits = zeros(2, numSegments);
speechSegmentsIndices = find(isSegmentActive);
for index = 1: length(speechSegmentsIndices)
    segments{index} = audio(startIndices(speechSegmentsIndices(index)): ...
        endIndices(speechSegmentsIndices(index)));
    limits(:,index) = [startIndices(speechSegmentsIndices(index)); ...
        endIndices(speechSegmentsIndices(index))];
end

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
[featureVectors, segmentsPerFile] = gather(featureVectosTall, segmentsPerFileTall);
featureVectos = cat(2, featureVectors{:});
myLabels = adsTrain.Labels;
myLabels = repelem(myLabels, segmentsPerFile);
allFeatures = cat(2,featureVectors{:});
allFeatures(isinf(allFeatures)) = nan;
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