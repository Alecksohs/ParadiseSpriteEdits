import os
import re

def extract_turf_types_from_dmm(file_path):
    """
    Extracts all unique turf types from a .dmm file.

    :param file_path: Path to the .dmm file
    :return: Set of turf types
    """
    turf_types = set()
    turf_pattern = re.compile(r"/turf/[^\s,)]+")

    with open(file_path, "r", encoding="utf-8") as file:
        content = file.read()

    matches = turf_pattern.findall(content)
    turf_types.update(matches)

    return turf_types

def find_all_turf_types_in_folder(folder_path):
    """
    Recursively finds all .dmm files in a folder and extracts all unique turf types.

    :param folder_path: Path to the folder
    :return: Set of all unique turf types
    """
    all_turf_types = set()

    for root, _, files in os.walk(folder_path):
        for file in files:
            if file.endswith(".dmm"):
                file_path = os.path.join(root, file)
                turfs = extract_turf_types_from_dmm(file_path)
                all_turf_types.update(turfs)

    return all_turf_types

def main():
    folder_path = input("Enter the path to the folder containing .dmm files: ").strip()
    if not os.path.exists(folder_path):
        print("The specified folder does not exist.")
        return

    all_turf_types = find_all_turf_types_in_folder(folder_path)
    print("All unique turf types found:")
    for turf in sorted(all_turf_types):
        print(turf)

if __name__ == "__main__":
    main()
