all:
	@bash compilation.sh

maj: ids fasm

ids:
	curl -k -o BIN/pci.ids "https://pci-ids.ucw.cz/v2.2/pci.ids"
	curl -o BIN/usb.ids "http://www.linux-usb.org/usb.ids" 

fasm:
	curl -k -o fasm.tgz "https://flatassembler.net/fasm-1.73.32.tgz"
	tar -xf fasm.tgz
	rm -rf fasm.tgz
	chmod 777 ./fasm/fasm
	-sudo cp ./fasm/fasm /bin
	rm -rf fasm
clean:
	rm -rf BIN/*.FE
	rm -rf BIN/*.MBR
	rm -rf BIN/*.BIN
	rm -rf BIN/SEAC.*

