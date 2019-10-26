f_name = 'audio_split/jack_hammer/jack_hammer4.wav';

[~, Fs] = audioread(f_name, [1 10]);
start_t = 1;
end_t = 9;
[y, Fs] = audioread(f_name, Fs * [start_t end_t]);
y = y(:,1); % get rid of second channel
y = y ./ max(abs(y)); % normalize audio
T = 1/Fs;
N = (length(y) * T) - T;
t = 0: T: N;

% Plot audio in time domain
figure;
plot(t, y); xlabel('Seconds'); ylabel('Amplitude');

% Plot audio's spectrogram
figure;
spectrogram(y(:,1), 128, 120, 128, Fs, 'yaxis');
figure;
spectrogram(y(:,1), 128, 120, 128, Fs, 'yaxis');
colormap hot
view(-45,65)

% Silence analysis
w_len = 50e-3 * Fs;
segs = buffer(y, w_len);

win = hann(w_len, 'periodic');
sig_energy = sum(segs.^2, 1) / w_len;
centroids = spectralCentroid(segs, Fs, 'Window', win, 'OverlapLength', 0);

T_E = mean(sig_energy) / 2;
T_C = 7000;
is_roi = (sig_energy >= T_E);% & (centroids <= T_C);

CC = repmat(centroids, w_len, 1);
CC = CC(:);
EE = repmat(sig_energy, w_len, 1);
EE = EE(:);
flags_2 = repmat(is_roi, w_len, 1);
flags_2 = flags_2(:);

figure

subplot(3, 1, 1);
plot(t, CC(1: length(y)), t, repmat(T_C, 1, length(t)), 'LineWidth', 2);
xlabel('Time (s)'); ylabel('Normalized Centroid');
legend('Centroid', 'Threshold'); title('Spectral Centroid');
grid on

subplot(3, 1, 2);
plot(t, EE(1: length(y)), t, repmat(T_E, 1, length(t)), 'LineWidth', 2);
xlabel('Time (s)'); ylabel('Normalized Energy');
legend('Energy', 'Threshold'); title('Window Energy');
grid on

subplot(3, 1, 3);
plot(t, y, t, flags_2(1: length(y)), 'LineWidth', 2);
xlabel('Time (s)'); ylabel('Audio');
legend('Audio', 'ROI'); title('Audio');
grid on
ylim([-1 1.1])
