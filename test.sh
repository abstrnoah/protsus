source lib.sh

passphrase=infected

mkdir -p protsus-test-target
cd protsus-test-target

echo "Super secret stuff" > testfile.txt

protect "testfile.txt"


