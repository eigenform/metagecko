#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>

#include <unistd.h>
#include <gccore.h>
#include <ogcsys.h>
#include <network.h>
#include <fat.h>

#include <ogc/usbgecko.h>

static void *xfb = NULL;
static GXRModeObj *rmode = NULL;


static __inline__ int __send_command(s32 chn,u16 *cmd)
{
	s32 ret = 0;
	if(!EXI_Select(chn,EXI_DEVICE_0,EXI_SPEED1MHZ)) ret |= 0x01;
	if(!EXI_Imm(chn,cmd,sizeof(u16),EXI_READWRITE,NULL)) ret |= 0x02;
	if(!EXI_Sync(chn)) ret |= 0x04;
	if(!EXI_Deselect(chn)) ret |= 0x08;
	printf("__send_command error code: 0x%08x\n", ret);
	if(ret) return 0;
	return 1;
}
//static __inline__ void __usbgecko_exi_wait(s32 chn)
//{
//	u32 level;
//
//	_CPU_ISR_Disable(level);
//	if(!usbgecko_inited) __usbgecko_init();
//	while(EXI_Lock(chn,EXI_DEVICE_0,__usbgecko_exi_unlock)==0) {
//		LWP_ThreadSleep(wait_exi_queue[chn]);
//	}
//	_CPU_ISR_Restore(level);
//}



/* Typical libogc video/console initialization */
void xfb_init(void)
{
	VIDEO_Init();
	PAD_Init();
	rmode = VIDEO_GetPreferredMode(NULL);
	xfb = MEM_K0_TO_K1(SYS_AllocateFramebuffer(rmode));

	console_init(xfb, 20, 20, rmode->fbWidth, rmode->xfbHeight,
			rmode->fbWidth*VI_DISPLAY_PIX_SZ);

	VIDEO_Configure(rmode);
	VIDEO_SetNextFramebuffer(xfb);
	VIDEO_SetBlack(FALSE);
	VIDEO_Flush();
	VIDEO_WaitVSync();
	if(rmode->viTVMode&VI_NON_INTERLACE)
		VIDEO_WaitVSync();
}


void hexdump (char *desc, void *addr, int len)
{
    int i; unsigned char buff[17]; unsigned char *pc = (unsigned char*)addr;
    if (desc != NULL) printf ("%s:\n", desc);
    if (len == 0) { printf("  ZERO LENGTH\n"); return; }
    if (len < 0) { printf("  NEGATIVE LENGTH: %i\n",len); return; }
    for (i = 0; i < len; i++) {
        if ((i % 16) == 0) {
            if (i != 0) printf("  %s\n", buff);
            printf("  %04x ", i); }
        printf(" %02x", pc[i]);
        if ((pc[i] < 0x20) || (pc[i] > 0x7e)) buff[i % 16] = '.';
        else buff[i % 16] = pc[i];
        buff[(i % 16) + 1] = '\0'; }
    while ((i % 16) != 0) { printf("   "); i++; }
    printf("  %s\n", buff); 
}



extern void __exi_init(void);
int main(int argc, char **argv)
{
	xfb_init();

	printf("\x1b[2;0H");
	printf("\n");

	// Channel 1, device 0 is SLOT B
	//printf("usb_isgeckoalive() returned %d\n", usb_isgeckoalive(0));
	//sleep(5);

	u32 exi_id = -1;

	u16 mycmd = 0xdead;
	u16 mycmdresp = -1;
	u16 gecko_init_cmd = 0x9000;
	u16 wtf = 0x9000;
	s32 res;

	while(1) 
	{
		PAD_ScanPads();
		u32 pressed = PAD_ButtonsDown(0);

		// Test EXI_GetID
		if (pressed & PAD_BUTTON_X)
		{
			res = EXI_GetID(EXI_CHANNEL_1, EXI_DEVICE_0, &exi_id);
			printf("exi_id: 0x%08x (EXI_GetID: %d)\n", exi_id, res);
		}

		// Test Gecko functions in libogc
		if (pressed & PAD_BUTTON_B) 
		{
			EXI_Lock(EXI_CHANNEL_1, EXI_DEVICE_0, NULL);
			EXI_Select(EXI_CHANNEL_1, EXI_DEVICE_0, EXI_SPEED1MHZ);

			EXI_Imm(EXI_CHANNEL_1, &wtf, 2, EXI_READWRITE, NULL);
			EXI_Sync(EXI_CHANNEL_1);

			EXI_Deselect(EXI_CHANNEL_1);
			EXI_Unlock(EXI_CHANNEL_1);
			printf("wtf: 0x%04x (expected 0x0470)\n", wtf);

		}

		/* Test command and response for some arbitrary user-defined protocol.
		 * Expect the value 0xbeef from a command 0xdead. */
		if (pressed & PAD_BUTTON_A) 
		{
			EXI_Lock(EXI_CHANNEL_1, EXI_DEVICE_0, NULL);
			EXI_Select(EXI_CHANNEL_1, EXI_DEVICE_0, EXI_SPEED1MHZ);

			EXI_Imm(EXI_CHANNEL_1, &mycmd, 2, EXI_WRITE, NULL);
			EXI_Sync(EXI_CHANNEL_1);
			EXI_Imm(EXI_CHANNEL_1, &mycmdresp, 2, EXI_READ, NULL);
			EXI_Sync(EXI_CHANNEL_1);

			EXI_Deselect(EXI_CHANNEL_1);
			EXI_Unlock(EXI_CHANNEL_1);
			printf("mycmdresp: 0x%04x (expected 0xbeef)\n", mycmdresp);
		}
		if (pressed & PAD_BUTTON_Y) {
			printf("usb_isgeckoalive: %d\n", 
					 usb_isgeckoalive(EXI_CHANNEL_1));
		}

		if (pressed & PAD_BUTTON_START)
			exit(0);
		VIDEO_WaitVSync();
	}
	return 0;
}
