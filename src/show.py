import sys

def main():
    if len(sys.argv) != 3:
        print("Usage: python show.py <annotation file> <ascii file>")
        print("Example: python show.py todo.sample.0.annotation.txt todo.sample.0.txt")
        sys.exit(1)

    with open(sys.argv[1], 'r') as annotation_file:
        annotations = annotation_file.read().strip().split('\n')

    with open(sys.argv[2], 'r') as ascii_file:
        lines = ascii_file.read().split('\n')

    for pair in annotations:
        (end, start) = pair.split(' ')[:2]

        if end == start:
            continue

        start_line = lines[int(start)].strip()
        end_line = lines[int(end)].strip()

        print(start_line)
        print(end_line)
        print()

if __name__ == "__main__":
    main()
