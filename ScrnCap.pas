unit ScrnCap;
interface
uses WinTypes, WinProcs, Forms, Classes, Graphics, Controls;

 { �������� ������������� ������� ������ }
function CaptureScreenRect(ARect : TRect) : TBitmap;
 { ����������� ����� ������ }
function CaptureScreen : TBitmap;
 { ����������� ���������� ������� ����� ��� �������� }
function CaptureClientImage(Control : TControl) : TBitmap;
 { ����������� ���� ����� �������� }
function CaptureControlImage(Control : TControl) : TBitmap;

{===============================================================}
implementation
function GetSystemPalette : HPalette;
var
 PaletteSize  : integer;
 LogSize      : integer;
 LogPalette   : PLogPalette;
 DC           : HDC;
 Focus        : HWND;
begin
 result:=0;
 Focus:=GetFocus;
 DC:=GetDC(Focus);
 try
   PaletteSize:=GetDeviceCaps(DC, SIZEPALETTE);
   LogSize:=SizeOf(TLogPalette)+(PaletteSize-1)*SizeOf(TPaletteEntry);
   GetMem(LogPalette, LogSize);
   try
     with LogPalette^ do
     begin
       palVersion:=$0300;
       palNumEntries:=PaletteSize;
       GetSystemPaletteEntries(DC, 0, PaletteSize, palPalEntry);
     end;
     result:=CreatePalette(LogPalette^);
   finally
     FreeMem(LogPalette, LogSize);
   end;
 finally
   ReleaseDC(Focus, DC);
 end;
end;


function CaptureScreenRect(aRect: TRect): TBitMap;
var
 ScreenDC: HDC;
begin
 Result := TBitMap.Create;
 Result.Width := aRect.Right - aRect.Left;
 Result.Height := aRect.Bottom - aRect.Top;
 ScreenDC := CreateDC(PChar('DISPLAY'), nil, nil, nil);
 try
   BitBlt(Result.Canvas.Handle, 0, 0, Result.Width, Result.Height, ScreenDC, aRect.Left, aRect.Top, SRCCOPY);
 finally
   ReleaseDC(0, ScreenDC);
 end;
end;

function CaptureScreen : TBitmap;
begin
 with Screen do
  Result:=CaptureScreenRect(Rect(0,0,Width,Height));
end;

function CaptureClientImage(Control : TControl) : TBitmap;
begin
 with Control, Control.ClientOrigin do
  result:=CaptureScreenRect(Bounds(X,Y,ClientWidth,ClientHeight));
end;

function CaptureControlImage(Control : TControl) : TBitmap;
begin
 with Control do
  if Parent=Nil then
    result:=CaptureScreenRect(Bounds(Left,Top,Width,Height))
  else
   with Parent.ClientToScreen(Point(Left, Top)) do
    result:=CaptureScreenRect(Bounds(X,Y,Width,Height));
end;
end.