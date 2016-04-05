local ffi = require("ffi")
local magick = require("magick")
local cvCore, cvHighgui, cvImgproc, cvObjdetect = 
	ffi.load("opencv_core"), 
	ffi.load("opencv_highgui"), 
	ffi.load("opencv_imgproc"),
	ffi.load("opencv_objdetect")

ffi.cdef[[

	/*---------------------------------------------------------------------------------------*/
	/*											                                             */
	/*											Types                                        */
	/*                                                                                       */
	/*---------------------------------------------------------------------------------------*/

	typedef unsigned char uchar;
	typedef signed char schar;
	
	typedef struct CvMat {
	    int type;
	    int step;
	    /* for internal use only */
	    int* refcount;
	    int hdr_refcount;
	    union {
	        uchar* ptr;
	        short* s;
	        int* i;
	        float* fl;
	        double* db;
	    } data;
	    int rows;
	    int cols;
	} CvMat;
	
	typedef struct _IplROI
	{
	    int  coi; /* 0 - no COI (all channels are selected), 1 - 0th channel is selected ...*/
	    int  xOffset;
	    int  yOffset;
	    int  width;
	    int  height;
	} IplROI;
	
	typedef struct _IplImage {
	    int		nSize;						/* sizeof(IplImage) */
	    int		ID;							/* version (=0)*/
	    int		nChannels;					/* Most of OpenCV functions support 1,2,3 or 4 channels */
	    int		alphaChannel;				/* Ignored by OpenCV */
	    int		depth;						/* Pixel depth in bits: IPL_DEPTH_8U, IPL_DEPTH_8S, IPL_DEPTH_16S,
											   IPL_DEPTH_32S, IPL_DEPTH_32F and IPL_DEPTH_64F are supported.  */
	
	    char	colorModel[4];				/* Ignored by OpenCV */
	    char	channelSeq[4];				/* ditto */
	    int		dataOrder;					/* 0 - interleaved color channels, 1 - separate color channels.
											cvCreateImage can only create interleaved images */
	
	    int		origin;						/* 0 - top-left origin,
											1 - bottom-left origin (Windows bitmaps style).  */
	
	    int		align;						/* Alignment of image rows (4 or 8).
											OpenCV ignores it and uses widthStep instead.    */
	
	    int		width;						/* Image width in pixels.                            */
	    int		height;						/* Image height in pixels.                           */
	    struct	_IplROI *roi;				/* Image ROI. If NULL, the whole image is selected.  */
	    struct	_IplImage *maskROI;			/* Must be NULL. */
	    void*	imageId;						/* "           " */
	    struct	_IplTileInfo *tileInfo;		/* "           " */
	    int		imageSize;					/* Image data size in bytes
											(==image->height*image->widthStep
											in case of interleaved data)*/
	
	    char*	imageData;					/* Pointer to aligned image data.         */
	    int		widthStep;					/* Size of aligned image row in bytes.    */
	    int		BorderMode[4];				/* Ignored by OpenCV.                     */
	    int		BorderConst[4];				/* Ditto.                                 */
	    char*	imageDataOrigin;			/* Pointer to very origin of image data
											(not necessarily aligned) -
											needed for correct deallocation */
	} IplImage;
	
	typedef void CvArr;
	
	typedef struct CvPoint {
	    int x;
	    int y;
	} CvPoint;
	
	typedef struct CvRect {
	    int x;
	    int y;
	    int width;
	    int height;
	} CvRect;
	
	typedef struct CvSize {
	    int width;
	    int height;
	} CvSize;
	
	typedef struct CvScalar {
	    double val[4];
	} CvScalar;
	
	
	/* Font structure */
	typedef struct CvFont {
		const char* nameFont;   		//Qt:nameFont
		CvScalar color;       		//Qt:ColorFont -> cvScalar(blue_component, green_component, red\_component[, alpha_component])
		int         font_face;   		//Qt: bool italic         /* =CV_FONT_* */
		const int*  ascii;      		/* font data and metrics */
		const int*  greek;
		const int*  cyrillic;
		float       hscale, vscale;
		float       shear;      		/* slope coefficient: 0 - normal, >0 - italic */
		int         thickness;    	//Qt: weight               /* letters thickness */
		float       dx;       		/* horizontal interval between letters */
		int         line_type;    	//Qt: PointSize
	} CvFont;
	
	
	/****************************************************************************************\
	*                                   Dynamic Data structures                              *
	\****************************************************************************************/

	/******************************** Memory storage ****************************************/

	typedef struct CvMemBlock {
	    struct CvMemBlock*  prev;
	    struct CvMemBlock*  next;
	} CvMemBlock;

	typedef struct CvMemStorage {
	    int signature;
	    CvMemBlock* bottom;           /* First allocated block.                   */
	    CvMemBlock* top;              /* Current memory block - top of the stack. */
	    struct  CvMemStorage* parent; /* We get new blocks from parent as needed. */
	    int block_size;               /* Block size.                              */
	    int free_space;               /* Remaining free space in current block.   */
	} CvMemStorage;
	
	typedef struct CvMemStoragePos {
	    CvMemBlock* top;
	    int free_space;
	} CvMemStoragePos;
	
	
	/*********************************** Sequence *******************************************/

	typedef struct CvSeqBlock {
		
		struct CvSeqBlock*  prev; 	/* Previous sequence block.                   */
		struct CvSeqBlock*  next; 	/* Next sequence block.                       */
		int start_index;				/* Index of the first element in the block +  */
	                              	/* sequence->first->start_index.              */
		int count;             		/* Number of elements in the block.           */
		schar* data;              	/* Pointer to the first element of the block. */
	} CvSeqBlock;


	/*
	   Read/Write sequence.
	   Elements can be dynamically inserted to or deleted from the sequence.
	*/

	typedef struct CvSeq {
		int       flags;             /* Miscellaneous flags.     */      
		int       header_size;       /* Size of sequence header. */      
		struct    CvSeq* h_prev; 		/* Previous sequence.       */      
		struct    CvSeq* h_next; 		/* Next sequence.           */      
		struct    CvSeq* v_prev; 		/* 2nd previous sequence.   */    
		struct    CvSeq* v_next;  	/* 2nd next sequence.       */
		                                        
		int       total;          	/* Total number of elements.            */  
		int       elem_size;      	/* Size of sequence element in bytes.   */  
		schar*    block_max;    	  	/* Maximal bound of the last block.     */ 
		schar*    ptr;          	  	/* Current write pointer.               */  
		int       delta_elems;    	/* Grow seq this many at a time.        */  
		CvMemStorage* storage;    	/* Where the seq is stored.             */  
		CvSeqBlock* free_blocks;  	/* Free blocks list.                    */  
		CvSeqBlock* first;        	/* Pointer to the first sequence block. */
	} CvSeq;
	
	/* Constants for color conversion */
	enum {
	    CV_BGR2BGRA    =0,
	    CV_RGB2RGBA    =CV_BGR2BGRA,

	    CV_BGRA2BGR    =1,
	    CV_RGBA2RGB    =CV_BGRA2BGR,

	    CV_BGR2RGBA    =2,
	    CV_RGB2BGRA    =CV_BGR2RGBA,

	    CV_RGBA2BGR    =3,
	    CV_BGRA2RGB    =CV_RGBA2BGR,

	    CV_BGR2RGB     =4,
	    CV_RGB2BGR     =CV_BGR2RGB,

	    CV_BGRA2RGBA   =5,
	    CV_RGBA2BGRA   =CV_BGRA2RGBA,

	    CV_BGR2GRAY    =6,
	    CV_RGB2GRAY    =7,
	    CV_GRAY2BGR    =8,
	    CV_GRAY2RGB    =CV_GRAY2BGR,
	    CV_GRAY2BGRA   =9,
	    CV_GRAY2RGBA   =CV_GRAY2BGRA,
	    CV_BGRA2GRAY   =10,
	    CV_RGBA2GRAY   =11,

	    CV_BGR2BGR565  =12,
	    CV_RGB2BGR565  =13,
	    CV_BGR5652BGR  =14,
	    CV_BGR5652RGB  =15,
	    CV_BGRA2BGR565 =16,
	    CV_RGBA2BGR565 =17,
	    CV_BGR5652BGRA =18,
	    CV_BGR5652RGBA =19,

	    CV_GRAY2BGR565 =20,
	    CV_BGR5652GRAY =21,

	    CV_BGR2BGR555  =22,
	    CV_RGB2BGR555  =23,
	    CV_BGR5552BGR  =24,
	    CV_BGR5552RGB  =25,
	    CV_BGRA2BGR555 =26,
	    CV_RGBA2BGR555 =27,
	    CV_BGR5552BGRA =28,
	    CV_BGR5552RGBA =29,

	    CV_GRAY2BGR555 =30,
	    CV_BGR5552GRAY =31,

	    CV_BGR2XYZ     =32,
	    CV_RGB2XYZ     =33,
	    CV_XYZ2BGR     =34,
	    CV_XYZ2RGB     =35,

	    CV_BGR2YCrCb   =36,
	    CV_RGB2YCrCb   =37,
	    CV_YCrCb2BGR   =38,
	    CV_YCrCb2RGB   =39,

	    CV_BGR2HSV     =40,
	    CV_RGB2HSV     =41,

	    CV_BGR2Lab     =44,
	    CV_RGB2Lab     =45,

	    CV_BayerBG2BGR =46,
	    CV_BayerGB2BGR =47,
	    CV_BayerRG2BGR =48,
	    CV_BayerGR2BGR =49,

	    CV_BayerBG2RGB =CV_BayerRG2BGR,
	    CV_BayerGB2RGB =CV_BayerGR2BGR,
	    CV_BayerRG2RGB =CV_BayerBG2BGR,
	    CV_BayerGR2RGB =CV_BayerGB2BGR,

	    CV_BGR2Luv     =50,
	    CV_RGB2Luv     =51,
	    CV_BGR2HLS     =52,
	    CV_RGB2HLS     =53,

	    CV_HSV2BGR     =54,
	    CV_HSV2RGB     =55,

	    CV_Lab2BGR     =56,
	    CV_Lab2RGB     =57,
	    CV_Luv2BGR     =58,
	    CV_Luv2RGB     =59,
	    CV_HLS2BGR     =60,
	    CV_HLS2RGB     =61,

	    CV_BayerBG2BGR_VNG =62,
	    CV_BayerGB2BGR_VNG =63,
	    CV_BayerRG2BGR_VNG =64,
	    CV_BayerGR2BGR_VNG =65,

	    CV_BayerBG2RGB_VNG =CV_BayerRG2BGR_VNG,
	    CV_BayerGB2RGB_VNG =CV_BayerGR2BGR_VNG,
	    CV_BayerRG2RGB_VNG =CV_BayerBG2BGR_VNG,
	    CV_BayerGR2RGB_VNG =CV_BayerGB2BGR_VNG,

	    CV_BGR2HSV_FULL = 66,
	    CV_RGB2HSV_FULL = 67,
	    CV_BGR2HLS_FULL = 68,
	    CV_RGB2HLS_FULL = 69,

	    CV_HSV2BGR_FULL = 70,
	    CV_HSV2RGB_FULL = 71,
	    CV_HLS2BGR_FULL = 72,
	    CV_HLS2RGB_FULL = 73,

	    CV_LBGR2Lab     = 74,
	    CV_LRGB2Lab     = 75,
	    CV_LBGR2Luv     = 76,
	    CV_LRGB2Luv     = 77,

	    CV_Lab2LBGR     = 78,
	    CV_Lab2LRGB     = 79,
	    CV_Luv2LBGR     = 80,
	    CV_Luv2LRGB     = 81,

	    CV_BGR2YUV      = 82,
	    CV_RGB2YUV      = 83,
	    CV_YUV2BGR      = 84,
	    CV_YUV2RGB      = 85,

	    CV_BayerBG2GRAY = 86,
	    CV_BayerGB2GRAY = 87,
	    CV_BayerRG2GRAY = 88,
	    CV_BayerGR2GRAY = 89,

	    //YUV 4:2:0 formats family
	    CV_YUV2RGB_NV12 = 90,
	    CV_YUV2BGR_NV12 = 91,
	    CV_YUV2RGB_NV21 = 92,
	    CV_YUV2BGR_NV21 = 93,
	    CV_YUV420sp2RGB = CV_YUV2RGB_NV21,
	    CV_YUV420sp2BGR = CV_YUV2BGR_NV21,

	    CV_YUV2RGBA_NV12 = 94,
	    CV_YUV2BGRA_NV12 = 95,
	    CV_YUV2RGBA_NV21 = 96,
	    CV_YUV2BGRA_NV21 = 97,
	    CV_YUV420sp2RGBA = CV_YUV2RGBA_NV21,
	    CV_YUV420sp2BGRA = CV_YUV2BGRA_NV21,

	    CV_YUV2RGB_YV12 = 98,
	    CV_YUV2BGR_YV12 = 99,
	    CV_YUV2RGB_IYUV = 100,
	    CV_YUV2BGR_IYUV = 101,
	    CV_YUV2RGB_I420 = CV_YUV2RGB_IYUV,
	    CV_YUV2BGR_I420 = CV_YUV2BGR_IYUV,
	    CV_YUV420p2RGB = CV_YUV2RGB_YV12,
	    CV_YUV420p2BGR = CV_YUV2BGR_YV12,

	    CV_YUV2RGBA_YV12 = 102,
	    CV_YUV2BGRA_YV12 = 103,
	    CV_YUV2RGBA_IYUV = 104,
	    CV_YUV2BGRA_IYUV = 105,
	    CV_YUV2RGBA_I420 = CV_YUV2RGBA_IYUV,
	    CV_YUV2BGRA_I420 = CV_YUV2BGRA_IYUV,
	    CV_YUV420p2RGBA = CV_YUV2RGBA_YV12,
	    CV_YUV420p2BGRA = CV_YUV2BGRA_YV12,

	    CV_YUV2GRAY_420 = 106,
	    CV_YUV2GRAY_NV21 = CV_YUV2GRAY_420,
	    CV_YUV2GRAY_NV12 = CV_YUV2GRAY_420,
	    CV_YUV2GRAY_YV12 = CV_YUV2GRAY_420,
	    CV_YUV2GRAY_IYUV = CV_YUV2GRAY_420,
	    CV_YUV2GRAY_I420 = CV_YUV2GRAY_420,
	    CV_YUV420sp2GRAY = CV_YUV2GRAY_420,
	    CV_YUV420p2GRAY = CV_YUV2GRAY_420,

	    //YUV 4:2:2 formats family
	    CV_YUV2RGB_UYVY = 107,
	    CV_YUV2BGR_UYVY = 108,
	    //CV_YUV2RGB_VYUY = 109,
	    //CV_YUV2BGR_VYUY = 110,
	    CV_YUV2RGB_Y422 = CV_YUV2RGB_UYVY,
	    CV_YUV2BGR_Y422 = CV_YUV2BGR_UYVY,
	    CV_YUV2RGB_UYNV = CV_YUV2RGB_UYVY,
	    CV_YUV2BGR_UYNV = CV_YUV2BGR_UYVY,

	    CV_YUV2RGBA_UYVY = 111,
	    CV_YUV2BGRA_UYVY = 112,
	    //CV_YUV2RGBA_VYUY = 113,
	    //CV_YUV2BGRA_VYUY = 114,
	    CV_YUV2RGBA_Y422 = CV_YUV2RGBA_UYVY,
	    CV_YUV2BGRA_Y422 = CV_YUV2BGRA_UYVY,
	    CV_YUV2RGBA_UYNV = CV_YUV2RGBA_UYVY,
	    CV_YUV2BGRA_UYNV = CV_YUV2BGRA_UYVY,

	    CV_YUV2RGB_YUY2 = 115,
	    CV_YUV2BGR_YUY2 = 116,
	    CV_YUV2RGB_YVYU = 117,
	    CV_YUV2BGR_YVYU = 118,
	    CV_YUV2RGB_YUYV = CV_YUV2RGB_YUY2,
	    CV_YUV2BGR_YUYV = CV_YUV2BGR_YUY2,
	    CV_YUV2RGB_YUNV = CV_YUV2RGB_YUY2,
	    CV_YUV2BGR_YUNV = CV_YUV2BGR_YUY2,

	    CV_YUV2RGBA_YUY2 = 119,
	    CV_YUV2BGRA_YUY2 = 120,
	    CV_YUV2RGBA_YVYU = 121,
	    CV_YUV2BGRA_YVYU = 122,
	    CV_YUV2RGBA_YUYV = CV_YUV2RGBA_YUY2,
	    CV_YUV2BGRA_YUYV = CV_YUV2BGRA_YUY2,
	    CV_YUV2RGBA_YUNV = CV_YUV2RGBA_YUY2,
	    CV_YUV2BGRA_YUNV = CV_YUV2BGRA_YUY2,

	    CV_YUV2GRAY_UYVY = 123,
	    CV_YUV2GRAY_YUY2 = 124,
	    //CV_YUV2GRAY_VYUY = CV_YUV2GRAY_UYVY,
	    CV_YUV2GRAY_Y422 = CV_YUV2GRAY_UYVY,
	    CV_YUV2GRAY_UYNV = CV_YUV2GRAY_UYVY,
	    CV_YUV2GRAY_YVYU = CV_YUV2GRAY_YUY2,
	    CV_YUV2GRAY_YUYV = CV_YUV2GRAY_YUY2,
	    CV_YUV2GRAY_YUNV = CV_YUV2GRAY_YUY2,

	    // alpha premultiplication
	    CV_RGBA2mRGBA = 125,
	    CV_mRGBA2RGBA = 126,

	    CV_RGB2YUV_I420 = 127,
	    CV_BGR2YUV_I420 = 128,
	    CV_RGB2YUV_IYUV = CV_RGB2YUV_I420,
	    CV_BGR2YUV_IYUV = CV_BGR2YUV_I420,

	    CV_RGBA2YUV_I420 = 129,
	    CV_BGRA2YUV_I420 = 130,
	    CV_RGBA2YUV_IYUV = CV_RGBA2YUV_I420,
	    CV_BGRA2YUV_IYUV = CV_BGRA2YUV_I420,
	    CV_RGB2YUV_YV12  = 131,
	    CV_BGR2YUV_YV12  = 132,
	    CV_RGBA2YUV_YV12 = 133,
	    CV_BGRA2YUV_YV12 = 134,

	    CV_COLORCVT_MAX  = 135
	};

	
	/*--------------------------------------------------------------------------------------*/
	/*											                                            */
	/*											Functions                                   */
	/*                                                                                      */
	/*--------------------------------------------------------------------------------------*/
	
	int sprintf(char *str, const char *format, ...);
	
	CvMat* cvCreateMat(int rows, int cols, int type);
	
	IplImage* cvLoadImage( const char* filename, int iscolor);
	CvMat* cvLoadImageM( const char* filename, int iscolor);
	int cvSaveImage(const char* filename, const CvArr* image, const int* params);

	void cvEllipse(	CvArr* img, 
					CvPoint center, 
					CvSize axes, 
					double angle, 
					double start_angle, 
					double end_angle, 
					CvScalar color, 
					int thickness, 
					int line_type, 
					int shift);
	
	void cvRectangle(CvArr* img, 
					 CvPoint pt1, 
					 CvPoint pt2, 
					 CvScalar color, 
					 int thickness, 
					 int line_type, 
					 int shift);
						
	void cvLine(CvArr* img, 
				CvPoint pt1, 
				CvPoint pt2, 
				CvScalar color, 
				int thickness, 
				int line_type, 
				int shift);
	
	void cvReleaseImage(IplImage** image);
	void cvReleaseMat(CvMat** mat);
	void cvCopy(const CvArr* src, CvArr* dst, const CvArr* mask);
	void cvSetImageROI(IplImage* image, CvRect rect);
	void cvSetZero(CvArr* arr);
	IplImage* cvCreateImage(CvSize size, int depth, int channels);
	void cvResetImageROI( IplImage* image );
	IplImage* cvCloneImage(const IplImage* image);
	
	/* Renders text stroke with specified font and color at specified location.
	   CvFont should be initialized with cvInitFont */
	void cvPutText( CvArr* img, const char* text, CvPoint org,
	                const CvFont* font, CvScalar color );
	
	/* Initializes font structure used further in cvPutText */
	void cvInitFont( CvFont* font, int font_face,
	                 double hscale, double vscale,
	                 double shear,
	                 int thickness,
	                 int line_type);
	
	/* Resizes image (input array is resized to fit the destination array) */
	void cvResize(const CvArr* src, CvArr* dst, int interpolation);
	
	/* dst = src1 * alpha + src2 * beta + gamma */
	void cvAddWeighted( const CvArr* src1, double alpha,
	                    const CvArr* src2, double beta,
	                    double gamma, CvArr* dst );
	
	/* Mirror array data around horizontal (flip=0),
	   vertical (flip=1) or both(flip=-1) axises:
	   cvFlip(src) flips images vertically and sequences horizontally (inplace) */
	void cvFlip(const CvArr* src, CvArr* dst, int flip_mode);
	
	void* cvLoad( const char* filename,
	              CvMemStorage* memstorage,
	              const char* name,
	              const char** real_name );
	
	void cvCvtColor( const CvArr* src, CvArr* dst, int code );
	
	void cvEqualizeHist( const CvArr* src, CvArr* dst );
	
	CvMemStorage* cvCreateMemStorage( int block_size );
	
	void cvReleaseMemStorage( CvMemStorage** storage );
	
	schar* cvGetSeqElem( const CvSeq* seq, int index );
	
	//CvRect* cvGetSeqElem( const CvSeq* seq, int index );
	
	CvSeq* cvHaarDetectObjects(const CvArr* image,
	                     		  void* cascade, 
								  CvMemStorage* storage,
	                     		  double scale_factor,
	                     		  int min_neighbors, 
								  int flags,
	                     		  CvSize min_size, 
								  CvSize max_size);
								
	/* Sets all or "masked" elements of input array to the same value */
	void cvSet(CvArr* arr, CvScalar value, const CvArr* mask);
	
	/* dst(idx) = src1(idx) & src2(idx) */
	void cvAnd( const CvArr* src1, const CvArr* src2, CvArr* dst, const CvArr* mask);
	
	/* dst(idx) = ~src(idx) */
	void cvNot( const CvArr* src, CvArr* dst );
	
	/* dst(idx) = src1(idx) | src2(idx) */
	void cvOr( const CvArr* src1, const CvArr* src2, CvArr* dst, const CvArr* mask);
	
	/* Splits a multi-channel array into the set of single-channel arrays or
	   extracts particular [color] plane */
	void  cvSplit( const CvArr* src, CvArr* dst0, CvArr* dst1, CvArr* dst2, CvArr* dst3 );
	
	/* Merges a set of single-channel arrays into the single multi-channel array
	   or inserts one particular [color] plane to the array */
	void  cvMerge( const CvArr* src0, const CvArr* src1, const CvArr* src2, const CvArr* src3, CvArr* dst );
	
	/* dst(idx) = src(idx) & value */
	void cvAndS( const CvArr* src, CvScalar value, CvArr* dst, const CvArr* mask);
	
	/* Retrieves image ROI */
	CvRect cvGetImageROI( const IplImage* image );

]]
 
local _M = {
	_VERSION = '0.1.0',
}

local mt = { __index = _M }

function _M.CV(self, cv_image)
	return setmetatable({ cv_image = cv_image }, mt)
end

local image_depth = {
	["IPL_DEPTH_8U"] = 8,
	["IPL_DEPTH_8S"] = 0x80000008,
	["IPL_DEPTH_16S"] = 0x80000010,
	["IPL_DEPTH_32S"] = 0x80000020,
	["IPL_DEPTH_32F"] = 32,
	["IPL_DEPTH_64F"] = 64,
	["UndefinedPixel"] = 0,
}


local iscolor_op = {
	['UNCHANGED'] = -1, --[[8bit, color or not]]
	['GRAYSCALE'] = 0,	--[[8bit, gray ]]
	['COLOR'] = 1,		--[[?, color]]
	['ANYDEPTH'] = 2,	--[[]ny depth, ?]]
	['ANYCOLOR'] = 4,	--[[?, any color]]
}

--[[
For JPEG, it can be a quality ( CV_IMWRITE_JPEG_QUALITY ) from 0 to 100 (the higher is the better). Default value is 95.
For WEBP, it can be a quality ( CV_IMWRITE_WEBP_QUALITY ) from 1 to 100 (the higher is the better). By default (without any parameter) and for quality above 100 the lossless compression is used.
For PNG, it can be the compression level ( CV_IMWRITE_PNG_COMPRESSION ) from 0 to 9. A higher value means a smaller size and longer compression time. Default value is 3.
For PPM, PGM, or PBM, it can be a binary format flag ( CV_IMWRITE_PXM_BINARY ), 0 or 1. Default value is 1.
]]
local save_op = {
	['JPEG_QUALITY'] = 1, 		-- 0, 100
	['PNG_COMPRESSION'] = 16,		-- 0, 9
	['WEBP_QUALITY'] = 64,		-- 1, 100
}

local line_type_op = {
	['CONNECTION_4'] = 4,
	['CONNECTION_8'] = 8,
	['CV_AA'] = 16,
}

local font_face_op = {
	["HERSHEY_SIMPLEX"] = 0,
	["HERSHEY_PLAIN"] = 1,
	["HERSHEY_DUPLEX"] = 2,
	["HERSHEY_COMPLEX"] = 3,
	["HERSHEY_TRIPLEX"] = 4,
	["HERSHEY_COMPLEX_SMALL"] = 5,
	["HERSHEY_SCRIPT_SIMPLEX"] = 6,
	["HERSHEY_SCRIPT_COMPLEX"] = 7,
	["ITALIC"] = 16,
}

local interpolation_op = {
	["INTER_NN"] = 0,
	["INTER_LINEAR"] = 1,
	["INTER_CUBIC"] = 2,
	["INTER_AREA"] = 3,
	["INTER_LANCZOS4"] = 4,
}

local flip_mode_op = {
	["V_FLIP"] = 0,
	["H_FLIP"] = 1,
	["VH_FLIP"] = -1,
}

local resize_mode_op = {
	["RESIZE_SCALE"] = 0, --default
	["RESIZE_FIT"] = 1,
	["RESIZE_MFIT"] = 2,
	["RESIZE_LIMIT"] = 3,
}

local fill_mode_op = {
	["FILL_DEFAULT"] = 0, --default
	["FILL_LIMIT"] = 1,
	["FILL_THUMB"] = 2,
}

local pad_mode_op = {
	["PAD_DEFAULT"] = 0, --default
	["PAD_LIMIT"] = 1,
	["PAD_M_LIMIT"] = 2,
}

local gravity_op = {
	["GRAVITY_CENTER"] = 0, --default
	["GRAVITY_NORTH_WEST"] = 1,
	["GRAVITY_NORTH"] = 2,
	["GRAVITY_NORTH_EAST"] = 3,
	["GRAVITY_WEST"] = 4,
	["GRAVITY_EAST"] = 5,
	["GRAVITY_SOUTH_WEST"] = 6,
	["GRAVITY_SOUTH"] = 7,
	["GRAVITY_SOUTH_EAST"] = 8,
	["GRAVITY_XY_CENTER"] = 9,
	["GRAVITY_FACE"] = 10,
	["GRAVITY_FACES"] = 11,
	["GRAVITY_FACE_CENTER"] = 12,
	["GRAVITY_FACES_CENTER"] = 13,
}

local function cv_rect(x, y, w, h)
	return ffi.new("CvRect", {
		x = x or 0,
		y = y or 0, 
		width = w or 0, 
		height = h or 0,
	})
end

local function cv_point(x, y)
	return ffi.new("CvPoint", {
		x = x or 0,
		y = y or 0,
	})
end

local function cv_scalar(r, g, b, a)
	r = r or 255
	g = g or 255
	b = b or 255
	a = a or 255
	return ffi.new("CvScalar", {
		val = {b, g, r, a}
	})
end

local cv_color = cv_scalar

local function cv_size(w, h)
	return ffi.new("CvSize", {
		width = w or 0,
		height = h or 0,
	})
end

local function cv_create_mat(rows, cols, type)
	rows = rows or 1
	cols = cols or 1
	type = type or 8
	return cvCore.cvCreateMat(rows, cols, type)
end

local function cv_release_mat(mat)
	local pointer = ffi.new("CvMat *[1]")
	pointer[0] = mat
	return cvCore.cvReleaseImage(pointer)
end

local function cv_create_image(w, h, depth, channels)
	return cvCore.cvCreateImage(cv_size(w, h), depth, channels)
end

local function cv_release_image(image)
	local pointer = ffi.new("IplImage *[1]")
	pointer[0] = image
	return cvCore.cvReleaseImage(pointer)
end

local function cv_copy(src, dst, mask)
	return cvCore.cvCopy(src, dst, mask)
end

local function cv_reset_image_roi(image)
	return cvHighgui.cvResetImageROI(image)
end

local function cv_set_zero(arr)
	return cvCore.cvSetZero(arr)
end

local function cv_clone_image(image)
	return cvCore.cvCloneImage(image)
end

local function cv_init_font(font_face, hscale, vscale, shear, thickness, line_type)
	if not font_face then
		font_face = "HERSHEY_SIMPLEX"
	end
	local font_face_val = font_face_op[font_face] or font_face_op["HERSHEY_SIMPLEX"]
	hscale = hscale or 1
	vscale = vscale or 1
	shear = shear or 0
	thickness = thickness or 1
	if not line_type then
		line_type = 'CONNECTION_8'
	end
	local line_type_val = line_type_op[line_type] or line_type_op['CONNECTION_8']
	local font = ffi.new("CvFont[1]")
	cvCore.cvInitFont(font, font_face_val, hscale, vscale, shear, thickness, line_type_val)
	return font
end

--[[ org & color should use function cv_point() & cv_scalar() ]]
local function cv_put_text(img, text, org, font, color)
	return cvCore.cvPutText(img, text, org, font, color)
end

local function cv_resize(src, dst, interpolation)
	if not interpolation then
		interpolation = "INTER_AREA"
	end
	local interpolation_val = interpolation_op[interpolation] or interpolation_op["INTER_AREA"]
	return cvImgproc.cvResize(src, dst, interpolation_val)
end

--[[ /* dst = src1 * alpha + src2 * beta + gamma */ ]]
local function cv_add_weighted(src1, alpha, src2, beta, gamma, dst)
	return cvCore.cvAddWeighted(src1, alpha, src2, beta, gamma, dst)
end

--[[ V_FLIP | H_FLIP | VH_FLIP ]]
local function cv_flip(src, dst, flip_mode)
	if not flip_mode then
		flip_mode = "V_FLIP"
	end
	local flip_mode_val = flip_mode_op[flip_mode] or flip_mode_op["V_FLIP"]
	return cvFlip(src, dst, flip_mode_val)
end

--[[ default: memstorage(nil), name(nil), real_name(nil) ]]
local function cv_load(filename, memstorage, name, real_name)
	return cvCore.cvLoad(filename, memstorage, name, real_name)
end

local function cv_cvt_color(src, dst, code)
	return cvImgproc.cvCvtColor(src, dst, code)
end

local function cv_equalize_hist(src, dst)
	return cvImgproc.cvEqualizeHist(src, dst);
end

local function cv_create_mem_storage(block_size)
	block_size = block_size or 0
	return cvCore.cvCreateMemStorage(block_size)
end

local function cv_and(src1, src2, dst, mask)
	return cvCore.cvAnd(src1, src2, dst, mask)
end

local function cv_and(src1, src2, dst, mask)
	return cvCore.cvAnd(src1, src2, dst, mask)
end
	
local function cv_and_s(src, value, dst, mask)
	return cvCore.cvAndS(src, value, dst, mask)
end	

local function cv_or(src1, src2, dst, mask)
	return cvCore.cvOr(src1, src2, dst, mask)
end

local function cv_not(src, dst)
	return cvCore.cvNot(src, dst)
end

local function cv_split(src, dst0, dst1, dst2, dst3)
	return cvCore.cvSplit(src, dst0, dst1, dst2, dst3)
end

local function cv_merge(src0, src1, src2, src3, dst)
	return cvCore.cvMerge(src0, src1, src2, src3, dst)
end

--[[
flags 或运算
#define CV_HAAR_DO_CANNY_PRUNING    1
#define CV_HAAR_SCALE_IMAGE         2
#define CV_HAAR_FIND_BIGGEST_OBJECT 4
#define CV_HAAR_DO_ROUGH_SEARCH     8
]]
local function cv_haar_detect_objects(image, cascade, storage, scale_factor, min_neighbors, flags, min_size, max_size)
	scale_factor = scale_factor or 1.1
	min_neighbors = min_neighbors or 3
	flags = flags or 0
	min_size = min_size or cv_size(0, 0)
	max_size = max_size or cv_size(0, 0)
	return cvObjdetect.cvHaarDetectObjects(image, cascade, storage, scale_factor, min_neighbors, flags, min_size, max_size)
end

local function cv_get_seq_elem(seq, index)
	return cvCore.cvGetSeqElem(seq, index)
end

local function cv_release_mem_storage(storage)
	local pointer = ffi.new("CvMemStorage *[1]")
	pointer[0] = storage
	return cvCore.cvReleaseMemStorage(pointer);
end

--[[ Sets all or "masked" elements of input array to the same value ]]
-- mask default nil
local function cv_set(arr, value, mask)
	return cvCore.cvSet(arr, value, mask)
end

local function cv_get_image_roi(image)
	return cvCore.cvGetImageROI(image)
end


local FaceCascade
local FaceStorageCascade = cv_create_mem_storage(0)

local function cv_object_detect(image, casc, find_biggest_object)

	local storage_cascade
	local cascade

	if casc == 'frontalface' then
		if not FaceCascade then
			FaceCascade = cv_load('src/lib/data/haarcascades/haarcascade_frontalface_alt2.xml', FaceStorageCascade)
		end
		cascade = FaceCascade
	else
		storage_cascade = cv_create_mem_storage(0)
		cascade = cv_load(casc, storage_cascade)
	end

	if not cascade then
		return error("ErrorInternal", 2)
	end
	local gray = cv_create_image(image.width, image.height, 8, 1)
	cv_cvt_color(image, gray, ffi.C.CV_BGR2GRAY)
	cv_equalize_hist(gray, gray)
	local storage = cv_create_mem_storage(0)
	local flags = 3
	if find_biggest_object then
		flags = 15
	end
	local faces = cv_haar_detect_objects(gray, cascade, storage, 1.06, 3, flags, cv_size(image.width / 100, image.height / 100), cv_size(0, 0))
	local rects = {}
	local x_min, y_min, x_max, y_max, idx_x_max, idx_y_max
	if faces and faces.total > 0 then
		
		local i
		for i=0, (faces.total - 1) do
			local rect = cv_get_seq_elem(faces, i)
			rect = ffi.cast("CvRect *", rect)
			if (not x_min) or (x_min > rect.x) then
				x_min = rect.x
			end
			if (not y_min) or (y_min > rect.y) then
				y_min = rect.y
			end
			if (not x_max) or (x_max < rect.x) then
				x_max = rect.x
				idx_x_max = i + 1
			end
			if (not y_max) or (y_max < rect.y) then
				y_max = rect.y
				idx_y_max = i + 1
			end
			local final_rect = cv_rect(
				rect.x,
				rect.y,
				rect.width,
				rect.height
			)
			table.insert(rects, final_rect)
		end
	end

	if storage_cascade then
		cv_release_mem_storage(storage_cascade)
	end
	cv_release_mem_storage(storage)
	cv_release_image(gray)
	local group_rect
	if #rects > 0 then
		local g_x, g_y = x_min, y_min
		local g_w = x_max - x_min + rects[idx_x_max].width
		local g_h = y_max - y_min + rects[idx_y_max].height
		group_rect = cv_rect(g_x, g_y, g_w, g_h)
	end
	return rects, group_rect
end

local function cv_center_of_gravity(image, gravity_mode)

	local x, y
	local faces_rect = nil
	local faces_num = nil
	
	if gravity_mode == 'GRAVITY_CENTER' then
		x = image.width / 2
		y = image.height / 2
	elseif gravity_mode == 'GRAVITY_NORTH_WEST' then
		x = 0
		y = 0
	elseif gravity_mode == 'GRAVITY_NORTH' then
		x = image.width / 2
		y = 0
	elseif gravity_mode == 'GRAVITY_NORTH_EAST' then
		x = image.width
		y = 0
	elseif gravity_mode == 'GRAVITY_WEST' then
		x = 0
		y = image.height / 2
	elseif gravity_mode == 'GRAVITY_EAST' then
		x = image.width
		y = image.height / 2
	elseif gravity_mode == 'GRAVITY_SOUTH_WEST' then
		x = 0
		y = image.height
	elseif gravity_mode == 'GRAVITY_SOUTH' then
		x = image.width / 2
		y = image.height
	elseif gravity_mode == 'GRAVITY_SOUTH_EAST' then
		x = image.width
		y = image.height
	elseif gravity_mode == 'GRAVITY_FACE' or gravity_mode == 'GRAVITY_FACE_CENTER' then
		
		local faces, group_rect = cv_object_detect(image, 'frontalface', 1)
		if #faces > 0 then
			x = faces[1].x + faces[1].width / 2
			y = faces[1].y + faces[1].height / 2
			faces_rect = group_rect
			faces_num = #faces
		else
			x = image.width / 2
			y = (gravity_mode == 'GRAVITY_FACE') and 0 or image.height / 2
		end
		
	elseif gravity_mode == 'GRAVITY_FACES' or gravity_mode == 'GRAVITY_FACES_CENTER' then
		
		local faces, group_rect = cv_object_detect(image, 'frontalface')
		if #faces > 0 then
			x = group_rect.x + group_rect.width / 2
			y = group_rect.y + group_rect.height / 2
			faces_rect = group_rect
			faces_num = #faces
		else
			x = image.width / 2
			y = (gravity_mode == 'GRAVITY_FACES') and 0 or image.height / 2
		end
	end
	return x, y, faces_rect, faces_num
end

local function cv_coord_gravity_to_image(image, x, y, gravity_mode, w, h)

	x = x or 0
	y = y or 0
	gravity_mode = gravity_mode or 'GRAVITY_NORTH_WEST'
	w = w or 0
	h = h or 0
	
	local ox, oy, face_rect, ix, iy
	ox, oy, face_rect= cv_center_of_gravity(image, gravity_mode)
	
	if not (face_rect == nil) then
		ix = ox + x - w / 2
		iy = oy + y - h / 2
	else
		if ox == image.width then 
			ix = ox - x - w
		elseif ox == 0 then
			ix = ox + x
		else
			ix = ox + x - w / 2
		end
		
		
		if oy == image.height then 
			iy = oy - y - h
		elseif oy == 0 then
			iy = oy + y
		else
			iy = oy + y - h / 2
		end
	end
	
	return ix, iy
end

local function cv_set_image_roi(image, x, y, w, h)
	if not image then
		return error("ErrorFile", 2)
	else
		local rect = cv_rect(x, y, w, h)
		return cvHighgui.cvSetImageROI(image, rect)
	end
end

--[[ +++++++++++++++++++++++++++++++++++++++++++++++ ]]

_M.ERROR_MESSAGE = {
	
	['ErrorSave'] = 'Failed to save image',
	['ErrorFile'] = 'File does not exist',
	['ErrorInternal'] = 'Error in the internal service',
	['ErrorGravity'] = 'Operation does not support the gravity_mode'
}

function _M.load_image(filename, iscolor)
	if not iscolor then
		iscolor = 'UNCHANGED' 
	end
	local iscolor_val = iscolor_op[iscolor] or iscolor_op['UNCHANGED']
	local cv_image = cvHighgui.cvLoadImage(filename, iscolor_val)
	return _M:CV(cv_image)
end

function _M.create_image(w, h, depth, channels)
	local cv_image = cv_create_image(w, h, depth, channels)
	return _M:CV(cv_image)
end

function _M.get_image_data(self)
	return self.cv_image.imageData
	--return self.cv_image.imageDataOrigin
end

function _M.clone_image(self)
	return _M:CV(cv_clone_image(self.cv_image))
end

function _M.save_image(self, filename, opt)
	local opt_val = nil
	if opt then
		if opt['JPEG_QUALITY'] and tonumber(opt['JPEG_QUALITY']) and tonumber(opt['JPEG_QUALITY']) >= 0 and tonumber(opt['JPEG_QUALITY']) <= 100 then
			opt_val = ffi.new("int[3]", {save_op['JPEG_QUALITY'], opt['JPEG_QUALITY'], 0})
		elseif opt['PNG_COMPRESSION'] and tonumber(opt['PNG_COMPRESSION']) and tonumber(opt['PNG_COMPRESSION']) >= 0 and tonumber(opt['PNG_COMPRESSION']) <= 9  then
			opt_val = ffi.new("int[3]", {save_op['PNG_COMPRESSION'], opt['PNG_COMPRESSION'], 0})
		elseif opt['WEBP_QUALITY'] and tonumber(opt['WEBP_QUALITY']) and tonumber(opt['WEBP_QUALITY']) >= 1 and tonumber(opt['WEBP_QUALITY']) <= 100 then
			opt_val = ffi.new("int[3]", {save_op['WEBP_QUALITY'], opt['WEBP_QUALITY'], 0})
		end
	end
	if 1 == cvHighgui.cvSaveImage(filename, self.cv_image, opt_val) then
		return true
	else
		return error("ErrorSave", 2)
	end
end

function _M.get_size(self)
	if not self.cv_image then
		return 0, 0
	else
		return self.cv_image.width, self.cv_image.height
	end
end

function _M.set_image_roi(self, x, y, w, h)
	return cv_set_image_roi(self.cv_image, x, y, w, h)
end

function _M.line(self, x1, y1, x2, y2, scalar, thickness, line_type, shift)

	if not self.cv_image then
		return error("ErrorFile", 2)
	else
		local point1 = cv_point(x1, y1)
		local point2 = cv_point(x2, y2)
		
		local color
		if scalar then
			color = cv_scalar(scalar[1], scalar[2], scalar[3], scalar[4])
		else
			color = cv_scalar(255, 255, 255, 255)
		end
		
		if not thickness then
			thickness = 1
		end
		
		if not line_type then
			line_type = 'CONNECTION_8'
		end
		
		local line_type_val = line_type_op[line_type] or line_type_op['CONNECTION_8']
		
		if not shift then
			shift = 0 
		end
		
		return cvHighgui.cvLine(self.cv_image, point1, point2, color, thickness, line_type_val, shift)
	end
end

function _M.release_image(self)
	cv_release_image(self.cv_image)
	self.cv_image = nil
end
					
function _M.rectangle(self, x1, y1, x2, y2, scalar, thickness, line_type, shift)

	if not self.cv_image then
		return error("ErrorFile", 2)
	else
		local point1 = cv_point(x1, y1)
		local point2 = cv_point(x2, y2)
		
		local color
		if scalar then
			color = cv_scalar(scalar[1], scalar[2], scalar[3], scalar[4])
		else
			color = cv_scalar(255, 255, 255, 255)
		end
		
		if not thickness then
			thickness = 1
		end
		
		if not line_type then
			line_type = 'CONNECTION_8'
		end
		
		local line_type_val = line_type_op[line_type] or line_type_op['CONNECTION_8']
		
		if not shift then
			shift = 0 
		end
		
		return cvHighgui.cvRectangle(self.cv_image, point1, point2, color, thickness, line_type_val, shift)
	end
end

function _M.ellipse(self, x, y, w, h, angle, start_angle, end_angle, scalar, thickness, line_type, shift)

	if not self.cv_image then
		return error("ErrorFile", 2)
	else
		local point = cv_point(x, y)
		local size = cv_size(w, h)
		
		if not angle then
			angle = 360
		end
		
		if not start_angle then
			start_angle = 0
		end
		
		if not end_angle then
			end_angle = 360
		end
		
		local color
		if scalar then
			color = cv_scalar(scalar[1], scalar[2], scalar[3], scalar[4])
		else
			color = cv_scalar(255, 255, 255, 255)
		end
		
		if not thickness then
			thickness = 1
		end
		
		if not line_type then
			line_type = 'CONNECTION_8'
		end
		
		local line_type_val = line_type_op[line_type] or line_type_op['CONNECTION_8']
		
		if not shift then
			shift = 0 
		end
		
		return cvHighgui.cvEllipse(self.cv_image, point, size, angle, start_angle, end_angle, color, thickness, line_type_val, shift)
	end
end


function _M.object_detect(self, casc, find_biggest_object)
	return cv_object_detect(self.cv_image, casc, find_biggest_object)
end

function _M.resize(self, w, h, mode, interpolation)
	
	if not self.cv_image then
		return error("ErrorFile", 2)
	else
		local roi_rect = cv_get_image_roi(self.cv_image)
		local o_w = roi_rect.width
		local o_h = roi_rect.height
		
		w = w or 0
		h = h or 0
		
		local n_w, n_h
		
		if w <= 0 then
			if h <= 0 then
				n_w = o_w
				n_h = o_h
			else
				n_h = h
				n_w = o_w*n_h/o_h
			end
		else
			if h <= 0 then
				n_w = w
				n_h = n_w*o_h/o_w
			else
				n_w = w
				n_h = h
			end
		end

		
		if not mode then
			mode = 'RESIZE_SCALE'
		end
				
		
		if not (n_w == o_w and n_h == o_h) then
			
			if mode == 'RESIZE_SCALE' then
				
			elseif mode == 'RESIZE_FIT' then
				
				if o_w/o_h > n_w/n_h then
					n_h = n_w*o_h/o_w
				else
					n_w = o_w*n_h/o_h
				end
				
			elseif mode == 'RESIZE_MFIT' then
				
				if o_w/o_h > n_w/n_h then
					if n_w < o_w then n_w = o_w end
					n_h = n_w*o_h/o_w
				else
					if n_h < o_h then n_h = o_h end
					n_w = o_w*n_h/o_h
				end
				
			elseif mode == 'RESIZE_LIMIT' then
				
				if o_w/o_h > n_w/n_h then
					if n_w > o_w then n_w = o_w end
					n_h = n_w*o_h/o_w
				else
					if n_h > o_h then n_h = o_h end
					n_w = o_w*n_h/o_h
				end
				
			end
		end
		
		local dst = cv_create_image(n_w, n_h, self.cv_image.depth, self.cv_image.nChannels)
		cv_resize(self.cv_image, dst, interpolation)
		cv_release_image(self.cv_image)
		self.cv_image = dst
	end
	return
end


function _M.fill(self, w, h, fill_mode, gravity_mode)

	if not self.cv_image then
		return error("ErrorFile", 2)
	else
		local roi_rect = cv_get_image_roi(self.cv_image)
		local o_w = roi_rect.width
		local o_h = roi_rect.height
		
		w = w or 0
		h = h or 0
		
		local n_w, n_h
		
		if w <= 0 then
			if h <= 0 then
				n_w = o_w
				n_h = o_h
			else
				n_h = h
				n_w = o_w*n_h/o_h
			end
		else
			if h <= 0 then
				n_w = w
				n_h = n_w*o_h/o_w
			else
				n_w = w
				n_h = h
			end
		end
		
		if not fill_mode then
			fill_mode = 'FILL_DEFAULT'
		end
		
		if not gravity_mode then
			gravity_mode = 'GRAVITY_NORTH'
		end
		
		if gravity_mode == 'GRAVITY_XY_CENTER' then
			gravity_mode = 'GRAVITY_NORTH'
		end
		
		if fill_mode == 'FILL_THUMB' then
			if (gravity_mode == 'GRAVITY_FACE' or gravity_mode == 'GRAVITY_FACE_CENTER' or gravity_mode == 'GRAVITY_FACES' or gravity_mode == 'GRAVITY_FACES_CENTER') then
				return self:thumb(w, h, gravity_mode)
			end
			fill_mode = 'FILL_DEFAULT'
		end
		
		if fill_mode == 'FILL_DEFAULT' then
		elseif fill_mode == 'FILL_LIMIT' then
			n_w = (n_w > o_w) and o_w or n_w
			n_h = (n_h > o_h) and o_h or n_h
		end
		
		local h_roi, w_roi, x_roi, y_roi, faces_rect
		x_roi, y_roi, faces_rect = cv_center_of_gravity(self.cv_image, gravity_mode)

		if faces_rect == nil then
			faces_rect = cv_rect(0, 0, o_w, o_h)
		end
		
		if n_w/n_h >= o_w/o_h then
			--w_roi = o_w - (o_w/2 - faces_rect.width/2)
			w_roi = o_w
			h_roi = n_h*w_roi/n_w
			x_roi = 0
			if y_roi == 0 then
			elseif (y_roi == o_h or y_roi + h_roi / 2 > o_h) then
				y_roi = o_h - h_roi
			else
				y_roi = y_roi - h_roi / 2 > 0 and y_roi - h_roi / 2 or 0
			end
		else
			--h_roi = o_h - (o_h/2 - faces_rect.height/2)
			h_roi = o_h
			w_roi = h_roi*n_w/n_h
			y_roi = 0
			
			if x_roi == 0 then
			elseif (x_roi == o_w or x_roi + w_roi / 2 > o_w) then
				x_roi = o_w - w_roi
			else
				x_roi = x_roi - w_roi / 2 > 0 and x_roi - w_roi / 2 or 0
			end
		end

		self:set_image_roi(x_roi, y_roi, w_roi, h_roi)
		self:resize(n_w, n_h, nil, 'INTER_AREA')
	end
	return
end

function _M.thumb(self, w, h, gravity_mode, face_area_rate)

	if not self.cv_image then
		return error("ErrorFile")
	else
		local roi_rect = cv_get_image_roi(self.cv_image)
		local o_w = roi_rect.width
		local o_h = roi_rect.height
		
		w = w or 0
		h = h or 0
		face_area_rate = tonumber(face_area_rate) or 1.5
		
		local n_w, n_h
		if w <= 0 then
			if h <= 0 then
				n_w = o_w
				n_h = o_h
			else
				n_h = h
				n_w = o_w*n_h/o_h
			end
		else
			if h <= 0 then
				n_w = w
				n_h = n_w*o_h/o_w
			else
				n_w = w
				n_h = h
			end
		end
		
		
		if not gravity_mode then
			gravity_mode = 'GRAVITY_FACE'
		end
		
		if not (gravity_mode == 'GRAVITY_FACE' or gravity_mode == 'GRAVITY_FACE_CENTER' or gravity_mode == 'GRAVITY_FACES' or gravity_mode == 'GRAVITY_FACES_CENTER') then
			return self:fill(n_w, n_h, nil, gravity_mode)
		end
		
		--要的大小大于原图，直接fill
		if (n_w > o_w or n_h > o_h) then
			return self:fill(n_w, n_h, nil, gravity_mode)
		else
			local h_roi, w_roi, x_roi, y_roi
			local faces_rect
			local faces_num
	
			x_roi, y_roi, faces_rect, faces_num = cv_center_of_gravity(self.cv_image, gravity_mode)
			--ngx.log(ngx.ALERT,string.format("~~~~~~ 1 ~~~~%f,%f,%f,%f,%d~~~~~",x_roi, y_roi, faces_rect.width, faces_rect.height,faces_num))
			if faces_rect == nil then
				if gravity_mode == 'GRAVITY_FACE_CENTER' or gravity_mode == 'GRAVITY_FACES_CENTER' then
					return self:fill(n_w, n_h, nil, 'GRAVITY_CENTER')
				else
					return self:fill(n_w, n_h, nil, 'GRAVITY_NORTH')
				end
			end

			if faces_num > 1 then
				face_area_rate = 1
			end

			--要的大小大于脸的rate倍，直接裁剪
			if (n_w >= faces_rect.width * face_area_rate and n_h >= faces_rect.height * face_area_rate) then
				h_roi = n_h
				w_roi = n_w
				
				if (x_roi - w_roi / 2) > 0 and (x_roi + w_roi/2) <= o_w then
					x_roi = (x_roi - w_roi / 2)
				elseif (x_roi - w_roi / 2) > 0 and (x_roi + w_roi/2) > o_w then
					x_roi = o_w - w_roi
				else
					x_roi = 0
				end
				
				if (y_roi - h_roi / 2) > 0 and (y_roi + h_roi/2) <= o_h then
					y_roi = (y_roi - h_roi / 2)
				elseif (y_roi - h_roi / 2) > 0 and (y_roi + h_roi/2) > o_h then
					y_roi = o_h - h_roi
				else
					y_roi = 0
				end
				
				self:set_image_roi(x_roi, y_roi, w_roi, h_roi)
				local dst = cv_create_image(w_roi, h_roi, self.cv_image.depth, self.cv_image.nChannels)
				cv_copy(self.cv_image, dst)
				cv_release_image(self.cv_image)
				self.cv_image = dst
			else
				--要的高大于脸的rate倍，宽小于脸的rate倍，先按宽取脸，若按比例计算后，高大于原图高，则按高反算宽，最后再缩放
				if (n_w < faces_rect.width * face_area_rate and n_h > faces_rect.height * face_area_rate) then

					w_roi = faces_rect.width * face_area_rate > o_w and o_w or faces_rect.width * face_area_rate
					h_roi = w_roi * n_h / n_w

					if h_roi > o_h then
						h_roi = o_h
						w_roi = n_w * h_roi / n_h
						x_roi = x_roi - w_roi/2 > 0 and (x_roi + w_roi/2 > o_w and o_w - w_roi or x_roi - w_roi/2) or 0
						y_roi = 0
					else
						x_roi = x_roi - w_roi/2 > 0 and (x_roi + w_roi/2 > o_w and o_w - w_roi or x_roi - w_roi/2) or 0
						y_roi = y_roi - h_roi/2 > 0 and (y_roi + h_roi/2 > o_h and o_h - h_roi or y_roi - h_roi/2) or 0
					end
					--ngx.log(ngx.ALERT,string.format("~~~~~~ 1 ~~~~%f,%f,%f,%f,%f,%f~~~~~",x_roi, y_roi, w_roi, h_roi, faces_rect.width, faces_rect.height))
					self:set_image_roi(x_roi, y_roi, w_roi, h_roi)
					self:resize(n_w, n_h, nil, 'INTER_AREA')

				--要的宽大于脸的rate倍，高小于脸的rate倍，先按高取脸，若按比例计算后，宽大于原图宽，则按宽反算高，最后再缩放
				elseif (n_w > faces_rect.width * face_area_rate and n_h < faces_rect.height * face_area_rate) then

					h_roi = faces_rect.height * face_area_rate > o_h and o_h or faces_rect.height * face_area_rate
					w_roi = n_w * h_roi / n_h

					if w_roi > o_w then
						w_roi = o_w
						h_roi = w_roi * n_h / n_w
						x_roi = 0
						y_roi = y_roi - h_roi/2 > 0 and (y_roi + h_roi/2 > o_h and o_h - h_roi or y_roi - h_roi/2) or 0
					else
						x_roi = x_roi - w_roi/2 > 0 and (x_roi + w_roi/2 > o_w and o_w - w_roi or x_roi - w_roi/2) or 0
						y_roi = y_roi - h_roi/2 > 0 and (y_roi + h_roi/2 > o_h and o_h - h_roi or y_roi - h_roi/2) or 0
					end

					--ngx.log(ngx.ALERT,string.format("~~~~~ 2 ~~~~%f,%f,%f,%f,%f,%f~~~~~",x_roi, y_roi, w_roi, h_roi, faces_rect.width, faces_rect.height))
					self:set_image_roi(x_roi, y_roi, w_roi, h_roi)
					self:resize(n_w, n_h, nil, 'INTER_AREA')

				--要的宽高都小于脸的rate倍，先取脸的宽高的较小值，再根据所要的比例，计算狂傲的值，最后缩放
				else
					w_roi = faces_rect.width * face_area_rate > o_w and o_w or faces_rect.width * face_area_rate
					h_roi = faces_rect.height * face_area_rate > o_h and o_h or faces_rect.height * face_area_rate

					if faces_num == 1 then
						w_roi = w_roi > h_roi and h_roi or w_roi
						h_roi = w_roi
					end

					if n_w/n_h >= w_roi/h_roi then
						h_roi = n_h * w_roi / n_w
					else
						w_roi = n_w * h_roi / n_h
					end
					--ngx.log(ngx.ALERT,string.format("~~~~~ 3 ~~~~%f,%f,%f,%f,%f,%f~~~~~",x_roi, y_roi, w_roi, h_roi, faces_rect.width, faces_rect.height))
					x_roi = x_roi - w_roi/2 > 0 and (x_roi + w_roi/2 > o_w and o_w - w_roi or x_roi - w_roi/2) or 0
					y_roi = y_roi - h_roi/2 > 0 and (y_roi + h_roi/2 > o_h and o_h - h_roi or y_roi - h_roi/2) or 0

					self:set_image_roi(x_roi, y_roi, w_roi, h_roi)
					--ngx.log(ngx.ALERT,string.format("~~~~~ 3‘ ~~~~%f,%f,%f,%f,%f,%f~~~~~",x_roi, y_roi, w_roi, h_roi, faces_rect.width, faces_rect.height))
					self:resize(n_w, n_h, nil, 'INTER_AREA')
				end
			end


			--[[ 此处为改前方式

			if (n_w < faces_rect.width or n_h < faces_rect.height) then
				
				--self:fill(n_w, n_h, nil, gravity_mode)
				
				if faces_rect == nil then
					faces_rect = cv_rect(0, 0, o_w, o_h)
				end
				
				if n_w/n_h >= o_w/o_h then

					w_roi = o_w - (o_w/2 - faces_rect.width/2)
					h_roi = n_h*w_roi/n_w
					
					--若脸在原图左侧，且位于roi区域的右侧（1/3）处，则x_roi要尽量取的靠右，以保证脸在roi区域的中间
					--反之同理
					if x_roi < o_w/2 then
						if x_roi/w_roi > 0.7 then
							x_roi = x_roi - faces_rect.width/2 > 0 and x_roi - faces_rect.width/2 or 0
						else
							x_roi = x_roi - faces_rect.width > 0 and x_roi - faces_rect.width or 0
						end
					else
						if (x_roi - (o_w/2 - faces_rect.width/2))/w_roi < 0.3 then
							x_roi = o_w/2 - faces_rect.width > 0 and o_w/2 - faces_rect.width or 0
						else
							x_roi = o_w/2 - faces_rect.width/2
						end
					end
					
					
					if y_roi == 0 then
					elseif (y_roi == o_h or y_roi + h_roi / 2 > o_h) then
						y_roi = o_h - h_roi
					else
						y_roi = y_roi - h_roi / 2 > 0 and y_roi - h_roi / 2 or 0
					end
				else
					h_roi = o_h - (o_h/2 - faces_rect.height/2)
					w_roi = h_roi*n_w/n_h
					
					if y_roi < o_h/2 then
						if y_roi/h_roi > 0.7 then
							y_roi = y_roi - faces_rect.height/2 > 0 and y_roi - faces_rect.height/2 or 0
						else
							y_roi = y_roi - faces_rect.height > 0 and y_roi - faces_rect.height or 0
						end
					else
						if (y_roi - (o_h/2 - faces_rect.height/2))/h_roi < 0.3 then
							y_roi = o_h/2 - faces_rect.height
						else
							y_roi = o_h/2 - faces_rect.height/2
						end
					end
					
					
					
					if x_roi == 0 then
					elseif (x_roi == o_w or x_roi + w_roi / 2 > o_w) then
						x_roi = o_w - w_roi
					else
						x_roi = x_roi - w_roi / 2 > 0 and x_roi - w_roi / 2 or 0
					end
				end

				self:set_image_roi(x_roi, y_roi, w_roi, h_roi)
				self:resize(n_w, n_h, nil, 'INTER_AREA')
			else
				h_roi = n_h
				w_roi = n_w
				
				if (x_roi - w_roi / 2) > 0 and (x_roi + w_roi/2) <= o_w then
					x_roi = (x_roi - w_roi / 2)
				elseif (x_roi - w_roi / 2) > 0 and (x_roi + w_roi/2) > o_w then
					x_roi = o_w - w_roi
				else
					x_roi = 0
				end
				
				if (y_roi - h_roi / 2) > 0 and (y_roi + h_roi/2) <= o_h then
					y_roi = (y_roi - h_roi / 2)
				elseif (y_roi - h_roi / 2) > 0 and (y_roi + h_roi/2) > o_h then
					y_roi = o_h - h_roi
				else
					y_roi = 0
				end
				--x_roi = (x_roi - w_roi / 2) > 0 and (x_roi - w_roi / 2) or 0
				--y_roi = (y_roi - h_roi / 2) > 0 and (y_roi - h_roi / 2) or 0
				self:set_image_roi(x_roi, y_roi, w_roi, h_roi)
				local dst = cv_create_image(w_roi, h_roi, self.cv_image.depth, self.cv_image.nChannels)
				cv_copy(self.cv_image, dst)
				cv_release_image(self.cv_image)
				self.cv_image = dst
			end

			--]]
		end
	end
	return
end


function _M.crop(self, x, y, w, h, gravity_mode)

	if not self.cv_image then
		return error("ErrorFile")
	else
		local roi_rect = cv_get_image_roi(self.cv_image)
		local o_w = roi_rect.width
		local o_h = roi_rect.height
		
		if not gravity_mode then
			gravity_mode = 'GRAVITY_NORTH'
		end
		
		local n_w, n_h
		
		if (w and w < 0) or (h and h < 0) then
			return
		end
		
		if (w or h) then
			w = w or 0
			h = h or 0
			
			if w <= 0 then
				if h <= 0 then
					n_w = o_w
					n_h = o_h
				else
					n_h = h
					n_w = o_w*n_h/o_h
				end
			else
				if h <= 0 then
					n_w = w
					n_h = n_w*o_h/o_w
				else
					n_w = w
					n_h = h
				end
			end
		end
		
		
		
		if (x or y) then
			
			x = x or 0
			y = y or 0
			
			if n_w == nil then
				return
			else
			
				if (x >= o_w or y >= o_h or x + n_w < 1 or y + n_h < 1) then
					
					x = 0
					y = 0
					n_w = 1
					n_h = 1
					
					self:set_image_roi(x, y, n_w, n_h)
					local rect = cv_get_image_roi(self.cv_image)
					local dst = cv_create_image(rect.width, rect.height, self.cv_image.depth, self.cv_image.nChannels)
					cv_copy(self.cv_image, dst)
					cv_release_image(self.cv_image)
					self.cv_image = dst
					
					return
				end
				
				if gravity_mode == 'GRAVITY_XY_CENTER' then
					x = x - n_w/2 > 0 and x - n_w/2 or 0
					y = y - n_h/2 > 0 and y - n_h/2 or 0
				else
					x = x < 0 and 0 or x
					y = y < 0 and 0 or y
				end
				
				self:set_image_roi(x, y, n_w, n_h)
				local rect = cv_get_image_roi(self.cv_image)
				local dst = cv_create_image(rect.width, rect.height, self.cv_image.depth, self.cv_image.nChannels)
				cv_copy(self.cv_image, dst)
				cv_release_image(self.cv_image)
				self.cv_image = dst
				
				return
			end
			
		else
		
			if n_w == nil then
				
				if (gravity_mode == 'GRAVITY_FACE' or gravity_mode == 'GRAVITY_FACE_CENTER' or gravity_mode == 'GRAVITY_FACES' or gravity_mode == 'GRAVITY_FACES_CENTER') then
					local h_roi, w_roi, x_roi, y_roi, faces_rect
					x_roi, y_roi, faces_rect = cv_center_of_gravity(self.cv_image, gravity_mode)
					
					if faces_rect == nil then
						return
					end
					
					w_roi = faces_rect.width * 1.3
					h_roi = w_roi/0.73
					
					self:set_image_roi(x_roi-w_roi/2, y_roi-h_roi/2, w_roi, h_roi)
					local rect = cv_get_image_roi(self.cv_image)
					local dst = cv_create_image(rect.width, rect.height, self.cv_image.depth, self.cv_image.nChannels)
					cv_copy(self.cv_image, dst)
					cv_release_image(self.cv_image)
					self.cv_image = dst
					return
				else
					return
				end
				
			else
				
				local x_roi, y_roi
				x_roi, y_roi = cv_center_of_gravity(self.cv_image, gravity_mode)
				
				if x_roi == 0 then x_roi = 0
				elseif x_roi == o_w then x_roi = x_roi - n_w
				else x_roi = x_roi - n_w/2
				end
				
				if y_roi == 0 then y_roi = 0
				elseif y_roi == o_h then y_roi = y_roi - n_h
				else y_roi = y_roi - n_h/2
				end
				
				self:set_image_roi(x_roi, y_roi, n_w, n_h)
				local rect = cv_get_image_roi(self.cv_image)
				local dst = cv_create_image(rect.width, rect.height, self.cv_image.depth, self.cv_image.nChannels)
				cv_copy(self.cv_image, dst)
				cv_release_image(self.cv_image)
				self.cv_image = dst
				
				return
			end
			
		end
	end
	
	return
end

function _M.pad(self, w, h, pad_mode, gravity_mode, pad_color)

	if not self.cv_image then
		return error("ErrorFile")
	else
		local roi_rect = cv_get_image_roi(self.cv_image)
		local o_w = roi_rect.width
		local o_h = roi_rect.height

		if w == nil and h == nil then
			return
		end
		
		local n_w, n_h
		if w <= 0 then
			if h <= 0 then
				return
			else
				n_h = h
				n_w = o_w*n_h/o_h
			end
		else
			if h <= 0 then
				n_w = w
				n_h = n_w*o_h/o_w
			else
				n_w = w
				n_h = h
			end
		end
		
		if not gravity_mode then
			gravity_mode = 'GRAVITY_NORTH'
		end
		
		if (gravity_mode == 'GRAVITY_FACE' or gravity_mode == 'GRAVITY_FACE_CENTER' or gravity_mode == 'GRAVITY_FACES' or gravity_mode == 'GRAVITY_FACES_CENTER' or gravity_mode == 'GRAVITY_XY_CENTER') then
			return error("ErrorGravity")
		end
		
		if not pad_mode then
			pad_mode = 'PAD_DEFAULT'
		end
		
		local color
		if pad_color then
			color = cv_scalar(pad_color[1], pad_color[2], pad_color[3], pad_color[4])
		else
			color = cv_scalar(255, 255, 255, 0)
		end
		
		local resize_h
		local resize_w 
		
		if pad_mode == 'PAD_DEFAULT' then
			
			if n_w/n_h > o_w/o_h then
				resize_h = n_h
				resize_w = o_w / o_h * resize_h
			else
				resize_w = n_w
				resize_h = resize_w * o_h / o_w
			end
			
		elseif pad_mode == 'PAD_LIMIT' then
			
			if n_w/n_h > o_w/o_h then
				resize_h = n_h > o_h and o_h or n_h
				resize_w = o_w / o_h * resize_h
			else
				resize_w = n_w > o_w and o_w or n_w
				resize_h = resize_w * o_h / o_w
			end

		elseif pad_mode == 'PAD_M_LIMIT' then
			resize_w = o_w
			resize_h = o_h
			n_w = n_w < o_w and o_w or n_w
			n_h = n_h < o_h and o_h or n_h
		end
		

		local x, y
		local dst = cv_create_image(n_w, n_h, self.cv_image.depth, self.cv_image.nChannels)
		cv_set(dst, color)
		x, y = cv_center_of_gravity(dst, gravity_mode)
		
		self:resize(resize_w, resize_h, nil, 'INTER_AREA')

		if x > n_w/2 then x = n_w - resize_w
		elseif x < n_w/2 then x = 0
		else x = x - resize_w/2
		end
		
		if y > n_h/2 then y = n_h - resize_h
		elseif y < n_h/2 then y = 0
		else y = y - resize_h/2
		end
		
		cv_set_image_roi(dst, x, y, resize_w, resize_h)
		cv_add_weighted(dst, 0, self.cv_image, 1, 0.0, dst)
		cv_reset_image_roi(dst)
		
		cv_release_image(self.cv_image)
		self.cv_image = dst
	end
	return
end

function _M.round_corner(self, radius, bg_color)

	if not self.cv_image then
		return error("ErrorFile")
	else
	
		local background_color
		if not bg_color then
			background_color = cv_scalar(255, 255, 255, 0)
		else
			background_color = cv_scalar(bg_color[1], bg_color[2], bg_color[3], bg_color[4])
		end

		radius = radius or 0
		
		local line_color = cv_scalar(255, 255, 255, 255)
		
		local roi_rect = cv_get_image_roi(self.cv_image)
		local o_w = roi_rect.width
		local o_h = roi_rect.height
		if o_w > o_h  then
			radius = radius > o_h / 2 and o_h / 2 or radius
		else
			radius = radius > o_w / 2 and o_w / 2 or radius
		end
		
		local scale_rate = 5
		local roi_x = o_w * (scale_rate - 1) / 2 - 1
		local roi_y = o_h * (scale_rate - 1) / 2
		
		local mask = _M:CV(cv_create_image(o_w * scale_rate, o_h * scale_rate, self.cv_image.depth, self.cv_image.nChannels))
		
		if (radius == 0) then
			mask:rectangle(0, 0, o_w, o_h, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
		elseif (radius < 0) then
			mask:ellipse(o_w*scale_rate/2-2, o_h*scale_rate/2, o_w/2-1, o_h/2, 0, 0, 360, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
		else
			mask:rectangle(roi_x + radius, roi_y, roi_x + o_w - radius, roi_y + o_h, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
			mask:rectangle(roi_x, roi_y + radius, roi_x + o_w, roi_y + o_h - radius, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
				
--			mask:ellipse(roi_x + radius-1, roi_y + radius-1, radius-1, radius-1, 0, 180, 270, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
--			mask:ellipse(roi_x + o_w - radius-1, roi_y + radius, radius, radius, 0, 270, 360, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
--			mask:ellipse(roi_x + o_w - radius, roi_y + o_h - radius, radius-1, radius-1, 0, 0, 90, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
--			mask:ellipse(roi_x + radius-1, roi_y + o_h - radius, radius-1, radius-1, 0, 180, 90, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')

			mask:ellipse(roi_x + radius, roi_y + radius, radius, radius, 0, 180, 270, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
			mask:ellipse(roi_x + o_w - radius, roi_y + radius, radius, radius, 0, 270, 360, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
			mask:ellipse(roi_x + o_w - radius, roi_y + o_h - radius, radius, radius, 0, 0, 90, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
			mask:ellipse(roi_x + radius, roi_y + o_h - radius, radius, radius, 0, 180, 90, {line_color.val[0],line_color.val[1],line_color.val[2],line_color.val[3]}, -1, 'CV_AA')
		end
		
		mask:set_image_roi(roi_x, roi_y, o_w, o_h)
		local dst2 = cv_create_image(o_w, o_h, self.cv_image.depth, self.cv_image.nChannels)
		cv_and(self.cv_image, mask.cv_image, dst2, nil)

		cv_not(mask.cv_image, mask.cv_image)
		
		local dst1 = cv_create_image(o_w, o_h, self.cv_image.depth, self.cv_image.nChannels)
		cv_set(dst1, background_color)
		cv_and(dst1, mask.cv_image, dst1, nil)
		cv_or(dst1, dst2, dst1, nil)
		
		mask:release_image()
		cv_release_image(dst2)
		cv_release_image(self.cv_image)
		self.cv_image = dst1
	end
	return
end

--function _M.background_color(self, bg_color)
--
--	if not self.cv_image then
--		return error("Failed to set background color to the image")
--	else
--	
--		local background_color
--		if not bg_color then
--			background_color = cv_scalar(255, 255, 255, 0)
--		else
--			background_color = cv_scalar(bg_color[1], bg_color[2], bg_color[3], bg_color[4])
--			print(background_color.val[0],background_color.val[1],background_color.val[2],background_color.val[3])
--		end
--	
--		local dst = _M:CV(cv_create_image(self.cv_image.width, self.cv_image.height, self.cv_image.depth, self.cv_image.nChannels))
--		
--		for i = 0, self.cv_image.height, 1 do
--			for j = 0, self.cv_image.width, 1 do
--			
--				*b=data[i*step+j*chanels+0];
--		           *g=data[i*step+j*chanels+1];
--		           *r=data[i*step+j*chanels+2];
--			end
--		end
--		
--		cv_set(dst.cv_image, background_color)
--		cv_add_weighted(dst.cv_image, 0.5, self.cv_image, 1, 0.0, dst.cv_image)
----		cv_copy(self.cv_image, dst.cv_image, mask.cv_image)
--		return dst
--	end
--
--end

local function printf(...)
	print(string.format(...))
end

function _M.overlay(self, src, x, y, w, h, alpha, gravity_mode, bg_color)

	if not self.cv_image or not src.cv_image then
		return error("ErrorFile")
	else
		
		if not gravity_mode then
			gravity_mode = 'GRAVITY_NORTH_WEST'
		end
		
		if not alpha then
			alpha = 1
		end

		w = w or 0
		h = h or 0
		
		w = (w == src.cv_image.width) and w or src.cv_image.width
		h = (h == src.cv_image.height) and h or src.cv_image.height
		
		x, y = self:overlay_canvas(x, y, w, h, gravity_mode, bg_color)

		local src_data = ffi.cast("unsigned char *",src.cv_image.imageData)
		local step = src.cv_image.widthStep
		local self_data = ffi.cast("unsigned char *",self.cv_image.imageData)
		local step_self = self.cv_image.widthStep
		
		local index_x = x < 0 and 0 or x
		local index_y = y < 0 and 0 or y	

		local i, j
		for j = 0, src.cv_image.height, 1 do
			for i = 0, src.cv_image.width, 1 do
				if (src_data[j*step+i*4+3] > 200) then
					self_data[index_y*step_self+index_x*4 + j*step_self + i*4 + 0] = self_data[index_y*step_self+index_x*4 + j*step_self + i*4 + 0] * (1-alpha) + src_data[j*step + i*4 + 0] * alpha
					self_data[index_y*step_self+index_x*4 + j*step_self + i*4 + 1] = self_data[index_y*step_self+index_x*4 + j*step_self + i*4 + 1] * (1-alpha) + src_data[j*step + i*4 + 1] * alpha
					self_data[index_y*step_self+index_x*4 + j*step_self + i*4 + 2] = self_data[index_y*step_self+index_x*4 + j*step_self + i*4 + 2] * (1-alpha) + src_data[j*step + i*4 + 2] * alpha
					self_data[index_y*step_self+index_x*4 + j*step_self + i*4 + 3] = self_data[index_y*step_self+index_x*4 + j*step_self + i*4 + 3] * (1-alpha) + src_data[j*step + i*4 + 3] * alpha
				end
			end
		end
		
		return
	end
end

function _M.overlay_canvas(self, x, y, w, h, gravity_mode, bg_color)

	if not self.cv_image then
		return error("ErrorFile")
	else
		local roi_rect = cv_get_image_roi(self.cv_image)
		local o_w = roi_rect.width
		local o_h = roi_rect.height

		x = x or 0
		y = y or 0
		local n_w = w or 0
		local n_h = h or 0
		
		n_w = n_w < 0 and 0 or n_w
		n_h = n_h < 0 and 0 or n_h
		
		
		if not gravity_mode then
			gravity_mode = 'GRAVITY_NORTH_WEST'
		end
		
		local background_color
		if not bg_color then
			background_color = cv_scalar(255, 255, 255, 0)
		else
			background_color = cv_scalar(bg_color[1], bg_color[2], bg_color[3], bg_color[4])
		end
		
		x, y = cv_coord_gravity_to_image(self.cv_image, x, y, gravity_mode, n_w, n_h)
		
		local dest_width, dest_height
		
		
		if x < 0 and y < 0 then
					
			dest_width = o_w - x < n_w and n_w or o_w - x
			dest_height = o_h - y < n_h and n_h or o_h - y
			dst = cv_create_image(dest_width, dest_height, self.cv_image.depth, self.cv_image.nChannels)
			cv_set(dst, background_color)
			cv_set_image_roi(dst, -x, -y, o_w, o_h)
			
		elseif x < 0 and y >= 0 then
			
			dest_width = o_w - x < n_w and n_w or o_w - x
			dest_height = y + n_h > o_h and y + n_h or o_h
			dst = cv_create_image(dest_width, dest_height, self.cv_image.depth, self.cv_image.nChannels)
			cv_set(dst, background_color)
			cv_set_image_roi(dst, -x, 0, o_w, o_h)
			
		elseif x >= 0 and y < 0 then
			
			dest_width = x + n_w > o_w and x + n_w or o_w
			dest_height = o_h - y < n_h and n_h or o_h - y
			dst = cv_create_image(dest_width, dest_height, self.cv_image.depth, self.cv_image.nChannels)
			cv_set(dst, background_color)
			cv_set_image_roi(dst, 0, -y, o_w, o_h)
		else
			dest_width = x + n_w > o_w and x + n_w or o_w
			dest_height = y + n_h > o_h and y + n_h or o_h
			dst = cv_create_image(dest_width, dest_height, self.cv_image.depth, self.cv_image.nChannels)
			cv_set(dst, background_color)
			cv_set_image_roi(dst, 0, 0, o_w, o_h)
		end
		
		cv_copy(self.cv_image, dst)
		cv_reset_image_roi(dst)
		cv_release_image(self.cv_image)
		self.cv_image = dst
		
		x = x < 0 and 0 or x
		y = y < 0 and 0 or y	
		
		return x, y
	end

end

function _M.to_magick(self)

	local storageType
	if self.cv_image.depth == image_depth["IPL_DEPTH_8U"] then
		storageType = "CharPixel"
	elseif self.cv_image.depth == image_depth["IPL_DEPTH_8S"] then
		storageType = "ShortPixel"
	elseif self.cv_image.depth == image_depth["IPL_DEPTH_16S"] then
		storageType = "IntegerPixel"
	elseif self.cv_image.depth == image_depth["IPL_DEPTH_32S"] then
		storageType = "LongPixel"
	elseif self.cv_image.depth == image_depth["IPL_DEPTH_32F"] then
		storageType = "FloatPixel"
	elseif self.cv_image.depth == image_depth["IPL_DEPTH_64F"] then
		storageType = "DoublePixel"
	else
		storageType = "UndefinedPixel"
	end
	
	--local map = string.format("%c%c%c%c", self.cv_image.colorModel[2], self.cv_image.colorModel[1], self.cv_image.colorModel[0], self.cv_image.colorModel[3])

	local rect = cv_get_image_roi(self.cv_image)
	
	local dst = cv_create_image(rect.width, rect.height, self.cv_image.depth, self.cv_image.nChannels)
	cv_copy(self.cv_image, dst)
	local mgk = magick.constitute_image(dst.width, dst.height, 'BGRA', storageType, dst.imageData)
	cv_release_image(dst)
								
	return mgk
end


return _M


