#include <syslog.h>
#include <stdlib.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <unistd.h>
#include <string.h>
 
int main(int argc, char **argv) {

	openlog("aeld", LOG_CONS, LOG_USER);

	setlogmask(LOG_UPTO(LOG_DEBUG));
	
	if (argc != 3) {
		syslog(LOG_ERR, "Arguments writefile and writestr not provided");	
		exit(1);
	}

	char* writefile = argv[1];
	char* writestr = argv[2];

	syslog(LOG_DEBUG, "Got arguments writefile %s and writestr %s", writefile, writestr);

	int fd = open(writefile, O_WRONLY | O_TRUNC | O_CREAT, S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH);

	if (fd == -1) {
		syslog(LOG_ERR, "Could not open file %s for writing", writefile);
	}

	ssize_t wroteBytes = write(fd, writestr, strlen(writestr));

	if (wroteBytes == -1) {
		syslog(LOG_ERR, "Could to write string %s to file %s", writestr, writefile);
	}

	closelog();
}



