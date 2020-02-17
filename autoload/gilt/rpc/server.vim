let s:Job = vital#gilt#import('System.Job')
let s:is_windows = has('win32')

if !exists('s:server')
  let s:server = v:null
endif


function! gilt#rpc#server#is_running() abort
  return s:server isnot# v:null && s:server.status() ==# 'run'
endfunction

function! gilt#rpc#server#start(...) abort
  if gilt#rpc#server#is_running()
    return
  endif
  let options = extend({
        \ 'port': 51515,
        \}, a:0 ? a:1 : {},
        \)
  let s:server = s:listen(options.port . '', {
        \ 'options': options,
        \ 'stdout': [''],
        \ 'stderr': [''],
        \ 'on_stdout': function('s:on_stdout'),
        \ 'on_stderr': function('s:on_stderr'),
        \ 'on_exit': function('s:on_exit'),
        \})
  augroup gilt_rpc_server_internal
    autocmd! *
    autocmd VimLeave * call gilt#rpc#server#stop()
  augroup END
endfunction

function! gilt#rpc#server#stop() abort
  if !gilt#rpc#server#is_running()
    return
  endif
  let server = s:server
  let s:server = v:null
  call server.stop()
endfunction

function! s:on_stdout(data) abort dict
  let self.stdout[-1] .= a:data[0]
  call extend(self.stdout, a:data[1:])
  if len(self.stdout) <= 1
    return
  endif
  call map(
        \ remove(self.stdout, 0, -2),
        \ function('gilt#rpc#executor#execute'),
        \)
endfunction

function! s:on_stderr(data) abort dict
  let self.stderr[-1] .= a:data[0]
  call extend(self.stderr, a:data[1:])
endfunction

function! s:on_exit(exitval) abort dict
  if !v:dying && a:exitval is# 0 && s:server isnot# v:null
    call gilt#rpc#server#start(self.options)
  else
    echohl Error
    for line in self.stderr
      echomsg line
    endfor
    echohl None
  endif
endfunction

if executable('nc')
  function! s:listen(port, options) abort
    let args = ['nc', '-l', '127.0.0.1', a:port]
    return s:Job.start(args, a:options)
  endfunction
elseif executable('powershell') || executable('pwsh')
  let s:script = fnamemodify(expand('<sfile>'), ':p:r') . '.ps1'
  let s:pwsh = executable('powershell') ? 'powershell' : 'pwsh'
  function! s:listen(port, options) abort
    let args = [
          \ s:pwsh,
          \ '-ExecutionPolicy', 'Bypass',
          \ s:script,
          \ a:port,
          \]
    return s:Job.start(args, a:options)
  endfunction
else
  function! s:listen(port, options) abort
    throw 'gilt: nc (netcat) or PowerShell is required'
  endfunction
endif
