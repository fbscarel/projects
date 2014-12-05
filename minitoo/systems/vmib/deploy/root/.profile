PS1='\u@\h \w \# '

xstat="$( ps auxw | grep 'xinit' | grep -v 'grep' | wc -l )"
[ "$xstat" -eq 0 ] && startx
