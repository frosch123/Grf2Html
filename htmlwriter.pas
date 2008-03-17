unit htmlwriter;

interface

function printLinkBegin(const srcFrame, dstFrame: string; dest: string): string;

implementation

function printLinkBegin(const srcFrame, dstFrame: string; dest: string): string;
var
   target                               : string;
begin
   if srcFrame <> dstFrame then target := ' target="' + dstFrame + '"' else
   begin
      target := '';
      delete(dest, 1, pos('#', dest) - 1);
   end;
   result := '<a href="' + dest + '"' + target + '>';
end;

end.
