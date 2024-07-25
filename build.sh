# Define current project and other variables
PROJECT=$(cat CURRENT_PROJECT)
CURRENTDIR=$(pwd)

# Compile C code
cd src/$PROJECT
mkdir build
mkdir bin
#make clean
make all #make all
cd $CURRENTDIR

# Compile verilator code
cd verilator
./verilate.sh $PROJECT
cd $CURRENTDIR

# Build target locations
TARGETS=( verilator rtl )

# Hexify rom and font and copy to build targets
for TARGET in "${TARGETS[@]}"; do
od -An -t x1 -v src/$PROJECT/bin/rom.bin > $TARGET/Aznable/rom.hex
od -An -t x1 -v font.pf > $TARGET/Aznable/font.hex
done

# Hexify resource binarys and copy to build targets
RESOURCES=( sprite palette music sound tilemap )
for RESOURCE in "${RESOURCES[@]}"; do
if [ -r "resources/$PROJECT/$RESOURCE.bin" ]; then
echo "Updating resources/$PROJECT/$RESOURCE.bin"
for TARGET in "${TARGETS[@]}"; do
od -An -t x1 -v resources/$PROJECT/$RESOURCE.bin > $TARGET/Aznable/$RESOURCE.hex
done
fi
done
