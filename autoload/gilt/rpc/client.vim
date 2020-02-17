function! gilt#rpc#client#connect(port) abort
  return s:connect(a:port, { -> 0 })
endfunction


if has('nvim')
  function! s:connect(port, callback) abort
    let ch = sockconnect('tcp', '127.0.0.1:' . a:port, {
          \ 'on_data': a:callback,
          \})
    return {
          \ 'send': function('chansend', [ch]),
          \ 'close': function('chanclose', [ch]),
          \}
  endfunction
else
  function! s:connect(port, callback) abort
    let ch = ch_open('127.0.0.1:' . a:port, {
          \ 'mode': 'raw',
          \ 'callback': funcref('s:vim_on_receive', [a:callback]),
          \})
    return {
          \ 'send': funcref('s:vim_send', [ch]),
          \ 'close': function('ch_close', [ch]),
          \}
  endfunction

  function! s:vim_send(ch, data) abort
    return ch_sendraw(a:ch, join(a:data, "\n"))
  endfunction

  function! s:vim_on_receive(callback, data) abort
    call a:callback(split(a:data, '\n'))
  endfunction
endif
