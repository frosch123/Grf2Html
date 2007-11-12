unit osspecific;

interface

{$IFDEF FPC}
   uses classes, libc, png, fpimage, fpimgcanv, fpwritepng;
{$ELSE}
   uses classes, windows, graphics, pngimage;
{$ENDIF}

type
   {$IFNDEF FPC}
      // Identical to libpng definition
      png_color = packed record
         red   : byte;
         green : byte;
         blue  : byte;
      end;
   {$ELSE}
      TCanvas = TFPImageCanvas;
   {$ENDIF}

   // Format of libpng palette as well as of *.bcp files
   TByteArray = array[0..high(longint) - 1] of byte;
   PByteArray = ^TByteArray;
   TPalette = packed array[byte] of png_color;

   TOSIndependentImage = class
   private
      {$IFDEF FPC}
         fImage : TFPMemoryImage;
         fCanvas: TCanvas;
      {$ELSE}
         fBitmap: TBitmap;
      {$ENDIF}
      function getCanvas: TCanvas;
      function getWidth: integer;
      function getHeight: integer;
   public
      constructor create(width, height: integer);
      destructor destroy; override;
      procedure savePng(const fileName: string);
      property canvas: TCanvas read getCanvas;
      property width: integer read getWidth;
      property height: integer read getHeight;
   end;

// Free Pascal defines WINDOWS on windows. Lets do the same for Delphi.
{$IFNDEF FPC}
   {$DEFINE WINDOWS}
{$ENDIF}

const
   {$IFDEF WINDOWS}
      pathSeparator = '\';
   {$ELSE}
      pathSeparator = '/';
   {$ENDIF}

procedure savePng(const fileName: string; const palette: TPalette; width, height: integer; data: PByteArray);

implementation

{$IFDEF FPC}

// Needed constants from "png.h" that are missing in "png.pp".
const
   PNG_LIBPNG_VER_STRING                = '1.2.15';
   PNG_COLOR_TYPE_PALETTE               = 3;
   PNG_COMPRESSION_TYPE_DEFAULT         = 0;
   PNG_FILTER_TYPE_DEFAULT              = 0;
   PNG_INTERLACE_NONE                   = 0;

procedure savePng(const fileName: string; const palette: TPalette; width, height: integer; data: PByteArray);
   procedure error(const msg: string);
   begin
      writeln(msg);
      halt;
   end;
var
   png_ptr                              : png_structp;
   info_ptr                             : png_infop;
   rows                                 : packed array of pointer;
   i                                    : integer;
   f                                    : PFILE;
begin
   f := fopen(pchar(fileName), 'wb');
   if f = nil then error('Error while creating "' + fileName + '".');

   png_ptr := png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil);
   if png_ptr = nil then error('Error in libpng:png_create_write_struct');

   info_ptr := png_create_info_struct(png_ptr);
   if png_ptr = nil then error('Error in libpng:png_create_info_struct');

   if (setjmp(png_ptr^.jmpbuf) <> 0) then
   begin
      // libpng jumps here in the case of an error.
      error('Error in libpng.');
   end;

   png_init_io(png_ptr, pointer(f)); // This typecast is a work-around for a faulty "png.pp".

   png_set_IHDR(png_ptr, info_ptr, width, height, 8, PNG_COLOR_TYPE_PALETTE, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
   png_set_PLTE(png_ptr, info_ptr, @palette[0], length(palette));

   png_write_info(png_ptr, info_ptr);

   setLength(rows, height);
   for i := 0 to height - 1 do rows[i] := @(data^[i * width]);

   png_write_image(png_ptr, @rows[0]);

   png_write_end(png_ptr, info_ptr);
   png_destroy_write_struct(@png_ptr, @info_ptr);

   fclose(f);
   (*
    *  Test case: Canadian Station Set, Output: 18929 files, 39 MB
    *
    *  OS         | FileSystem           | DiskUsage | Real time | User time | Rest
    * ------------+----------------------+-----------+-----------+-----------+--------
    *  Linux      | Ext3                 |  92 MB    |  22 s     |  12 s     |  10 s
    *
    *)
end;

constructor TOSIndependentImage.create(width, height: integer);
begin
   inherited create;
   fImage := TFPMemoryImage.create(width, height);
   fImage.usePalette := true;
   fCanvas := TFPImageCanvas.create(fImage);
end;

destructor TOSIndependentImage.destroy;
begin
   fCanvas.free;
   fImage.free;
end;

function TOSIndependentImage.getCanvas: TCanvas;
begin
   result := fCanvas;
end;

function TOSIndependentImage.getWidth: integer;
begin
   result := fImage.width;
end;

function TOSIndependentImage.getHeight: integer;
begin
   result := fImage.height;
end;

procedure TOSIndependentImage.savePng(const fileName: string);
var
   pal                                  : TPalette;
   bitmap                               : array of byte;
   x, y, i                              : integer;
   c                                    : TFPColor;
begin
   // A "fImage.saveToFile(fileName);" would suffice here. But fpc's own png encoding is awfully slow.
   setLength(bitmap, width * height);
   for y := 0 to height - 1 do
   for x := 0 to width - 1 do bitmap[y * width + x] := fImage.pixels[x,y];
   for i := 0 to fImage.palette.count - 1 do
   begin
      c := fImage.palette[i];
      pal[i].red := c.red shr 8;
      pal[i].green := c.green shr 8;
      pal[i].blue := c.blue shr 8;
   end;
   osspecific.savePng(fileName, pal, width, height, @bitmap[0]);
end;

{$ELSE}

procedure forcePalette(const bmp: HBitmap; const pal: TPalette);
var
   screenDC, dc                         : HDC;
   oldBM                                : HBitmap;
   winPal                               : array[byte] of TRGBQuad;
   i                                    : integer;
begin
   for i := 0 to 255 do
   begin
      winPal[i].rgbRed := pal[i].red;
      winPal[i].rgbGreen := pal[i].green;
      winPal[i].rgbBlue := pal[i].blue;
      winPal[i].rgbReserved := 0;
   end;

   screenDC := getDC(0);
   dc := createCompatibleDC(screenDC);
   oldBM := selectObject(dc, bmp);
   try
      setDIBColorTable(dc, 0, 256, winPal);
   finally
      selectObject(dc, oldBM);
      deleteDC(dc);
      releaseDC(0, screenDC);
   end;
end;

procedure saveBitmapAsPng(const fileName: string; bmp: TBitmap);
var
   png                                  : TPngObject;
   stream                               : TMemoryStream;
begin
   (* Encode and save a png image.
    * We first encode the png into a MemoryStream, and write it then into the file in one block.
    * Perhaps this increases speed on some filesystems, though I could not measure a difference on any I tried.
    *)
   png := TPngObject.create;
   png.assign(bmp);

   stream := TMemoryStream.create;
   png.saveToStream(stream);
   png.free;

   stream.saveToFile(fileName); // You laugh, but this line takes 50-90% of the execution time. (depends on OS/FileSystem/Grf)
   stream.free;
   (* Some numbers:
    *  Test case: Canadian Station Set, Output: 18929 files, 39 MB
    *
    *  OS         | FileSystem           | DiskUsage | Total time | stream.saveToFile | Rest
    * ------------+----------------------+-----------+------------+-------------------+--------
    *  WinXP      | Fat16 (16K clusters) | 314 MB    | 169.7 s    | 153.4 s  90%      |  16.3 s
    *  WinXP      | NTFS                 |  92 MB    |  50.0 s    |  44.5 s  89%      |   5.5 s
    *  Linux/wine | Ext3                 |  92 MB    |  96.9 s    |  52.7 s  54%      |  44.2 s
    *
    *)
end;

procedure savePng(const fileName: string; const palette: TPalette; width, height: integer; data: PByteArray);
var
   y                                    : integer;
   bmp                                  : TBitmap;
begin
   bmp := TBitmap.create;

   bmp.pixelFormat := pf8Bit;
   bmp.width := width;
   bmp.height := height;

   forcePalette(bmp.handle, palette);

   // set bitmap data
   if width > 0 then
   begin
      for y := 0 to height - 1 do move(data^[width * y], bmp.scanLine[y]^, width);
   end;

   saveBitmapAsPng(fileName, bmp);
   bmp.free;
end;

constructor TOSIndependentImage.create(width, height: integer);
begin
   inherited create;
   fBitmap := TBitmap.create;
   fBitmap.pixelFormat := pf8Bit;
   fBitmap.width := width;
   fBitmap.height := height;
end;

destructor TOSIndependentImage.destroy;
begin
   fBitmap.free;
   inherited destroy;
end;

function TOSIndependentImage.getCanvas: TCanvas;
begin
   result := fBitmap.canvas;
end;

function TOSIndependentImage.getWidth: integer;
begin
   result := fBitmap.width;
end;

function TOSIndependentImage.getHeight: integer;
begin
   result := fBitmap.height;
end;

procedure TOSIndependentImage.savePng(const fileName: string);
begin
   saveBitmapAsPng(fileName, fBitmap);
end;

{$ENDIF}

end.
