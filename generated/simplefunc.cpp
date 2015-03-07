#include <iostream>
#include <stdio.h>

int add (int a, int b) {
  return a + b;
}

int main () {
  int a = 5;
  int b = 10;
  int sum = add(a, b);
  printf("%i", sum);
}

