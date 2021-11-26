function s:complete(_a, _b, _c)
    return ['fzf', 'fzy', 'skim', 'telescope']
endfunction

command -nargs=0 -range=% Godbolt lua require("godbolt").godbolt(<line1>, <line2>)
command -nargs=1 -range=% -complete=customlist,s:complete GodboltCompiler lua require("godbolt").godbolt(<line1>, <line2>, <f-args>)
