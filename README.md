# SaraKIT-RCCar-Remote-Controller

Welcome to the GitHub repository for the SaraKIT-RCCar-Remote-Controller, a versatile remote control application designed to enhance projects like "RC Car - LEGO Powered" and "Self-Balancing LEGO Robot", which I've presented on hackster.io, hackaday.io, our GitHub, and elsewhere.

![SaraKIT_Remote_Controller](https://github.com/SaraEye/SaraKIT-RCCar-Remote-Controller/assets/35704910/f673ddda-3e6d-40ba-bf0e-4505dbb279fb)

This remote controller allows for connection to a Raspberry Pi (SaraKIT) to control the direction and speed of your project using one or two fingers. Additionally, it offers the capability to view live video feed from one or two cameras connected to the Raspberry Pi. The controller connects to the Raspberry Pi via your home WiFi network.

The controller is developed in Delphi FireMonkey, enabling its use on Android phones, iPhones, and directly from PC/MAC computers.

## Raspberry Pi Companion Code

Below you'll find a sample code snippet for Raspberry Pi in C++ that works in conjunction with the remote controller:

```cpp
#include <iostream>
#include <signal.h>
#include <stdio.h>
#include <math.h>
#include <arm_neon.h>
#include "unistd.h"
#include <fstream>

#include "struct.hpp"
#include "lib/viewer/viewer.hpp"
#include "lib/SaraKIT/devices.hpp"
#include "lib/RC/remoteControl.hpp"

using namespace std;
 
cv::Mat frame0, frame0Gray, frame0GrayHalf, frame0GrayHalfEdge; // cam0
cv::Mat frame1, frame1Gray, frame1GrayHalf, frame1GrayHalfEdge; // cam1
cv::Mat imgProcessed;

ViewerStatus viewStatus;
RemoteControll rc;

//ctrl-c 
void ctrlc_handler(sig_atomic_t s){
    printf("\nCaught signal %d\n",s);
    BLDCMotor_MoveStop(0);
    BLDCMotor_MoveStop(1);
    control_c=true;	
}

int main(int argc, char** argv){
    signal(SIGINT,ctrlc_handler);

	camwidth=640;
	camheight=480;

    imgProcessed=cv::Mat(camheight, camwidth, CV_8UC3);

    init_camera(0, camwidth, camheight, false, false, true, true, true);
    sleepms(200);

    init_viewer(ViewMode::Camera0,ViewMode::Processed);

    //set gimbals pole
    BLDCMotor_PolePairs(0,11);
    BLDCMotor_PolePairs(1,11);
    BLDCMotor_On(0,true);//speed
    BLDCMotor_On(1,true);//steering

    int iz=0;
    while (_SPICheck()==false && iz<10) {
        iz++;
        sleepms(100);
    }

    int px=-1000;
    int py=-1000;
    int lastpx=px;
    int lastpy=py;
    int btn;

    float startX=0;
    printf("Start Loop\n");
    do {
        // Get frame to frame,frameGray,frameGrayHalf
        GetFrame(); //GetFrame()==1 (new frame from cam0, ==2 from cam1, ==3 from cam0 & cam 1)

        //button from the remote control
        btn=rc.getButton();
        if (btn==1) {            
            printf("ButtonA pressed\n");
        }
        if (btn==2) {            
            printf("ButtonB pressed\n");
        }
        if (btn==3) {
            printf("ButtonC pressed\n");
        }

        //RGB Color from the remote control
        rc.getColorRGB(&isColorRGB,&ColorRGB);
        if (isColorRGB) {
            printf("R:%.0f G:%.0f B:%.0f \n",ColorRGB[0],ColorRGB[1],ColorRGB[2]);
        }

        //speed/steering wheel from the remote control
        rc.getPos(&px,&py);
        if (px!=-1000 && lastpx!=px) {
            lastpx=px;
            BLDCMotor_MoveToAngle(1,px+startX,1,70,true);
            printf("%.2f PX\n",px+startX);
        }
        if (py!=-1000 && lastpy!=py) {
            lastpy=py;
            if (py>0)
                BLDCMotor_MoveContinuousTorque(0,1,(float)py);
            else
                BLDCMotor_MoveContinuousTorque(0,-1,-(float)py);
            printf("%.2f PY\n",(float)py);
        }
            
        viewStatus = viewer_refresh();

    } while (viewStatus != ViewerStatus::Exit && control_c != true);
    rc.stop();
    closing_function(0);
    return 1;
}

```

## Installation Files

For your convenience, here are the links to the installation files:

- Android: [Download Link](https://sarakit.saraai.com/download/SaraKITRemoteController.apk)
- Windows executable: [Download Link](https://sarakit.saraai.com/download/SaraKITRemoteController.exe)

## Contribution and Customization

We welcome enhancements and contributions. If you've written your own code in C++ or Pascal that you'd like to share with the community, please let us know. We'd be happy to include a link to your repository here.

### Example Code for RCCar with Controller Support:

[https://github.com/SaraEye/SaraKIT-RCCar-Raspberry-Pi](https://github.com/SaraEye/SaraKIT-RCCar-Raspberry-Pi)

---

Feel free to dive into the project, customize the controller to your liking, and enhance your SaraKIT-powered projects. Your feedback and contributions not only help improve this project but also inspire innovation within the community. Happy building!
```

https://sarakit.saraai.com/
