all: writer

writer: writer.c
	@echo "Compile using" ${CROSS_COMPILE}
	${CROSS_COMPILE}gcc writer.c -o writer

clean:
	rm -f *.o writer
