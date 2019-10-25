import os, subprocess

def main(dir_name):
    dir = ''
    files = []
    for (dir, cat, files) in os.walk(dir_name):
        count = 1
        if dir != dir_name:
            for file in files:
                if file.split('.')[-1] != 'wav':
                    file_path = os.path.join(os.getcwd(), dir, file)
                    file_name_new = file.split('.')
                    file_name_new[-1] = ''
                    file_path_new = os.path.join(os.getcwd(), dir, ''.join(file_name_new) + '.wav')
                    subprocess.call(['ffmpeg', '-i', file_path, file_path_new])
                    os.remove(file_path)

if __name__ == '__main__':
    main('audio_pre_split')