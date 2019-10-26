type = 'killer_whale';
datafolder = './audio_split/';
ads0 = audioDatastore(datafolder,'IncludeSubfolders',true);
metadata = readtable(fullfile(datafolder, strcat('audio_data_', type, '.csv')), 'FileType', 'text', 'Delimiter', ',');
head(metadata)

csvFiles = metadata.path;
adsFiles = ads0.Files;
%adsFiles = cellfun(@HelperGetFilePart,adsFiles,'UniformOutput',false);
[~,indA,indB] = intersect(adsFiles,csvFiles);

adsTrain = subset(ads0, indA);
species = metadata.label;
species = species(indB);
adsTrain.Labels = species;

istype = find(categorical(adsTrain.Labels) == type);
isnottype = find(categorical(adsTrain.Labels) == strcat("not_", type));
numFilesPerType = numel(istype);
isnottype = isnottype(randperm(numel(isnottype)));
adsTrain = subset(adsTrain,[isnottype(1:numFilesPerType) istype(1:numFilesPerType)]);

adsTrain = shuffle(adsTrain);
countEachLabel(adsTrain)

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
featureVectors = cat(2, featureVectors{:});
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
speciesTrain = repelem(myLabels,[sequencePerSegment{:}]);

% skip validation data set, reuse the training set for now
metadata = readtable(fullfile(datafolder, strcat('audio_data_', type, '.csv')), 'FileType', 'text', 'Delimiter', ',');

csvFiles = metadata.path;
adsFiles = ads0.Files;
%adsFiles = cellfun(@HelperGetFilePart,adsFiles,'UniformOutput',false);
[~,indA,indB] = intersect(adsFiles,csvFiles);

adsVal = subset(ads0,indA);
species = metadata.label;
species = species(indB);
adsVal.Labels = species;

istype = find(categorical(adsVal.Labels) == type);
isnottype = find(categorical(adsVal.Labels) == strcat("not_", type));
numFilesPerType = numel(istype);
isnottype = isnottype(randperm(numel(isnottype)));
adsVal = subset(adsVal,[isnottype(1:numFilesPerType) istype(1:numFilesPerType)]);

countEachLabel(adsVal)

T = tall(adsVal);
segments = cellfun(@(x)HelperSegmentSpeech(x,Fs),T,"UniformOutput",false);
segmentsPerFileTall = cellfun(@numel,segments);
featureVectorsTall = cellfun(@(x)HelperGetFeatureVectors(x,extractor),segments,"UniformOutput",false);
[featureVectors,valSegmentsPerFile] = gather(featureVectorsTall,segmentsPerFileTall);
featureVectors = cat(2,featureVectors{:});
valSegmentLabels = repelem(adsVal.Labels,valSegmentsPerFile);

featureVectors = cellfun(@(x)(x-M)./S,featureVectors,'UniformOutput',false);
for ii = 1:numel(featureVectors)
    idx = find(isnan(featureVectors{ii}));
    if ~isempty(idx)
        featureVectors{ii}(idx) = 0;
    end
end

[featuresValidation,valSequencePerSegment] = HelperFeatureVector2Sequence(featureVectors,featureVectorsPerSequence,featureVectorOverlap);
speciesValidation = repelem(valSegmentLabels,[valSequencePerSegment{:}]);
%--------------------------------------------------------------------------

layers = [ ...
    sequenceInputLayer(size(featuresTrain{1},1))
    bilstmLayer(50,"OutputMode","sequence")
    dropoutLayer(0.1)
    bilstmLayer(50,"OutputMode","last")
    fullyConnectedLayer(2)
    softmaxLayer
    classificationLayer];

miniBatchSize = 128;
validationFrequency = floor(numel(speciesTrain)/miniBatchSize);
options = trainingOptions("adam", ...
    "MaxEpochs",4, ...
    "MiniBatchSize",miniBatchSize, ...
    "Plots","training-progress", ...
    "Verbose",false, ...
    "Shuffle","every-epoch", ...
    "LearnRateSchedule","piecewise", ...
    "LearnRateDropFactor",0.1, ...
    "LearnRateDropPeriod",2,...
    'ValidationData',{featuresValidation,categorical(speciesValidation)}, ...
    'ValidationFrequency',validationFrequency);

net = trainNetwork(featuresTrain,categorical(speciesTrain),layers,options);
trainPred = classify(net,featuresTrain);
figure
cm = confusionchart(categorical(speciesTrain),trainPred,'title','Training Accuracy');
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';

[valPred,valScores] = classify(net,featuresValidation);

figure
cm = confusionchart(categorical(speciesValidation),valPred,'title','Validation Set Accuracy');
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';

sequencePerFile = zeros(size(valSegmentsPerFile));
valSequencePerSegmentMat = cell2mat(valSequencePerSegment);
idx = 1;
for ii = 1:numel(valSegmentsPerFile)
    sequencePerFile(ii) = sum(valSequencePerSegmentMat(idx:idx+valSegmentsPerFile(ii)-1));
    idx = idx + valSegmentsPerFile(ii);
end

numFiles = numel(adsVal.Files);
actualSpecies = categorical(adsVal.Labels);
predictedSpecies = actualSpecies;      
scores = cell(1,numFiles);
counter = 1;
cats = unique(actualSpecies);
for index = 1:numFiles
    scores{index}      = valScores(counter: counter + sequencePerFile(index) - 1,:);
    m = max(mean(scores{index},1),[],1);
    if m(1) >= m(2)
        predictedSpecies(index) = cats(1);
    else
        predictedSpecies(index) = cats(2); 
    end
    counter = counter + sequencePerFile(index);
end

figure
cm = confusionchart(actualSpecies,predictedSpecies,'title','Validation Set Accuracy - Max Rule');
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';