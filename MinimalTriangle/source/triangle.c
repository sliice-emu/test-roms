// adapted from	the	original acube demo	by tkcne.

// enjoy

//#include <stdlib.h>
#include <string.h>
#include <malloc.h>
//#include <math.h>
#include <gccore.h>
//#include <wiiuse/wpad.h>

GXRModeObj	*screenMode;
static void	*frameBuffer;
static vu8	readyForCopy;
#define	FIFO_SIZE (256*1024)

s16	vertices[] ATTRIBUTE_ALIGN(32) = {
	0, 15, 0,
	-15, -15, 0,
	15,	-15, 0
};

u8 colors[]	ATTRIBUTE_ALIGN(32)	= {
255, 0,	0, 255,		// red
0, 255,	0, 255,		// green
0, 0, 255, 255};	// blue

void update_screen(Mtx viewMatrix);
static void	copy_buffers(u32 unused);

int	main(void) {
	Mtx	view;
	Mtx44	projection;
	GXColor	backgroundColor	= {255, 255, 255, 255}; //was {0, 0, 0,	255};
	void *fifoBuffer = NULL;

	VIDEO_Init();
	//WPAD_Init();

	screenMode = VIDEO_GetPreferredMode(NULL);

	frameBuffer	= SYS_AllocateFramebuffer(screenMode);
	//frameBuffer	= MEM_K0_TO_K1(SYS_AllocateFramebuffer(screenMode)); not casting from cached to uncached virtual address doesn't seem to break anything

	VIDEO_Configure(screenMode);
	VIDEO_SetNextFramebuffer(frameBuffer);
	VIDEO_SetPostRetraceCallback(copy_buffers);
	VIDEO_SetBlack(FALSE);
	VIDEO_Flush();

	fifoBuffer = memalign(32,FIFO_SIZE);
	//fifoBuffer = MEM_K0_TO_K1(memalign(32,FIFO_SIZE)); not casting from cached to uncached virtual address doesn't seem to break anything
	memset(fifoBuffer,	0, FIFO_SIZE);

	GX_Init(fifoBuffer, FIFO_SIZE);
	GX_SetCopyClear(backgroundColor, 0x00ffffff);
	GX_SetViewport(0,0,screenMode->fbWidth,screenMode->efbHeight,0,1);
	GX_SetDispCopyYScale((f32)screenMode->xfbHeight/(f32)screenMode->efbHeight);
	GX_SetScissor(0,0,screenMode->fbWidth,screenMode->efbHeight);
	GX_SetDispCopySrc(0,0,screenMode->fbWidth,screenMode->efbHeight);
	GX_SetDispCopyDst(screenMode->fbWidth,screenMode->xfbHeight);
	GX_SetCopyFilter(screenMode->aa,screenMode->sample_pattern,
					 GX_TRUE,screenMode->vfilter);
	GX_SetFieldMode(screenMode->field_rendering,
					((screenMode->viHeight==2*screenMode->xfbHeight)?GX_ENABLE:GX_DISABLE));

	GX_SetCullMode(GX_CULL_NONE);
	GX_CopyDisp(frameBuffer,GX_TRUE);
	GX_SetDispCopyGamma(GX_GM_1_0);

	guVector camera =	{0.0F, 0.0F, 0.0F};
	guVector up =	{0.0F, 1.0F, 0.0F};
	guVector look	= {0.0F, 0.0F, -1.0F};

	guPerspective(projection, 60, 1.33F, 10.0F,	300.0F);
	GX_LoadProjectionMtx(projection, GX_PERSPECTIVE);

	GX_ClearVtxDesc();
	GX_SetVtxDesc(GX_VA_POS, GX_INDEX8);
	GX_SetVtxDesc(GX_VA_CLR0, GX_INDEX8);
	GX_SetVtxAttrFmt(GX_VTXFMT0, GX_VA_POS,	GX_POS_XYZ,	GX_S16,	0);
	GX_SetVtxAttrFmt(GX_VTXFMT0, GX_VA_CLR0, GX_CLR_RGBA, GX_RGBA8,	0);
	GX_SetArray(GX_VA_POS, vertices, 3*sizeof(s16));

	// Disable any sort of TEV color/texture stuff
	// GX_SetArray(GX_VA_CLR0,	colors,	4*sizeof(u8));
	// GX_SetNumChans(1);
	// GX_SetNumTexGens(0);
	// GX_SetTevOrder(GX_TEVSTAGE0, GX_TEXCOORDNULL, GX_TEXMAP_NULL, GX_COLOR0A0);
	// GX_SetTevOp(GX_TEVSTAGE0, GX_PASSCLR);

	while (1)
	{
		guLookAt(view, &camera,	&up, &look);
		// GX_SetViewport(0,0,screenMode->fbWidth,screenMode->efbHeight,0,1); //why bother setting the view port every frame?
		GX_InvVtxCache(); //Commenting out this and the next line makes the rom break on hw, but not dolphin
		GX_InvalidateTexAll(); 
		update_screen(view);

		// WPAD_ScanPads();
		// if (WPAD_ButtonsDown(0) & WPAD_BUTTON_HOME) exit(0);
	}
	return 0;
}

void update_screen(	Mtx	viewMatrix )
{
	Mtx	modelView;

	guMtxIdentity(modelView);
	guMtxTransApply(modelView, modelView, 0.0F,	0.0F, -50.0F);
	guMtxConcat(viewMatrix,modelView,modelView);

	GX_LoadPosMtxImm(modelView,	GX_PNMTX0);

	GX_Begin(GX_TRIANGLES, GX_VTXFMT0, 3);

	GX_Position1x8(0);
	GX_Color1x8(0); //Since TEV stuff hasn't been initialised, the GX_Color1x8 commands do nothing.
	GX_Position1x8(1); 
	GX_Color1x8(1); //On dolphin a black triangle is displayed, and on hardware a grey one
	GX_Position1x8(2);
	GX_Color1x8(2);

	GX_End();

	GX_DrawDone();
	readyForCopy = GX_TRUE;

	//VIDEO_WaitVSync(); This is terrible for performance since we're basically drawing to the screen as fast as possible.
	return;
}

static void	copy_buffers(u32 count __attribute__ ((unused)))
{
	if (readyForCopy==GX_TRUE) {
		GX_SetZMode(GX_TRUE, GX_LEQUAL,	GX_TRUE);
		//GX_SetColorUpdate(GX_TRUE); //Dunno what this does.
		GX_CopyDisp(frameBuffer,GX_TRUE);
		GX_Flush();
		readyForCopy = GX_FALSE;
	}
}
