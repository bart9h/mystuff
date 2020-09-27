#!/bin/sh
layout() {
	i3-msg 'exec mate-terminal'
	sleep .2
	i3-msg 'exec mate-terminal'
	sleep .2
	i3-msg 'resize grow width 20 px or 20 ppt'
	i3-msg 'split v'
	i3-msg 'focus left'
	i3-msg 'split v'
	i3-msg 'focus right'
	i3-msg 'layout tabbed'
}

layout
#i3-msg workspace 2
#layout
#i3-msg workspace 3
#layout
#i3-msg workspace 1
