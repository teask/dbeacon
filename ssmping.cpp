#include "dbeacon.h"
#include "address.h"
#include "msocket.h"

enum {
	SSMPING_REQUEST = 'Q',
	SSMPING_ANSWER = 'A'
};

static const int maxSSMPingMessage = 1000;

static const char *SSMPingV6ResponseChannel = "ff3e::4321:1234";
static const char *SSMPingV4ResponseChannel = "232.43.211.234";

static int ssmPingSocket = -1;

int SetupSSMPing() {
	address addr;

	if (!addr.set_family(beaconUnicastAddr.family()))
		return -1;

	if (!addr.set_port(4321))
		return -1;

	ssmPingSocket = SetupSocket(addr, true, false);
	if (ssmPingSocket < 0)
		return -1;

	if (!SetHops(ssmPingSocket, addr, 64)) {
		close(ssmPingSocket);
		return -1;
	}

	ListenTo(SSMPING, ssmPingSocket);

	return 0;
}

void handle_ssmping(int s, address &from, const address &to, uint8_t *buffer, int len) {
	if (buffer[0] != SSMPING_REQUEST || len > maxSSMPingMessage)
		return;

	if (verbose > 1) {
		char tmp[64];
		from.print(tmp, sizeof(tmp));
		fprintf(stderr, "Got SSM Ping Request from %s\n", tmp);
	}

	buffer[0] = SSMPING_ANSWER;

	if (SendTo(s, buffer, len, to, from) < 0)
		return;

	if (!from.set_addr(from.family() == AF_INET6 ? SSMPingV6ResponseChannel :
							SSMPingV4ResponseChannel))
		return;

	SendTo(s, buffer, len, to, from);
}

