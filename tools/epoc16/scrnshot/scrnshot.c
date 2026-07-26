#include <plib.h>
#include <wlib.h>
#include <hwif.h>

#include <plib.h>
#include <wlib.h>

LOCAL_D WSERV_SPEC wSpec;

GLDEF_C VOID main(VOID)
	{
	TEXT name[64];
	p_scpy(&name[0], "M:\\RCONNECT\\SCRNSHOT.PIC");
	wConnect(&wSpec, 0, W_CONNECT_AT_BACK);
	gSaveBit(&name[0],0);
	}
