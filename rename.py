import os

def main(dir_name):
    dir = ''
    files = []
    for (dir, cat, files) in os.walk(dir_name):
        count = 1
        if dir != dir_name:
            for file in files:
                file_path = os.path.join(os.getcwd(), dir, file)
                file_path_new = os.path.join(os.getcwd(), dir, dir[dir.index('\\') + 1:] + str(count) + '.wav')
                os.replace(file_path, file_path_new)
                count += 1

if __name__ == '__main__':
    main('audio_split')