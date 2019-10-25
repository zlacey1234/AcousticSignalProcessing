import os, subprocess

def main():
    p_split_dir = 'audio_pre_split'
    split_dir = 'audio_split'
    dir = ''
    n_dir = ''
    files = []
    for (dir, _, files) in os.walk(p_split_dir):
        if dir != p_split_dir:
            n_dir = os.path.join(os.getcwd(), dir).replace(p_split_dir, split_dir)
            if not os.path.isdir(n_dir):
                os.mkdir(n_dir)
            for file in files:
                file_path = os.path.join(os.getcwd(), dir, file)
                file_path_new = os.path.join(n_dir, file)
                file_path_new = file_path_new.split('.')
                subprocess.call(['ffmpeg', '-i', file_path, '-f', 'segment', '-segment_time', '10', '-c', 'copy', ''.join(file_path_new[0] + '%03d.' + 'wav')])

if __name__ == '__main__':
    main()