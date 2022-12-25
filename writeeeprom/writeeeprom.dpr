program writeeeprom;

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


const
    EEPROM_SIZE = 2048;


var DevHandle: THandle;
    DevPath: String;
    ov: OVERLAPPED;
    data_out: array [0..8] of byte;
    data_in : array [0..8] of byte;
    eeprom_data: array of byte;
    i,j: integer;
    binfile: File;
    file_len: Integer;
begin
  try
    if ParamCount<>1 then begin
      writeln('Usage: writeeeprom.exe file.bin');
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

        AssignFile(binfile,ParamStr(1));
        FileMode := fmOpenRead;
        Reset(binfile,1);
        file_len:=FileSize(binfile);
        SetLength(eeprom_data,file_len);
        BlockRead(binfile,eeprom_data[0],Length(eeprom_data));
        CloseFile(binfile);


        ZeroMemory(@ov, SizeOf(OVERLAPPED));
        ZeroMemory(@data_out,Length(data_out));
        ZeroMemory(@data_in, Length(data_in));


        for i:=0 to file_len-1 do begin
          //PREPARE BUFFER
          data_out[0]:=$00; //REPORT ID = Always Zero
          data_out[1]:=$e6; //0xE5=EEPROM MEMORY AREA WRITE
          data_out[2]:=i shr 8;   //ADDRESS HIGH BYTE
          data_out[3]:=i and $FF; //ADDRESS LOW BYTE
          data_out[4]:=eeprom_data[i];
          
          HidD_SetFeature(DevHandle,@data_out,SizeOf(data_out));

        end;
        CloseHandle(DevHandle);




      end else Writeln('Invalid device handle');
    end;




  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
