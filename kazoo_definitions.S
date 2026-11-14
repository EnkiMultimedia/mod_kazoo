    .global kz_default_config
    .global kz_default_config_size
    .section .rodata
kz_default_config:
    .incbin "kazoo.conf.xml"
1:
kz_default_config_size:
    .int 1b - kz_default_config

#if defined(__ELF__)
/* no executable stack needed; without this note the linker marks the
   module as needing one and recent glibc refuses to dlopen it */
    .section .note.GNU-stack,"",%progbits
#endif
