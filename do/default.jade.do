f="$(dirname "$2")/../$(basename "$2").jade"
redo-ifchange "$f"
cp "$f" "$3"

