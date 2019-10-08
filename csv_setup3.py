import soundfile as sf
import os, csv, subprocess

def main(dir_name):
    csv_data = [['path', 'label', 'length', 'Fs']]
    dir = ''
    files = []
    for (dir, _, files) in os.walk(dir_name):
        if dir != dir_name:
            for file in files:
                file_path = os.path.join(os.getcwd(), dir, file)
                file_path_new = os.path.join(os.getcwd(), dir, 'mono' + file)
                subprocess.call(['ffmpeg', '-i', file_path, '-ac', '1', file_path_new])
                os.replace(file_path_new, file_path)
                f = sf.SoundFile(file_path)
                csv_data.append([file_path, dir[dir.index('\\') + 1:], len(f) / f.samplerate, f.samplerate])
    with open(os.path.join(dir_name, 'audio_data.csv'), 'w+') as csv_file:
        writer = csv.writer(csv_file, delimiter=',')
        writer.writerows(csv_data)

if __name__ == '__main__':
    main('audio')