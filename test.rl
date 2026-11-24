#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>

static unsigned long ilog10(int x);

#define SLURP(S) { status = (S); goto slurp; } (void)0

#define PUT if (fputc(by,fi) != EOF) by = 0; else SLURP(531008 + quant)

%%{
  machine protocol;
  alphtype unsigned char;

  action set_mode
  {
    *mode = fc;
  }

  action cp
  {
    if (f >= f + sizeof path - 5)
      SLURP(13000);
    *f = fc;
    *++f = '\0';
  }

  action open
  {
    if (!(fi = fopen(path,mode)))
      SLURP(69000);
  }

  action decode
  {
    do {
      unsigned char v;

      if (isupper(fc))
        v = c - 'A';
      else if (islower(fc))
        v = c - 'a' + 26;
      else if (isdigit(fc))
        v = c - '0' + 52;
      else if ('+' == fc || '-' == fc)
        v = 62;
      else if ('/' == fc || '_' == fc)
        v = 63;
      else if ('=' == fc && 1 == quant)
      {
        quant++;
        break;
      }
      else if ('=' == fc && 2 == quant)
      {
        quant++;
        break;
      }
      else
        assert(!"impossile");

      switch (quant = (quant + 1) % 4)
      {
        case 0:
          by = (v << 2u);
        break;
        case 1:
          by |= (v >> 4u);
          PUT;
          by = ((v << 4u) & 0xFFu);
        break;
        case 2:
          by |= (v >> 2u);
          PUT;
          by = ((v << 6u) & 0xFFu);
        break;
        case 3:
          by |= v;
          PUT;
        break;
        default:
          assert(!"imp");
        break;
      }
    } while (0);
  }

  u = alnum | [+/_] | "-";

          #  0  | 16  | 32  | 48
  remain2 = "A" | "Q" | "g" | "w";
  remain3 = "A" | "E" | "I" | "M" | "Q" | "U" | "Y" | "c" | "g" | "k" | "o" | "s" | "w" | "0" | "4" | "8";
          #  0  |  4  |  8  | 12  | 16  | 20  | 24  | 28  | 32  | 36  | 40  | 44  | 48  | 52  | 56  | 60

  base64gen = u{4}* (u remain2 "=="{,2} | u{2} remain3 "="?)?;

  base64    = base64gen -- ("-" | "_");
  base64url = base64gen -- [+/];

  file = ((base64url -- "=") "." [^/,]*) - "..";

  action error { SLURP(fcurs); } 

  message = "\"" [aw] @set_mode file $cp %open "," base64gen $decode "\"";

  main := message $!error;
}%%

int main(void)
{
  unsigned long length = 1;
  unsigned char *b = (unsigned char *)&length;
  b += (1 == *b) ? 0 : (sizeof (length) - 4);

  again:

  if (fread(b,1,4,stdin) < 4)
    return 0;

  int status = 0;

  int cs;
  #define PATH "/home/pebolim/Downloads/Ingrid/"
  char path[1000] = PATH;
  char *f = path + (sizeof PATH) - 1;
  FILE *fi = NULL;
  char mode[3] = "?b";
  int quant = 3;
  unsigned char by = 0;
  unsigned long i = 0;

  %% write data noerror nofinal noentry;
  %% write init;

  for (int c; i < length; i++)
  {
    if (EOF == (c = getchar()))
      return 67;
    unsigned char  a  = c,
                  *p  = &a,
                  *pe = p+1,
                 *eof = (i < length - 1 ? NULL : pe);
    %% write exec;
  }

  if (1 == quant)
    SLURP(42);

  slurp:

  if (fi)
  {
    fclose(fi);
    fi = NULL;
  }

  for (; i < length; i++)
    (void)getchar();

  length = ilog10(status);

  if (fwrite(b,1,4,stdout) < 4)
    return 33;
  if (printf("%d", status) < 0)
    return 34;
  if (EOF == fflush(stdout))
    return 35;

  goto again;
}

static unsigned long ilog10(int x)
{
  int len = 0;
  if (x < 0)
  {
    x = -x;
    len++;
  }
  if (0 == x)
    len = 1;
  else while (x > 0)
  {
    len++;
    x /= 10;
  }
  return len;
}
