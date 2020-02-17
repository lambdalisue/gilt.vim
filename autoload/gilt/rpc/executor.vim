function! gilt#rpc#executor#execute(expr) abort
  try
    " XXX: Limit expr
    execute a:expr
  catch
    echohl Error
    echomsg printf("gilt: failed to execute '%s'", a:expr)
    echomsg v:exception
    echohl None
  endtry
endfunction
