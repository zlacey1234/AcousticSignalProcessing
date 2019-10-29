function [type1, type2, type3] = classify_sound(file_path)
    type1 = 0;
    type2 = 0;
    type3 = 0;
    persistent net
    persistent extractor
    if isempty(net) || isempty(extractor)
        load('neural_payload.mat', 'net', 'extractor');
    end
    [x, Fs] = audioread(file_path);
    x = x(:,1);
    [P, Q] = rat(48000/Fs);
    x = resample(x,P,Q);
    segments = HelperSegmentSpeech(x, 48000);
    segment_features = zeros(1, 28);
    for i = 1:numel(segments)
        segment_features = segment_features + segment_analysis(extractor, net, cell2mat(segments(i)));
    end
    while sum(segment_features) ~= 0 && type3 == 0
        [~, i] = max(segment_features);
        if type1 == 0
            type1 = i;
        elseif type2 == 0
            type2 = i;
        else
            type3 = i;
        end
        segment_features(i) = 0;
    end
end

function scores = segment_analysis(extractor, net, x)
    features = extract(extractor, x);
    features = features';
    [~, scores] = classify(net, features);
    scores(scores < 0.5) = 0;
end