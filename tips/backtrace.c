#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

void print_trace (void)
{
	const int size_max = 200;
	void *array[size_max];
	size_t size;
	char **strings;
	size_t i;

	size = backtrace (array, size_max);
	strings = backtrace_symbols (array, size);

	printf ("Obtained %zd stack frames.\n", size);

	for (i = 0; i < size; i++) {
		printf ("%s\n", strings[i]);
	}

	free (strings);
}

void dummy_function (void)
{
	print_trace ();
}

void dummy_function2 (void)
{
	dummy_function();
}

int main (void)
{
	dummy_function2();
	return 0;
}

