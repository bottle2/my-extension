#include <stdio.h>

#define TEST(S) if (EOF == (c = getchar())) return (S); else
#define HEADER_(I,S) TEST(S) b[I] = c; putchar(c)
#define HEADER(I) HEADER_(I,1)

int main(void)
{
  unsigned long length = 1;
  unsigned char *b = (unsigned char *)&length;
  b += (1 == *b) ? 0 : (sizeof (length) - 4);
  int c;

  again:

  HEADER_(0,0);
  HEADER(1);
  HEADER(2);
  HEADER(3);

  for (; length > 0; length--)
    TEST(1) putchar(c);

  fflush(stdout);

  goto again;
}
