program dumpxdata;

{$APPTYPE CONSOLE}

uses
  SysUtils, Windows;



const
HID_GUIid: TGUID  = '{4D1E55B2-F16F-11CF-88CB-001111000030}';

CM_GET_DEVICE_INTERFACE_LIST_PRESENT     = $00000000;  // only currently 'live' device interfaces
CM_GET_DEVICE_INTERFACE_LIST_ALL_DEVICES = $00000001;  // all registered device interfaces, live or not
CM_GET_DEVICE_INTERFACE_LIST_BITS        = $00000001;

function CM_Get_Device_Interface_ListA(InterfaceClassGuid: PGUID; pDeviceID: PAnsiChar; Buffer: PAnsiChar; BufferLen: ULONG; ulFlags: ULONG): DWORD; stdcall; external 'SetupApi.dll' name 'CM_Get_Device_Interface_ListA';
function CM_Get_Device_Interface_ListW(InterfaceClassGuid: PGUID; pDeviceID: PWideChar; Buffer: PWideChar; BufferLen: ULONG; ulFlags: ULONG): DWORD; stdcall; external 'SetupApi.dll' name 'CM_Get_Device_Interface_ListW';
function CM_Get_Device_Interface_List_SizeA(var ulLen: ULONG; InterfaceClassGuid: PGUID; pDeviceID: PAnsiChar; ulFlags: ULONG): DWORD; stdcall;               external 'SetupApi.dll' name 'CM_Get_Device_Interface_List_SizeA';
function CM_Get_Device_Interface_List_SizeW(var ulLen: ULONG; InterfaceClassGuid: PGUID; pDeviceID: PWideChar; ulFlags: ULONG): DWORD; stdcall;               external 'SetupApi.dll' name 'CM_Get_Device_Interface_List_SizeW';

function HidD_SetFeature(HidDeviceObject: THandle; ReportBuffer: Pointer; Size: Integer): LongBool; stdcall;  external 'HID.dll' name 'HidD_SetFeature';
function HidD_GetFeature(HidDeviceObject: THandle; ReportBuffer: Pointer; Size: Integer): LongBool; stdcall;  external 'HID.dll' name 'HidD_GetFeature';


function getFirstDevicePath(VID,PID:WORD):string;
var
    DevsListSize,i    : DWORD;
    pszDeviceInterface: pWideChar;
    DevicePath        : string;
    SearchPath        : string;
begin
    CM_Get_Device_Interface_List_SizeW(&DevsListSize, @HID_GUIid, nil, CM_GET_DEVICE_INTERFACE_LIST_PRESENT);
    GetMem(pszDeviceInterface,DevsListSize);
    CM_Get_Device_Interface_ListW(@HID_GUIid,nil,pszDeviceInterface,DevsListSize,CM_GET_DEVICE_INTERFACE_LIST_PRESENT);

    DevicePath:= '';
    SearchPath:= Format('HID#VID_%.4x&PID_%.4x',[VID,PID]);

    i:=0;
    while i<DevsListSize-1 do begin
      DevicePath:= WideCharToString(pszDeviceInterface+i);
      i:=i+1+Length(DevicePath);
      if Pos(UpperCase(SearchPath), UpperCase(DevicePath))>0 then break else DevicePath:='';
    end;

    Result:=DevicePath;
end;

function printBuffer(buffer: array of byte; length: dword): string;
var i:integer;
    s:string;
begin
 s:='';
 for i := 0 to length - 1 do
  s:=s+Format('%.2x ',[buffer[i]]);

 Result:=s;   
end;


const
    XDATA_SIZE = $10000;


var DevHandle: THandle;
    DevPath: String;
    ov: OVERLAPPED;
    data_out: array [0..8] of byte;
    data_in : array [0..8] of byte;
    xdata_data: array [0..XDATA_SIZE-1] of byte;
    i: integer;
    binfile: File;
begin
  try
    if ParamCount<>1 then begin
      writeln('Usage: dumpxdata.exe dump.bin');
      exit;
    end;


    DevPath := getFirstDevicePath($534d,$2109);
    if Length(DevPath)=0 then begin
      writeln('No device found');
    end else begin
      //Try to open device
      Writeln('Device found: '+DevPath);
      DevHandle := CreateFile( PChar(DevPath), GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_FLAG_OVERLAPPED, 0);
      If DevHandle <> INVALID_HANDLE_VALUE then begin
        ZeroMemory(@ov, SizeOf(OVERLAPPED));
        ZeroMemory(@data_out,Length(data_out));
        ZeroMemory(@data_in, Length(data_in));

        i:=0;
        while i<XDATA_SIZE do begin
          //PREPARE BUFFER
          data_out[0]:=$00;       //REPORT ID = Always Zero
          data_out[1]:=$b5;       //0xb5=XDATA MEMORY AREA READ
          data_out[2]:=i shr 8;   //ADDRESS HIGH BYTE
          data_out[3]:=i and $FF; //ADDRESS LOW BYTE
          data_in[0]:=data_out[0]; //REPORT ID

          HidD_SetFeature(DevHandle,@data_out,SizeOf(data_out));
          HidD_GetFeature(DevHandle,@data_in,SizeOf(data_in));

          //writeln(printBuffer(data_in,SizeOf(data_in)));

          if i<XDATA_SIZE then xdata_data[i]:=data_in[4];

          i:=i+1;
        end;
        CloseHandle(DevHandle);

        AssignFile(binfile,ParamStr(1));
        Rewrite(binfile,1);
        BlockWrite(binfile,xdata_data[0],Length(xdata_data));
        CloseFile(binfile);


      end else Writeln('Invalid device handle');
    end;




  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
