#include <stdio.h>

const char *openblas_get_config(void);

int main(void) {
    const char *config = openblas_get_config();
    if (config == NULL || config[0] == '\0') {
        return 1;
    }
    puts(config);
    return 0;
}
