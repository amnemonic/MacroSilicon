# MS2109 HID control endpoint

## Introduction 
This repository contains description of HID endpoint of HDMI to USB devices based on [MacroSilicon MS2109](http://en.macrosilicon.com/info.asp?base_id=2&third_id=50) chip.


## Acknowledgments
Knowledge in this repo is basing heavly on data found in following places:

 - https://github.com/YuzukiHD/YuzukiHCC
 - https://github.com/BertoldVdb/ms-tools
 - https://github.com/contiki-os/contiki/wiki/8051-Memory-Spaces#Memory_Spaces


## Architecture
 - The chip contain a 8051 core that executes code from a mask ROM. 
 - On boot this code copies extra firmware from an external EEPROM that will be called from some configurable (fixed-address) hooks in the ROM. 
 - When connected to computer it exposes 4 endpoints:
    - USB Compsite Device
    - USB Video Device
    - USB Audio Device
    - USB Input Device (HID)

## XDATA 
The 8051 architecture has three separate address spaces, the core RAM uses an 8 bit address, so can be up to 256 bytes, XDATA is a 16bit address space (64Kbytes) with read/write capability, and the program space is a 16bit address space with execution and read-only data capability. [[1](https://stackoverflow.com/a/2059998/645146)]



| Description                                           | Start    | End     |  Length   |
|-------------------------------------------------------|---------:|--------:|----------:|
| Internal RAM                                          |   `0x00` |   `0x7F`|    `0x80` |
| Special fuction registers (SFRs)                      |   `0x80` |   `0xFF`|    `0x80` |
| _Memory hole (filled with 0xFF)_                      | `0x0100` | `0x7FFF`|  `0x7F00` |
| Unknown data (looks 32bit aligned)                    | `0x8000` | `0x8FFF`|  `0x1000` |
| _Memory hole (filled with 0xFF)_                      | `0x9000` | `0xBFFF`|  `0x3000` |
| UserRAM                                               | `0xC000` | `0xDFFF`|  `0x2000` |  
| UserConfig                                            | `0xCBD0` | `0xCBFF`|  `0x0030` |
| Code loaded from EEPROM                               | `0xCC00` | Variable| Variable  |
| Unknown data (looks 32bit aligned)                    | `0xE000` | `0xEFFF`|  `0x1000` |
| Filled with 0xFF except:<br>@0xF000, @0xF0E0, @0xF1F0 | `0xF000` | `0xF4FF`|  `0x0500` |
| Filled with 0x00 except:<br>@0xF520                   | `0xF500` | `0xF5FF`|  `0x0100` |
| Filled with 0xFF                                      | `0xF600` | `0xF7FF`|  `0x0100` |
| Unknown                                               | `0xF800` | `0xFAFF`|  `0x0300` |
| _Memory hole (filled with 0xFF)_                      | `0xFB00` | `0xFCFF`|  `0x2000` |
| Unknown                                               | `0xFD00` | `0xFFFF`|  `0x0300` |



## HID Endpoint
Communication with device is performed by sending and receiving HID feature reports with `reportId==0`. Out of the box it is possible to read EEPROM memory and 8051 XDATA. However BertoldVdb shown that is possible to extend these capabilites by patching orginal firmware. 

### Read EEPROM (0xE5)
 - Buffers size: 9 bytes ( 1 byte for report ID=0 and 8 bytes of data)
 - Applies only to MS2109

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
HidD_GetFeature(DevHandle, @getf_buffer, SizeOf(getf_buffer));
```



### Write EEPROM (0xE6)
 - Buffers size: 9 bytes ( 1 byte for report ID=0 and 8 bytes of data)
 - Applies only to MS2109

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
 - Buffers size: 9 bytes ( 1 byte for report ID=0 and 8 bytes of data)
 - Applies to MS2109 and MS2130

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
HidD_GetFeature(DevHandle, @getf_buffer, SizeOf(getf_buffer));
```



### Write XDATA (0xB6)
 - Buffers size: 9 bytes ( 1 byte for report ID=0 and 8 bytes of data)
 - Applies to MS2109 and MS2130

SetFeature buffer:
```
00,             //Report ID=0
B6,             //Command 0xB6 = Write XDATA
xx,xx,          //Address
xx,             //Data to write (1 byte only?)
xx,xx,xx,xx     //Unused
```


