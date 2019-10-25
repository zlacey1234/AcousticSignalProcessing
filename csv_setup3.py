import soundfile as sf
import os, csv, subprocess

def main(dir_name):
    csv_data = [['path', 'label', 'length', 'Fs']]
    dir = ''
    labels = set()
    files = []
    count = 0
    for (dir, _, files) in os.walk(dir_name):
        if dir != dir_name:
            for file in files:
                file_path = os.path.join(os.getcwd(), dir, file)
                file_path_new = os.path.join(os.getcwd(), dir, 'mono' + file)
                subprocess.call(['ffmpeg', '-loglevel', 'quiet', '-i', file_path, '-ar', '48000', '-ac', '1', file_path_new])
                os.replace(file_path_new, file_path)
                f = sf.SoundFile(file_path)
                labels.add(dir[dir.index('\\') + 1:])
                csv_data.append([file_path, dir[dir.index('\\') + 1:], len(f) / f.samplerate, f.samplerate])
                if count % 6 == 0:
                    print('Processing <->   ', end='\r')
                elif count % 6 == 1:
                    print('Processing  <->  ', end='\r')
                elif count % 6 == 2:
                    print('Processing   <-> ', end='\r')
                elif count % 6 == 3:
                    print('Processing    <->', end='\r')
                elif count % 6 == 4:
                    print('Processing   <-> ', end='\r')
                elif count % 6 == 5:
                    print('Processing  <->  ', end='\r')
                count += 1
                    
    with open(os.path.join(dir_name, 'audio_data_master.csv'), 'w+') as csv_file:
        writer = csv.writer(csv_file, delimiter=',')
        writer.writerows(csv_data)
    
    for label in labels:
        with open(os.path.join(dir_name, 'audio_data_' + label + '.csv'), 'w+') as csv_file:
            writer = csv.writer(csv_file, delimiter=',')
            writer.writerow(csv_data[0])
            for row in csv_data[1:-1]:
                if row[1] == label:
                    writer.writerow(row)
                else:
                    writer.writerow([row[0], 'not_' + label, row[2], row[3]])
     
    print('Done!                 ')

if __name__ == '__main__':
    main('audio_split')