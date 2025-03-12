import os
import argparse

def find_empty_files(directory, recurse):
    # Walk though the directory structure
    for root, dirs, files in os.walk(directory):
        for file in files:
            file_path = os.path.join(root, file)
            try:
                if os.path.getsize(file_path) == 0:
                    print(f"Empty file found: {file_path}")
            except Exception as e:
                print(f"An error occurred processing file {file_path}: {e}")

        if not recurse:
            break

if __name__ == "__main__":  
    parser = argparse.ArgumentParser(description="Find empty files in a specified directory.")
    parser.add_argument('-d', '--directory', required=True, help="The directory where the search for empty files begins.")
    parser.add_argument('-r', '--recurse', action='store_true', help="Recursively search subdirectories.")
    args = parser.parse_args()

    find_empty_files(args.directory, args.recurse)
