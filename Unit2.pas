unit Unit2;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, IdBaseComponent,
  IdComponent, IdCustomTCPServer, IdCustomHTTPServer, IdHTTPServer, idcontext,
  ActiveX, MMDevApi, ShellAPI, Vcl.ExtCtrls, Registry, ScrnCap, pngimage;

type
  TForm2 = class(TForm)
    Memo1: TMemo;
    IdHTTPServer1: TIdHTTPServer;
    TrayIcon1: TTrayIcon;
    Button1: TButton;
    procedure IdHTTPServer1CreateSession(ASender: TIdContext;
      var VHTTPSession: TIdHTTPSession);
    procedure IdHTTPServer1Exception(AContext: TIdContext;
      AException: Exception);
    procedure IdHTTPServer1CommandGet(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TrayIcon1Click(Sender: TObject);
  private
    { Private declarations }
    procedure HideForm(var Msg: TWMSysCommand); message WM_SYSCOMMAND;
  public
    { Public declarations }
  end;

var
  Form2: TForm2;
  EndPointVolume: IAudioEndpointVolume = nil;

implementation

{$R *.dfm}
{$R *.dfm}

function SearchBitmap(bmMain, bmSub: TBitMap; var R: TRect): boolean;
type
  TIntArray = array [word] of integer;
  PIntArray = ^TIntArray;
var
  p0, p1, p2: PIntArray;
  x, y: integer;
  x1, y1, w, w0, w1, k: integer;
  b: boolean;
begin
  result := true;
  FillChar(R, sizeOf(R), 0);

  bmMain.PixelFormat := pf32bit;
  bmSub.PixelFormat := pf32bit;

  w := bmMain.width;
  w0 := bmMain.width * sizeOf(integer);
  w1 := bmSub.width * sizeOf(integer);

  p0 := bmMain.ScanLine[0];
  p1 := bmSub.ScanLine[0];
  for y := 0 to bmMain.Height - bmSub.Height do
  begin
    for x := 0 to bmMain.width - bmSub.width do
    begin

      b := true;

      p2 := p1;
      k := 0;
      for y1 := 0 to bmSub.Height - 1 do
      begin
        for x1 := 0 to bmSub.width - 1 do
        begin
          if p0[k + x + x1] <> p2[x1] then
          begin
            b := false;
            break;
          end;
        end;
        if not b then
          break;
        integer(p2) := integer(p2) - w1;
        k := k - w;
      end;

      if b then
      begin
        R := Rect(x, y, x + bmSub.width, y + bmSub.Height);
        exit;
      end;
    end;
    integer(p0) := integer(p0) - w0;
  end;
  result := false;
end;

function GetSystemPalette: HPalette;
var
  PaletteSize: integer;
  LogSize: integer;
  LogPalette: PLogPalette;
  DC: HDC;
  Focus: HWND;
begin
  result := 0;
  Focus := GetFocus;
  DC := GetDC(Focus);
  try
    PaletteSize := GetDeviceCaps(DC, SIZEPALETTE);
    LogSize := sizeOf(TLogPalette) + (PaletteSize - 1) * sizeOf(TPaletteEntry);
    GetMem(LogPalette, LogSize);
    try
      with LogPalette^ do
      begin
        palVersion := $0300;
        palNumEntries := PaletteSize;
        GetSystemPaletteEntries(DC, 0, PaletteSize, palPalEntry);
      end;
      result := CreatePalette(LogPalette^);
    finally
      FreeMem(LogPalette, LogSize);
    end;
  finally
    ReleaseDC(Focus, DC);
  end;
end;

procedure autorun;
var
  reg: tregistry;
begin
  reg := tregistry.create;
  reg.rootkey := HKEY_CURRENT_USER;
  if reg.openkey('software\microsoft\windows\currentversion\run', false) then
    reg.writestring(Application.Title, Application.ExeName);
  reg.closekey;
  reg.free;
end;

function GetVolume: integer;
var
  VolumeLevel: Single;
begin
  EndPointVolume.GetMasterVolumeLevelScaler(VolumeLevel);
  result := Round(VolumeLevel * 100);
end;

procedure SetVolume(VolumeLevel: integer);
begin
  EndPointVolume.SetMasterVolumeLevelScalar(VolumeLevel / 100, nil);
  beep;
end;

procedure TForm2.Button2Click(Sender: TObject);
begin
  ShowMessage(IntToStr(GetVolume));
end;

procedure TForm2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  IdHTTPServer1.Active := false;
end;

procedure HideForm2;
begin
  Form2.TrayIcon1.Visible := true;
  Application.ShowMainForm := false;
  // ShowWindow(Form2.Handle, SW_HIDE);
  // ShowWindow(Application.Handle, SW_HIDE);
end;

procedure TForm2.HideForm;
begin
  if Msg.CmdType = SC_MINIMIZE then
    HideForm2;
  inherited;
end;

procedure TForm2.FormCreate(Sender: TObject);
var
  DeviceEnumerator: IMMDeviceEnumerator;
  DefaultDevice: IMMDevice;
begin
  IdHTTPServer1.Active := true;
  TrayIcon1.BalloonTitle := Form2.Caption;
  TrayIcon1.Hint := Form2.Caption;
 // HideForm2;
  CoCreateInstance(CLASS_IMMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER,
    IID_IMMDeviceEnumerator, DeviceEnumerator);
  DeviceEnumerator.GetDefaultAudioEndpoint(eRender, eConsole, DefaultDevice);
  DefaultDevice.Activate(IID_IAudioEndpointVolume, CLSCTX_INPROC_SERVER, nil,
    EndPointVolume);

  if EndPointVolume = nil then
    Halt;
end;

procedure ClickNext(x, y: integer);
begin
  SetCursorPos(x, y);
  mouse_event(MOUSEEVENTF_LEFTDOWN, x, y, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTUP, x, y, 0, 0);
  Application.ProcessMessages;
  Sleep(1000);
  y := y + 50;
  SetCursorPos(x, y);
  mouse_event(MOUSEEVENTF_LEFTDOWN, x, y, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTUP, x, y, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTDOWN, x, y, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTUP, x, y, 0, 0);
  keybd_event(vk_Space, 0, 0, 0);
  keybd_event(vk_Space, 0, KEYEVENTF_KEYUP, 0);
  Application.ProcessMessages;
end;

procedure TForm2.IdHTTPServer1CommandGet(AContext: TIdContext;
  ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  s: TStringList;
  vol, x, y, i: integer;
  ss: string;
  bmMain, bmSub: TBitMap;
  b: boolean;
  R: TRect;
  png: TPNGObject;
begin
  AResponseInfo.ContentType := 'text/html; charset=utf-8';
  ss := ARequestInfo.Params.Text;
  if ss <> '' then
  begin
    if pos('scroll', ss) <> 0 then
    begin
      vol := strtoint(trim(Copy(ss, pos('=', ss) + 1, 3)));
      SetVolume(vol);
    end
    else if pos('Shut Down PC', ss) <> 0 then
       ShellExecute(handle, nil, 'shutdown', ' -s -t 5', '', SW_SHOWNORMAL)
    else if pos('Next Episode', ss) <> 0 then
    begin
      bmMain := TBitMap.create();
      bmSub := TBitMap.create();
      bmMain := CaptureScreenRect(Rect(0, 0, Screen.width, Screen.Height));
      png := TPNGObject.create;
      png.LoadFromFile('D:\Программы\Тест\search_bitmap\Win32\Debug\2.png');
      bmSub.Assign(png); // Convert data into bitmap
      png.free;
      b := SearchBitmap(bmMain, bmSub, R);
      x := (R.Left + R.Right) div 2;
      y := (R.Bottom + R.Top) div 2;
      if b then
        ClickNext(x, y)
      else
      begin
      {
        keybd_event(VK_ESCAPE, 0, 0, 0);
        keybd_event(VK_ESCAPE, 0, KEYEVENTF_KEYUP, 0);
        bmMain := CaptureScreenRect(Rect(0, 0, Screen.width, Screen.Height));
        b := SearchBitmap(bmMain, bmSub, R);
        x := (R.Left + R.Right) div 2;
        y := (R.Bottom + R.Top) div 2;
        ClickNext(x, y);       }
      end;
          bmMain.free;
    bmSub.free;
    end;

  end;
  s := TStringList.create;
  s.LoadFromFile(ExtractFilePath(Application.ExeName) + '/index.html');
  ss := IntToStr(GetVolume);
  s.Text := StringReplace(s.Text, 'volume', ss, [rfReplaceAll, rfIgnoreCase]);
  AResponseInfo.ContentText := s.Text;
  s.free;
  ss := Copy(ss, 0, Length(ss));
  Memo1.Lines.Add('[' + AContext.Connection.Socket.Binding.PeerIP + '] ' + ss);
end;

procedure TForm2.IdHTTPServer1CreateSession(ASender: TIdContext;
  var VHTTPSession: TIdHTTPSession);
begin
  Memo1.Lines.Add('OnCreateSession: ' + VHTTPSession.SessionID + '; ' +
    VHTTPSession.RemoteHost);
end;

procedure TForm2.IdHTTPServer1Exception(AContext: TIdContext;
  AException: Exception);
begin
  Memo1.Lines.Add('OnException: ' + AException.Message);
end;

procedure TForm2.TrayIcon1Click(Sender: TObject);
begin

  TrayIcon1.Visible := false;
  Form2.Show;
end;

end.
