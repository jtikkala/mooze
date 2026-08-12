program precalculate;

const
  psize = 16;

var
  point  : array[0..psize,0..psize]of byte;
  i,j    : integer;
  f      : text;

begin
  assign(f,'bobe.inc');
  rewrite(f);
  write(f,'bobesize EQU ');
  writeln(f,psize);
  writeln(f,'BOBE label byte');
  for i:=0 to psize do begin
    writeln(F);
   for j:=0 to psize do begin
    write(f,'db ');
    writeln(f,trunc(15/(1+sqrt(sqr(i-psize shr 1)+sqr(j-psize shr 1)))) );
   end;
  end;
  close(f);
end.
