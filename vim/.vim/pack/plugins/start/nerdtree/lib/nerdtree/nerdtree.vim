"CLASS: NERDTree
"============================================================
let s:NERDTree = {}
let g:NERDTree = s:NERDTree

"FUNCTION: s:NERDTree.AddPathFilter() {{{1
function! s:NERDTree.AddPathFilter(callback)
    call add(s:NERDTree.PathFilters(), a:callback)
endfunction

"FUNCTION: s:NERDTree.changeRoot(node) {{{1
function! s:NERDTree.changeRoot(node)
    if a:node.path.isDirectory
        let self.root = a:node
    else
        call a:node.cacheParent()
        let self.root = a:node.parent
    endif

    call self.root.open()

    "change dir to the dir of the new root if instructed to
    if g:NERDTreeChDirMode >= 2
        call self.root.path.changeToDir()
    endif

    call self.render()
    call self.root.putCursorHere(0, 0)

    if exists('#User#NERDTreeNewRoot')
        doautocmd User NERDTreeNewRoot
    endif
endfunction

"FUNCTION: s:NERDTree.Close() {{{1
"Closes the tab tree window for this tab
function! s:NERDTree.Close()
    if !s:NERDTree.IsOpen()
        return
    endif

    if winnr('$') !=# 1
        " Use the window ID to identify the currently active window or fall
        " back on the buffer ID if win_getid/win_gotoid are not available, in
        " which case we'll focus an arbitrary window showing the buffer.
        let l:useWinId = exists('*win_getid') && exists('*win_gotoid')

        if winnr() ==# s:NERDTree.GetWinNum()
            call nerdtree#exec('wincmd p', 1)
            let l:activeBufOrWin = l:useWinId ? win_getid() : bufnr('')
            call nerdtree#exec('wincmd p', 1)
        else
            let l:activeBufOrWin = l:useWinId ? win_getid() : bufnr('')
        endif

        call nerdtree#exec(s:NERDTree.GetWinNum() . ' wincmd w', 1)
        call nerdtree#exec('close', 0)
        if l:useWinId
            call nerdtree#exec('call win_gotoid(' . l:activeBufOrWin . ')', 0)
        else
            call nerdtree#exec(bufwinnr(l:activeBufOrWin) . ' wincmd w', 0)
        endif
    else
        close
    endif
endfunction

"FUNCTION: s:NERDTree.CursorToBookmarkTable(){{{1
"Places the cursor at the top of the bookmarks table
function! s:NERDTree.CursorToBookmarkTable()
    if !b:NERDTree.ui.getShowBookmarks()
        throw 'NERDTree.IllegalOperationError: cant find bookmark table, bookmarks arent active'
    endif

    if g:NERDTreeMinimalUI
        return cursor(1, 2)
    endif

    let rootNodeLine = b:NERDTree.ui.getRootLineNum()

    let line = 1
    while getline(line) !~# '^>-\+Bookmarks-\+$'
        let line = line + 1
        if line >= rootNodeLine
            throw 'NERDTree.BookmarkTableNotFoundError: didnt find the bookmarks table'
        endif
    endwhile
    call cursor(line, 2)
endfunction

"FUNCTION: s:NERDTree.CursorToTreeWin(){{{1
"Places the cursor in the nerd tree window
function! s:NERDTree.CursorToTreeWin(...)
    call g:NERDTree.MustBeOpen()
    call nerdtree#exec(g:NERDTree.GetWinNum() . 'wincmd w', a:0 >0 ? a:1 : 1)
endfunction

" Function: s:NERDTree.ExistsForBuffer()   {{{1
" Returns 1 if a nerd tree root exists in the current buffer
function! s:NERDTree.ExistsForBuf()
    return exists('b:NERDTree')
endfunction

" Function: s:NERDTree.ExistsForTab()   {{{1
" Returns 1 if a nerd tree root exists in the current tab
function! s:NERDTree.ExistsForTab()
    if !exists('t:NERDTreeBufName')
        return
    end

    "check b:NERDTree is still there and hasn't been e.g. :bdeleted
    return !empty(getbufvar(bufnr(t:NERDTreeBufName), 'NERDTree'))
endfunction

function! s:NERDTree.ForCurrentBuf()
    if s:NERDTree.ExistsForBuf()
        return b:NERDTree
    else
        return {}
    endif
endfunction

"FUNCTION: s:NERDTree.ForCurrentTab() {{{1
function! s:NERDTree.ForCurrentTab()
    if !s:NERDTree.ExistsForTab()
        return
    endif

    let bufnr = bufnr(t:NERDTreeBufName)
    return getbufvar(bufnr, 'NERDTree')
endfunction

"FUNCTION: s:NERDTree.getRoot() {{{1
function! s:NERDTree.getRoot()
    return self.root
endfunction

"FUNCTION: s:NERDTree.GetWinNum() {{{1
"gets the nerd tree window number for this tab
function! s:NERDTree.GetWinNum()
    if exists('t:NERDTreeBufName')
        return bufwinnr(t:NERDTreeBufName)
    endif

    " If WindowTree, there is no t:NERDTreeBufName variable. Search all windows.
    for w in range(1,winnr('$'))
        if bufname(winbufnr(w)) =~# '^' . g:NERDTreeCreator.BufNamePrefix() . 'win_\d\+$'
            return w
        endif
    endfor

    return -1
endfunction

"FUNCTION: s:NERDTree.IsOpen() {{{1
function! s:NERDTree.IsOpen()
    return s:NERDTree.GetWinNum() !=# -1
endfunction

"FUNCTION: s:NERDTree.isTabTree() {{{1
function! s:NERDTree.isTabTree()
    return self._type ==# 'tab'
endfunction

"FUNCTION: s:NERDTree.isWinTree() {{{1
function! s:NERDTree.isWinTree()
    return self._type ==# 'window'
endfunction

"FUNCTION: s:NERDTree.MustBeOpen() {{{1
function! s:NERDTree.MustBeOpen()
    if !s:NERDTree.IsOpen()
        throw 'NERDTree.TreeNotOpen'
    endif
endfunction

"FUNCTION: s:NERDTree.New() {{{1
function! s:NERDTree.New(path, type)
    let newObj = copy(self)
    let newObj.ui = g:NERDTreeUI.New(newObj)
    let newObj.root = g:NERDTreeDirNode.New(a:path, newObj)
    let newObj._type = a:type
    return newObj
endfunction

"FUNCTION: s:NERDTree.PathFilters() {{{1
function! s:NERDTree.PathFilters()
    if !exists('s:NERDTree._PathFilters')
        let s:NERDTree._PathFilters = []
    endif
    return s:NERDTree._PathFilters
endfunction

"FUNCTION: s:NERDTree.previousBuf() {{{1
function! s:NERDTree.previousBuf()
    return self._previousBuf
endfunction

function! s:NERDTree.setPreviousBuf(bnum)
    let self._previousBuf = a:bnum
endfunction

"FUNCTION: s:NERDTree.render() {{{1
"A convenience function - since this is called often
function! s:NERDTree.render()
    call self.ui.render()
endfunction

" vim: set sw=4 sts=4 et fdm=marker:
