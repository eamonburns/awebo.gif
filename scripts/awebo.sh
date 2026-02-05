#!/usr/bin/bash

# The initial script for the animation.

frames=\
"  0;/ôô>
 0.5;/ôô>
 0.3;/ôô=
0.03;/ôô< awebo
 0.4;/ôô=
0.03;/ôô>
 0.9;/ôô=
0.03;/ôô< Awebo
 0.4;/ōō=
0.03;/ŏŏ>
 1.2;/ŏŏ=
0.03;/ŏŏ< AWEBO!!
 0.7;/ŏŏ=
0.03;/ŏŏ>
   1;/ōō>
0.03;/ôô>"

printf "\ec"
printf "\e[?25l"
echo

echo "$frames" | while IFS=";" read -r time text; do
    sleep "$time"
    printf "\r  %s\e[J" "$text"
done
sleep "1"
printf "\ec"

printf "\e[?25h"
