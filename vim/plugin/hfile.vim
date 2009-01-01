
function! s:hfile()
	let file = expand("%:t")

	let macro = substitute(file, '\.', "_", "g")

	exe ("normal a#ifndef " . macro . "_included\r")
	exe ("normal a#define " . macro . "_included\r")
	exe ("normal a\r\r\r#endif")
	normal kk

endfunction

autocmd! BufNewFile *.h nested call s:hfile()
autocmd! BufNewFile *.hpp nested call s:hfile()

