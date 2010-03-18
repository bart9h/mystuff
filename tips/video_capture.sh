res=`show res`
fps=25
ffmpeg -f x11grab -s $res -r $fps -i :0.0 -sameq /tmp/out.mpg
