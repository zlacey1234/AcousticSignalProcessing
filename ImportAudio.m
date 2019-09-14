%
% AUTHORS: PABLO GARCIA BELTRAN, ZACHARY LACEY
% AFFILIATION : UNIVERSITY OF MARYLAND
% EMAIL : pgarciab@umd.edu
%         zlacey@umd.edu
%         zlacey1234@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[song, fs] = audioread('When_Elon_Musk_realised_China_s_richest_man_is_an_idiot_Jack_Ma.wav');
t = 0:1/fs:200;
gong = audioplayer(song, fs);
play(gong);
% nwin = 63;
% wind = kaiser(nwin,17);
% nlap = nwin-10;
% nfft = 256;
% 
% spectrogram(song(:,1),wind,nlap,nfft,fs,'yaxis')