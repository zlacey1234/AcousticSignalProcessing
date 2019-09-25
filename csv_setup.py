import soundfile as sf
import os, csv

def main(dir_name):
    csv_data = [['file_path', 'label', 'length']]
    dir = ''
    files = []
    for (dir, _, files) in os.walk(dir_name):
        if dir != dir_name:
            for file in files:
                file_path = os.path.join(dir, file)
                f = sf.SoundFile(file_path)
                csv_data.append([file_path, dir[dir.index('\\') + 1:], len(f) / f.samplerate])
    with open('audio_data.csv', 'wb+') as csv_file:
        writer = csv.writer(csv_file, delimiter=',')
        writer.writerows(csv_data)

if __name__ == '__main__':
    main('audio')