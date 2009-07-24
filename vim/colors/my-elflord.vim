" {{{1  header

" Forked from "elflord":
" Maintainer:	Ron Aaron <ron@ronware.org>
" Last Change:	2003 May 02

set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif


" {{{1  my

runtime colors/elflord.vim

let g:colors_name = "my-elflord"

hi TabLineSel    ctermfg=DarkGray  ctermbg=DarkCyan
hi TabLine       ctermfg=Cyan      ctermbg=DarkGray
hi TabLineFill   ctermfg=Black  ctermbg=none

hi StatusLineNC  ctermfg=DarkGray  ctermbg=Cyan
hi StatusLine    ctermfg=Cyan      ctermbg=DarkGray

hi Cursor        term=underline
hi CursorLine    term=underline
hi CursorColumn	 term=underline

hi LineNr ctermfg=DarkRed
hi Folded ctermfg=blue cterm=bold
hi Comment  ctermfg=darkgray  guifg=#80a0ff

hi Search ctermbg=green ctermfg=yellow guibg=#b000b0


" {{{1 reference

" {{{2 grupos
" 
" *group-name* *{group-name}* *E669* *W18*
" 
" 	*Comment	any comment
" 
" 	*Constant	any constant
" 	 String		a string constant: "this is a string"
" 	 Character	a character constant: 'c', '\n'
" 	 Number		a number constant: 234, 0xff
" 	 Boolean	a boolean constant: TRUE, false
" 	 Float		a floating point constant: 2.3e10
" 
" 	*Identifier	any variable name
" 	 Function	function name (also: methods for classes)
" 
" 	*Statement	any statement
" 	 Conditional	if, then, else, endif, switch, etc.
" 	 Repeat		for, do, while, etc.
" 	 Label		case, default, etc.
" 	 Operator	"sizeof", "+", "*", etc.
" 	 Keyword	any other keyword
" 	 Exception	try, catch, throw
" 
" 	*PreProc	generic Preprocessor
" 	 Include	preprocessor #include
" 	 Define		preprocessor #define
" 	 Macro		same as Define
" 	 PreCondit	preprocessor #if, #else, #endif, etc.
" 
" 	*Type		int, long, char, etc.
" 	 StorageClass	static, register, volatile, etc.
" 	 Structure	struct, union, enum, etc.
" 	 Typedef	A typedef
" 
" 	*Special	any special symbol
" 	 SpecialChar	special character in a constant
" 	 Tag		you can use CTRL-] on this
" 	 Delimiter	character that needs attention
" 	 SpecialComment	special things inside a comment
" 	 Debug		debugging statements
" 
" 	*Underlined	text that stands out, HTML links
" 
" 	*Ignore		left blank, hidden
" 
" 	*Error		any erroneous construct
" 
" 	*Todo		anything that needs extra attention; mostly the
" 			keywords TODO FIXME and XXX
" 
" {{{2  colors
" 
" 	    Red		LightRed	DarkRed
" 	    Green	LightGreen	DarkGreen	SeaGreen
" 	    Blue	LightBlue	DarkBlue	SlateBlue
" 	    Cyan	LightCyan	DarkCyan
" 	    Magenta	LightMagenta	DarkMagenta
" 	    Yellow	LightYellow	Brown		DarkYellow
" 	    Gray	LightGray	DarkGray
" 	    Black	White
" 	    Orange	Purple		Violet
" 
" {{{2  elements
" 
" Cursor		the character under the cursor
" CursorIM	like Cursor, but used when in IME mode |CursorIM|
" CursorColumn	the screen column that the cursor is in when 'cursorcolumn' is set
" CursorLine	the screen line that the cursor is in when 'cursorline' is set
" Directory	directory names (and other special names in listings)
" DiffAdd		diff mode: Added line |diff.txt|
" DiffChange	diff mode: Changed line |diff.txt|
" DiffDelete	diff mode: Deleted line |diff.txt|
" DiffText	diff mode: Changed text within a changed line |diff.txt|
" ErrorMsg	error messages on the command line
" VertSplit	the column separating vertically split windows
" Folded		line used for closed folds
" FoldColumn	'foldcolumn'
" SignColumn	column where |signs| are displayed
" IncSearch	'incsearch' highlighting; also used for the text replaced with ":s///c"
" LineNr		Line number for ":number" and ":#" commands, and when 'number' option is set.
" MatchParen	The character under the cursor or just before it, if it is a paired bracket, and its match. |pi_paren.txt|
" ModeMsg		'showmode' message (e.g., "-- INSERT --")
" MoreMsg		|more-prompt|
" NonText		'~' and '@' at the end of the window, and other characters that do not really exist in the text
" Normal		normal text
" Pmenu		Popup menu: normal item.
" PmenuSel	Popup menu: selected item.
" PmenuSbar	Popup menu: scrollbar.
" PmenuThumb	Popup menu: Thumb of the scrollbar.
" Question	|hit-enter| prompt and yes/no questions
" Search		Last search pattern highlighting (see 'hlsearch').  Also used for highlighting the current line in the quickfix window and similar items that need to stand out.
" SpecialKey	text that is displayed differently from what it really is (special keys in ":map", unprintable characters, 'listchars'.
" SpellBad	Word that is not recognized by the spellchecker.
" SpellCap	Word that should start with a capital.
" SpellLocal	Word that is recognized by the spellchecker as one that is used in another region. |spell|
" SpellRare	Word that is recognized by the spellchecker as one that is hardly ever used. |spell|
" StatusLine	status line of current window
" StatusLineNC	status lines of not-current windows
" TabLine		tab pages line, not active tab page label
" TabLineFill	tab pages line, where there are no labels
" TabLineSel	tab pages line, active tab page label
" Title		titles for output from ":set all", ":autocmd" etc.
" Visual		Visual mode selection
" VisualNOS	Visual mode selection when vim is "Not Owning the Selection".
" WarningMsg	warning messages
" WildMenu	current match in 'wildmenu' completion
" 
" 2}}}

" }}}
" vim: set fdm=marker:%foldc!:
