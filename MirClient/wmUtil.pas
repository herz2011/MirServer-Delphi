unit wmutil;
{
   ����Ԫ��Ҫ��WIL,WIX�ļ����в���������WIX�������ļ���WIL��ͼ�󣨽�ɫ�������ļ�
}

interface

uses
  Windows, SysUtils, Graphics, DIB, DXDraws;

type
{********WIS �ļ����� By 2009-11-11 �����********}
  TDeCodeRLE = packed record   //2�ֽ�
    Num : Byte;
    Value : Byte;
  end;                   //RLE ѹ���Ľṹ
  PTDeCodeRLE = ^TDeCodeRLE;

  TWISImageHead = packed record  //12�ֽ�
    DeCodeMake : Integer;            //���ܱ�� 
    Width : Word;              //��
    Height : Word;             //��
    X : SmallInt;              //X����
    Y : SmallInt;              //Y����
  end;
  PTWISImageHead = ^TWISImageHead;   //ÿ��ͼ��ͷ��12�ֽ�

  TWISImageSize = packed record  //12�ֽ�
    ImageOff: Integer;         //ƫ�ư����ļ�ͷ
    ImageSize: Integer;        //��С�����ļ�ͷ
    Unknow: Integer;           //δ֪����
  end;                         //ʵ���ϸýṹ�������൱�� WIX �ļ�������
  PTWISImageSize = ^TWISImageSize;

  TWISImageInfo = packed record  // 24�ֽ�
    WISImageHead : TWISImageHead;
    WISImageSize : TWISImageSize;
  end;
  PTWISImageInfo = ^TWISImageInfo;

  TAWISImageSize = packed record //24000�ֽ�
    A: array[0..999] of TWISImageSize;
  end;
  PTAWISImageSize = ^TAWISImageSize;

  TWISHead = packed record
    WISMake : string[4];       //WIS��ʽ��� 'WISA'
    LoveFF : array[0..195] of Byte;
  end;                      //WIS �ļ�ͷ��200�ֽ�

   TWMImageHeader = record
      Title: string[40];        //'WEMADE Entertainment inc.'
      ImageCount: integer;      //���е��ļ���
      ColorCount: integer;      //ɫ������
      PaletteSize: integer;     //��ɫ���С
   end;
   PTWMImageHeader = ^TWMImageHeader;

   TWMImageInfo = record
      Width: smallint;          //ͼƬ����
      Height: smallint;         //ͼƬ�߶�
      px: smallint;             //λ��ƫ������X,Y
      py: smallint;
      bits: PByte;              //ͼ������
   end;
   PTWMImageInfo = ^TWMImageInfo;

   TWMIndexHeader = record
      Title: string[40];        //'WEMADE Entertainment inc.'
      IndexCount: integer;      //�����ļ�����������Ŀ
   end;
   PTWMIndexHeader = ^TWMIndexHeader;

   TWMIndexInfo = record
      Position: integer;        //������λ�ã�ƫ������
      Size: integer;            //ͼƬ���ݴ�С
   end;
   PTWMIndexInfo = ^TWMIndexInfo;

   TDXImage = record            //ͼ��ƫ����
      npx: smallint;
      npy: smallint;
      surface: TDirectDrawSurface; //��ͼ����
      LatestTime: integer;         //���һ��ʹ�ñ�ͼƬ��ʱ��
   end;
   PTDxImage = ^TDXImage;

  TWzlHeader = record
    sTitle: string[40]; //����
    ImageCount: Integer; //
    i1: integer;
    i2: integer;
    i3: integer;
    i4: Integer;
  end;

  TWzlIndexHeader = record
    sTitle: string[40];
    IndexCount: Integer;
  end;

  TWzlImageInfo = packed record
    btEn1: Byte; //3(8λ) 5(16)λ
    btEn2: Byte;
    bt2: Byte;
    bt3: Byte;
    nWidth: smallint;
    nHeight: smallint;
    wPx: smallint;
    wPy: smallint;
    iLen: Cardinal;
  end;

function WidthBytes(w: Integer): Integer;
function PaletteFromBmpInfo(BmpInfo: PBitmapInfo): HPalette;
procedure CreateDIB256(var Bmp: TBitmap; BmpInfo: PBitmapInfo; Bits: PByte);
function  MakeBmp (w, h: integer; bits: Pointer; pal: TRGBQuads): TBitmap;
procedure DrawBits(Canvas: TCanvas; XDest, YDest: integer; PSource: PByte; Width, Height: integer);

implementation

//ͼƬ��һ����������Ҫ���ֽ�����256ɫ����������4�ı���
function WidthBytes(w: Integer): Integer;
begin
     Result := (((w * 8) + 31) div 32) * 4;
end;

//��BMP�ļ��л�ȡ��ɫ����Ϣ�������ص�ɫ����
function PaletteFromBmpInfo(BmpInfo: PBitmapInfo): HPalette;
var
   PalSize, n: Integer;
   Palette: PLogPalette;
begin
     PalSize := SizeOf(TLogPalette) + (256 * SizeOf(TPaletteEntry));
     Palette := AllocMem(PalSize);

     with Palette^ do
     begin
          palVersion := $300;
          palNumEntries := 256;
          for n := 0 to 255 do
          begin
               palPalEntry[n].peRed := BmpInfo^.bmiColors[n].rgbRed;
               palPalEntry[n].peGreen := BmpInfo^.bmiColors[n].rgbGreen;
               palPalEntry[n].peBlue := BmpInfo^.bmiColors[n].rgbBlue;
               palPalEntry[n].peFlags := 0;
          end;
     end;
     Result := CreatePalette(Palette^);
     FreeMem(Palette, PalSize);
end;

//����BMP�ļ�����256ɫ��λͼ
procedure CreateDIB256(var Bmp: TBitmap; BmpInfo: PBitmapInfo; Bits: PByte);
var
   dc, MemDc: HDC;
   OldPal: HPalette;
begin
   DeleteObject(Bmp.ReleaseHandle);
   DeleteObject(Bmp.ReleasePalette);
   try
      //Windows��Ļ��ͼ���
      dc := GetDC(0);
      try
         //��������Ļ���ݵĻ�ͼ���
         MemDC := CreateCompatibleDC(DC);  
         DeleteObject(SelectObject(MemDC, CreateCompatibleBitmap(dc, 1, 1)));

         OldPal := 0;
         Bmp.Palette := PaletteFromBmpInfo(BmpInfo);
         OldPal := SelectPalette(MemDc, Bmp.Palette, False);
         RealizePalette(MemDc);
         try
            Bmp.Handle := CreateDIBitmap(MemDc, BmpInfo^.bmiHeader, CBM_INIT,
                     Pointer(Bits), BmpInfo^, DIB_RGB_COLORS);
         finally
            if OldPal <> 0 then
               SelectPalette(MemDc, OldPal, True);
         end;
      finally
         if MemDC <> 0 then
            DeleteDC(MemDC);
      end;
   finally
      if dc <> 0 then
         ReleaseDC(0, DC);
   end;
   if Bmp.Handle = 0 then
      Exception.Create('CreateDIBitmap failed');
end;

//����λͼ�Ŀ����ߺ�λͼ���ݡ���ɫ�崴��һ��BMP����
function  MakeBmp (w, h: integer; bits: Pointer; pal: TRGBQuads): TBitmap;
var
   i, k: integer;
   BmpInfo: PBitmapInfo;
   HeaderSize: Integer;
   bmp: TBitmap;
begin
   HeaderSize := SizeOf(TBitmapInfo) + (256 * SizeOf(TRGBQuad));
   GetMem (BmpInfo, HeaderSize);
   for i:=0 to 255 do begin
      BmpInfo.bmiColors[i] := pal[i];
   end;
   with BmpInfo^.bmiHeader do begin
      biSize := SizeOf(TBitmapInfoHeader);
      biWidth := w;
      biHeight := h;
      biPlanes := 1;
      biBitCount := 8; //8bit
      biCompression := BI_RGB;
      biClrUsed := 0;
      biClrImportant := 0;
   end;
   Bmp := TBitmap.Create;
   CreateDIB256 (Bmp, BmpInfo, bits);
   FreeMem (BmpInfo);
   Result := Bmp;
end;

//�ڻ����ϻ���λͼ
//  canvas:��ͼ����
//  XDest,TDest:���Ͻ�����
//  PSource��λͼ����
//  Width,Height:λͼ����
procedure DrawBits(Canvas: TCanvas; XDest, YDest: integer; PSource: PByte; Width, Height: integer);
var
  HeaderSize : integer;
  bmpInfo : PBitmapInfo;
begin
  if PSource = nil then exit;

  HeaderSize := Sizeof(TBitmapInfo) + (256 * Sizeof(TRGBQuad));
  BmpInfo := AllocMem(HeaderSize);
  if BmpInfo = nil then raise Exception.Create('TNoryImg: Failed to allocate a DIB');
  with BmpInfo^.bmiHeader do begin
    biSize        := SizeOf(TBitmapInfoHeader);
    biWidth       := Width;
    biHeight      := -Height;
    biPlanes      := 1;
    biBitCount    := 8;
    biCompression := BI_RGB;
    biClrUsed     := 0;
    biClrImportant:= 0;
  end;
  SetDIBitsToDevice(Canvas.Handle, XDest, YDest, Width, Height, 0, 0, 0, Height,
                    PSource, BmpInfo^, DIB_RGB_COLORS);
  FreeMem(BmpInfo, HeaderSize);
end;

end.