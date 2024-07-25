OPTIMIZE="-O3 --x-assign fast --x-initial fast --noassert"
WARNINGS="-Wno-TIMESCALEMOD"
DEFINES="+define+SIMULATION=1 "
readarray -t DEFINE_LINES < ../src/$1/.define
for i in "${DEFINE_LINES[@]}"
do
	if ! [[ $i == //* ]]; then
		DEFINES+="+define+$i=1 "
	fi
done
echo "verilator -cc --compiler msvc $DEFINES $WARNINGS $OPTIMIZE"
verilator -cc --compiler msvc $DEFINES $WARNINGS $OPTIMIZE \
--converge-limit 6000 \
--top-module emu sim.v \
-I../rtl \
-I../rtl/JTFRAME \
-I../rtl/jt49 \
-I../rtl/jt5205 \
-I../rtl/tv80
