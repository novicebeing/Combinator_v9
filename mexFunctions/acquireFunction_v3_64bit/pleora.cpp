/*==========================================================
 * mexcpp.cpp - example in MATLAB External Interfaces
 *
 *mex(['-L' pwd],'-lCyCamLib','-lCyUtilsLib','-lCyComLib',['-I' pwd],'camTest.cpp')
 *
 * Illustrates how to use some C++ language features in a MEX-file.
 * It makes use of member functions, constructors, destructors, and the
 * iostream.
 *
 * The routine simply defines a class, constructs a simple object,
 * and displays the initial values of the internal variables.  It
 * then sets the data members of the object based on the input given
 * to the MEX-file and displays the changed values.
 *
 * This file uses the extension .cpp.  Other common C++ extensions such
 * as .C, .cc, and .cxx are also supported.
 *
 * The calling syntax is:
 *
 *		mexcpp( num1, num2 )
 *
 * Limitations:
 * On Windows, this example uses mexPrintf instead cout.  Iostreams 
 * (such as cout) are not supported with MATLAB with all C++ compilers.
 *
 * This is a MEX-file for MATLAB.
 * Copyright 1984-2009 The MathWorks, Inc.
 *
 *========================================================*/
/* $Revision: 1.5.4.4 $ */

#include <iostream>
#include <math.h>
#include "mex.h"
#include <windows.h>
#include <process.h>
#include <time.h>       /* clock_t, clock, CLOCKS_PER_SEC */

#include "CyXMLDocument.h"
#include "CyConfig.h"
#include "CyGrabber.h"
#include "CyCameraRegistry.h"
#include "CyCameraInterface.h"
#include "CyImageBuffer.h"
#include "CyDeviceFinder.h"
#include <stdio.h>
#include <CySimpleMemoryManager.h>

/* */
void killThread();
void threadStatus( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );
void version( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {mexPrintf("PLEORA MEX INTERFACE VERSION 1.0\n");return;}
void acquireSingleImage( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] );

// SET THE COMMAND TABLE
typedef void (* MEXFUNCTION)( int nlhs, mxArray *plhs[], int nrhs, const
mxArray *prhs[] );
struct _cmd_data
{
  char *pCmd;
  void (*pFunction)( int nlhs, mxArray *plhs[], int nrhs, const mxArray
*prhs[] );
} CmdTable[] = {
  {"version" , version},
  {"acquireSingleImage" , acquireSingleImage},
  {"threadstatus" , threadStatus}
};

/* Input Arguments */

#define argument_IN    prhs[10]
#define	sizeX_IN	prhs[0]
#define	sizeY_IN	prhs[1]
#define	nImages_IN	prhs[2]

/* Output Arguments */

#define	imageMatrix_OUT	plhs[0]
#define	timing_OUT	plhs[1]

#define DEBUGMODE FALSE

using namespace std;

//unsigned short *outMatrix = NULL;
CyGrabber *lGrabber = NULL;  // Initialize on the heap
CyCameraInterface *lCamera = NULL; // Initialize to null value

// STORAGE VARIABLE FOR DATA
unsigned short *outputMatrix;
unsigned long *timingArray;
int outputSizeX,outputSizeY,outputSizeN;

// Threading variables
static HANDLE hThread=NULL;

void connectGrabber ();
void acquireImages();

void killThread() {
	WaitForSingleObject(hThread,10000);
	CloseHandle(hThread);
    if (!outputMatrix) {mxFree(outputMatrix);outputMatrix = NULL;}
	if (!timingArray) {mxFree(timingArray);timingArray = NULL;}
}

void threadStatus( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
	if (hThread) {
		mexPrintf("THREAD IS RUNNING\n");
	} else {
		mexPrintf("NO THREADS\n");
	}
	return;
}

void acquireSingleImage( int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[] ) {
	killThread();
	return;
}

unsigned __stdcall acquireImagesThread( void* pArguments ) {
    
   /*if(!SetPriorityClass(GetCurrentProcess(), REALTIME_PRIORITY_CLASS))
   {
      return 0;
   }*/
   
   if(!SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_TIME_CRITICAL))
   {
      return 0;
   }
   
     acquireImages();
     _endthreadex( 0 );
     return 0;
}

void onExit() {
     WaitForSingleObject(hThread,10000);
     CloseHandle( hThread );
     
     if (!outputMatrix) {mxFree(outputMatrix);outputMatrix = NULL;}
	 if (!timingArray) {mxFree(timingArray);timingArray = NULL;}
     if (!lCamera) {delete lCamera;lCamera = NULL;}
     if (!lGrabber) {delete lGrabber;lGrabber = NULL;}
     return;
}

int mexAtExit(void (*onExit)(void));

void mexFunction(
		 int          nlhs,
		 mxArray      *plhs[],
		 int          nrhs,
		 const mxArray *prhs[]
		 )
{
		int h;
		char StrBuffer[65];
        unsigned threadID;
        
    ////////////////////////////////////////////////
    // CONNECT GRABBER, IF NOT ALREADY CONNECTED  //
    ////////////////////////////////////////////////

        //connectGrabber();
        
    ////////////////////////////////////////////////
    // FUNCTION CALL SWITCHYARD                   //
    ////////////////////////////////////////////////
    
		// INITIALIZE
		if (nrhs == 0) {
			if (nlhs != 0) {
				mexErrMsgIdAndTxt("MATLAB:mexcpp:nargout",
						"MEXCPP:initialize does not return anything.");
				return;
			} else {return;}
		}
		
		if (!mxIsChar(prhs[0]))
			mexErrMsgTxt("First argument must be a command string");
		if (mxGetString(prhs[0], StrBuffer, sizeof(StrBuffer)-1))
			mexErrMsgTxt("Unable to read first argument: command string");
		
		  for (h=0; h<sizeof(CmdTable)/sizeof(CmdTable[0]); h++)
		  {
			if (!strcmp(CmdTable[h].pCmd, StrBuffer))
			{
			  CmdTable[h].pFunction(nlhs, plhs, nrhs-1, prhs+1);
			  return;
			}
		  }

		  mexErrMsgTxt("Invalid command");

		  nlhs = nlhs; // avoid compiler warning
		  plhs = plhs; // avoid compiler warning

    ////////////////////////////////////////////////
    // IF WE GET HERE, THERE IS A PROBLEM         //
    ////////////////////////////////////////////////
        
        mexErrMsgTxt("Not sure what has happened - we've reached an unreachable part of the program");
        return;
}

void connectGrabber () {
    if ((!lCamera) | (!lGrabber)) {
        
        // Some variables...
        CyConfig lConfig;
        CyAdapterID lAdapterID;
        CyCameraRegistry lReg;
        
        // We want to make a new connection, so we will check if we are already connected first
        if (lCamera) {delete lCamera;lCamera = NULL;}//mexPrintf("Deleting Old Camera...\n");}
        if (lGrabber) {delete lGrabber;lGrabber = NULL;}//mexPrintf("Deleting Old Grabber...\n");}
        lGrabber = new CyGrabber;
            
        // We now work with an adapter identifier, which is basically a MAC address
        // For this example, we something need a valid ID so we will get one
        // from the CyAdapterID class
        CyAdapterID::GetIdentifier( CyConfig::MODE_DRV, 0, lAdapterID );

        // Step 1:  Open the configuration file.  We create a XML 
        // document with the name of the file as parameter.
        CyXMLDocument lDocument( "C:\\CameraConfig.xml" );
        if ( lDocument.LoadDocument() != CY_RESULT_OK )
        {
            mexPrintf("Error: Could not open config file at C:\\CameraConfig.xml.");
            return;
        }

        // Step 2a: Create a copnfiguration object and fill it from the XML document.
        //CyConfig lConfig;
        if ( lConfig.LoadFromXML( lDocument ) != CY_RESULT_OK )
        {
            mexPrintf("Error: Could not create a configuration object.");
            return;
        }

        // Step 3a: Set the configuration on the entry to connect to.
        // In this case, we only have one entry, so index 0, is good.
        // Select the device you want to use
        lConfig.SetIndex( 0 );

        // Step 4: Connect to the grabber.  It will use the currently
        // selected entry in the config object, hence step 3.

        //CyGrabber lGrabber;
        if ( lGrabber->Connect( lConfig ) != CY_RESULT_OK )
        {
            mexPrintf("Error: Could not connect to grabber");
            return;
        }

        // Step 5: Create a camera object on top of the grabber.  This camera
        // object takes care of configuring both the iPORT and the camera.

        // Find the camera type from the configuration
        char lCameraType[128];
        lConfig.GetDeviceType( lCameraType, sizeof( lCameraType ) );

        // Find the camera in the registry
        //CyCameraRegistry lReg;
        if ( lReg.FindCamera( lCameraType ) != CY_RESULT_OK )
        {
            mexPrintf("Error: Could not find camera in the registry.");
            return;
        }

        // Create the camera.  The previous operation placed the registry 
        // internal settings on the found camera.  The next step will create
        // a camera object of that type.

        if ( lReg.CreateCamera( &lCamera, lGrabber ) != CY_RESULT_OK )
        {
            mexPrintf("Error: Could create the camera object.");
            return;
        }

        // Step 6: Load the camera settings from the XML document

        if ( lCamera->LoadFromXML( lDocument ) != CY_RESULT_OK )
        {
            // error
            mexPrintf("Error: Could not load the XML camera settings.");
            return;
        }
    }
}

void acquireImages() {
    
    unsigned short sizeX, sizeY, nImages;
    
    // Get the image size parameters
    sizeX = outputSizeX;
    sizeY = outputSizeY;
    nImages = outputSizeN;
    
    // Free the output matrix if necessary
      if (outputMatrix)
          free (outputMatrix);
      outputMatrix = NULL;
      if (timingArray)
          free (timingArray);
      timingArray = NULL;
      
    // Step 6a: Set some settings
     lCamera->SetParameter( CY_CAMERA_PARAM_SIZE_X, sizeX );
     lCamera->SetParameter( CY_CAMERA_PARAM_SIZE_Y, sizeY );

    // Step 7: Send the settings to iPORT and the camera

    if ( lCamera->UpdateToCamera() != CY_RESULT_OK )
    {
        // error
        mexPrintf("Error: Could not send the settings to iPORT and the camera.");
        return;
    };

    // Step 8:  Create a buffer for grabbing images.

    // Get some information from the camera
    unsigned short lSizeX, lSizeY, lDecimationX, lDecimationY, lBinningX, lBinningY;
    CyPixelTypeID lPixelType;
    lCamera->GetSizeX( lSizeX );
    lCamera->GetSizeY( lSizeY );
    lCamera->GetDecimationX( lDecimationX );
    lCamera->GetDecimationY( lDecimationY );
    lCamera->GetBinningX( lBinningX );
    lCamera->GetBinningY( lBinningY );
    lCamera->GetEffectivePixelType( lPixelType );


    if ( ( lDecimationX != 0 ) && ( lDecimationY != 0 ) && ( lBinningX != 0 ) && ( lBinningY != 0 ) )
    {
        lSizeX = (( lSizeX / lBinningX ) + (( lSizeX % lBinningX ) ? 1 : 0));
        lSizeX = (( lSizeX / lDecimationX ) + (( lSizeX % lDecimationX ) ? 1 : 0));
        lSizeY = (( lSizeY / lBinningY ) + (( lSizeY % lBinningY ) ? 1 : 0));
        lSizeY = (( lSizeY / lDecimationY ) + (( lSizeY % lDecimationY ) ? 1 : 0));
    }

    CyResult lResult;
    unsigned short *outMatrix;              // output matrix
    //imageMatrix_OUT = mxCreateNumericMatrix(0, 0, mxUINT16_CLASS, mxREAL);
    // Point mxArray to outMatrix
    //mxSetData(imageMatrix_OUT, outMatrix);

    // Create the buffer.
    CyImageBuffer lBuffer( lSizeX, lSizeY, lPixelType );
    lBuffer.SetQueueSize(nImages+1);
    lBuffer.SetQueueMode(true);
    lBuffer.ClearQueue();
       
    // Start the recording
    lResult = lCamera->GetGrabber().StartRecording(  CyChannel( 0 )); // Start the recording

    Sleep(500);

    lResult = lCamera->GetGrabber().StopRecording(  CyChannel( 0 )); // Stop the recording
         
    // Acquire the images
    for (long i = 0;i<nImages;i++)
    {
        lResult = lCamera->Grab(  CyChannel( 0 ), // always this for now,
                 lBuffer,
                 CyGrabber::FLAG_GRAB_RECORDING );
    
        if ( lResult != CY_RESULT_OK )
        {
            if (i == 0)
            {
                mexPrintf("Timeout on camera\n");
                //imageMatrix_OUT = mxCreateDoubleMatrix( (mwSize) 1, (mwSize) 1, mxREAL);
                //outMatrix = (unsigned short*) mxGetData(imageMatrix_OUT);
                //outMatrix[0] = 0;
                return;
            }
            break;
        }
    }

    const unsigned char* lPtr;
    unsigned long lSize;

    // Get the size of the images
    unsigned short imSizeX = lSizeX;
    unsigned short imSizeY = lSizeY-1;
    unsigned short imHeaderSize = lSizeX;

    // create the output matrix
    size_t imagesInQueue = lBuffer.GetQueueItemCount() + 1;
    
    outputSizeX = imSizeX;
    outputSizeY = imSizeY;
    outputSizeN = imagesInQueue;

    outputMatrix = (unsigned short*) malloc (sizeof (unsigned short) * outputSizeX * outputSizeY * outputSizeN);
	timingArray = (unsigned long*) malloc (sizeof (unsigned long) * outputSizeN);
    
    // Loop over the number of images to read
    for (long i = 0;i<imagesInQueue;i++)
    {
        // Get the pointer to the buffer
        if ( lBuffer.LockForRead( (void**) &lPtr, &lSize, CyBuffer::FLAG_NO_WAIT ) == CY_RESULT_OK )
        {
            // Now, lPtr points to the data and lSize contains the number of bytes available.

            // Also, the GetRead...() methods are available to inquire information
            // about the buffer.

            // Now release the buffer
            //lBuffer.SignalReadEnd();
        

        
			if (lSize == imHeaderSize*2 + imSizeX*imSizeY*2)
			{
				// Save the timing data
				timingArray[i] = lBuffer.GetReadTimestamp();
			
				// Save the data to the output matrix
				for (long j = 0;j<imSizeX*imSizeY;j++)
				{
					outputMatrix[j+imSizeX*imSizeY*i] = ((unsigned short*) lPtr)[imHeaderSize + j];
				}
			} else {
				// Save the timing data
				timingArray[i] = 0;
				
				// Save the data to the output matrix
				for (long j = 0;j<imSizeX*imSizeY;j++)
				{
					outputMatrix[j+imSizeX*imSizeY*i] = 0;
				}
				//mexErrMsgIdAndTxt( "MATLAB:pleora_acquireImages:imageSizeNotCorrect",
				//    "The camera image size is not the same as the size of the output matrix."); 
				//free(outputMatrix);
				//outputMatrix = NULL;
			}
			lBuffer.SignalReadEnd();
		}
    }
    return;
}