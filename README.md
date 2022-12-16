# MS2109 HID control endpoint

## Introduction 
This repository contains description of HID endpoint of HDMI to USB devices based on [MacroSilicon MS2109](http://en.macrosilicon.com/info.asp?base_id=2&third_id=50) chip.


## Acknowledgments
Knowledge in this repo is basing heavly on data found in following places:

 - https://github.com/YuzukiHD/YuzukiHCC
 - https://github.com/BertoldVdb/ms-tools
 - others


## Architecture
 - The chip contain a 8051 core that executes code from a mask ROM. 
 - On boot this code copies extra firmware from an external EEPROM that will be called from some configurable (fixed-address) hooks in the ROM. 
 - When connected to computer it exposes 4 endpoints:
    - USB Compsite Device
    - USB Video Device
    - USB Audio Device
    - USB Input Device (HID)


## HID Endpoint
Communication with device is performed by sending and receiving HID feature reports with `reporId==0`. Out of the box it is possible to read EEPROM memory and registers. However BertoldVdb's shown that is possible to extend these capabilites by patching orginal firmware. 

### Read EEPROM (0xE5)
Buffers size: 9 bytes

SetFeature buffer:
```
00,             //Report ID=0
E5,             //Command 0xE5 = Read EEPROM
xx,xx,          //Address
xx,xx,xx,xx,xx  //Unused
```

GetFeature buffer:
```
00,             //Report ID=0
E5,             //Command 0xE5 = Read EEPROM
xx,xx,          //Address
xx,xx,xx,xx,xx  //EEPROM memory content (5 bytes)
```

Code sample - two calls are used to request memory contents.
```
HidD_SetFeature(DevHandle, @setf_buffer, SizeOf(setf_buffer));
HidD_GetFeature(DevHandle, @getf_buffer, SizeOf(setf_buffer));
```



### Write EEPROM (0xE6)
Buffer size: 9 bytes

SetFeature buffer:
```
00,             //Report ID=0
E6,             //Command 0xE6 = Write EEPROM
xx,xx,          //Address
xx,xx,          //Data to write (2 bytes only?)
xx,xx,xx        //Unused
```


Code sample:
```
HidD_SetFeature(DevHandle, @setf_buffer, SizeOf(setf_buffer));
```


### Read XDATA (0xB5)
Buffers size: 9 bytes

SetFeature buffer:
```
00,             //Report ID=0
B5,             //Command 0xB5 = Read XDATA
xx,xx,          //Address
xx,xx,xx,xx,xx  //Unused
```

GetFeature buffer:
```
00,             //Report ID=0
B5,             //Command 0xB5 = Read XDATA
xx,xx,          //Address
xx,             //XDATA Value
xx,xx,xx,xx     //Unused
```

Code sample - two calls are used to request memory contents.
```
HidD_SetFeature(DevHandle, @setf_buffer, SizeOf(setf_buffer));
HidD_GetFeature(DevHandle, @getf_buffer, SizeOf(setf_buffer));
```



### Write XDATA (0xB6)
Buffer size: 9 bytes

SetFeature buffer:
```
00,             //Report ID=0
B6,             //Command 0xB6 = Write XDATA
xx,xx,          //Address
xx,             //Data to write (1 byte only?)
xx,xx,xx,xx     //Unused
```



### Read SFR (0xC5)
To be described


### Write SFR (0xC6)
To be described

