#include <ctype.h>
#include <stdio.h>

int main(void)
{
  FILE *debug = fopen(REPL,"wb");
  fprintf(debug,"0");
  fprintf(stderr,"native: Hello, world!\n");
  for (int c; (c = getchar()) != EOF; )
  {
    putchar(c);
    if (isgraph(c))
      fprintf(debug,"%c",c);
    else
      fprintf(debug,"0x%x",c);
  }
  fprintf(debug,"2");
  fclose(debug);
  return 0;
}
