module Nekonote
    class PageCacheError < Error
        MSG_THERE_IS_DIRECTORY      = %(There is the unknown directory under the 'cache' directory.) 
        MSG_CHACHE_DIR_WRONG_PERMIT = %(Wrong permission or the cache directory '%s' was not found.)
    end
end
