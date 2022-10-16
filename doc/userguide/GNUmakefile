default:
	cat userguide.ms | tbl | preconv  | eqn | groff -m ms -p -Tps > userguide.ps
	ps2pdf14 -dPDFSETTINGS=/printer "userguide.ps" "userguide.pdf"

clean:
	rm userguide.ps
	rm userguide.pdf

