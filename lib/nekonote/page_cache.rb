module Nekonote
    class PageCache
        include Singleton
        CACHE_DIR = 'cache'

        def initialize
            @cache_path = Nekonote.get_root_path + CACHE_DIR

            # check the accessibility
            if !Util::Filer.available_dir? @cache_path
                raise PageCacheError, PageCacheError::MSG_CHACHE_DIR_WRONG_PERMIT% @cache_path
            end
        end

        # @return bool
        public
        def cache_clear
            files = Dir.glob("#{@cache_path}/*")
            if files.size > 0
                deleted = true
            else
                deleted = false
            end

            begin
                files.each do |full_path|
                    File.delete full_path
                end
            rescue Errno::EISDIR
                raise PageCacheError, PageCacheError::MSG_THERE_IS_DIRECTORY
            end

            return deleted
        end

        # Makes a cache file newly.
        # The cache files will be created under 'cache' directory and its filename is SHA-256 hash value.
        # @param string uri
        # @param int code
        # @param hash header
        # @param array body
        public
        def make_cache(uri, code, header, body)
            created_at = Time.now.to_i
            data = {
                :code   => code,
                :header => header,
                :body   => body
            }
            data = [code, header, body]
            serialized_data = Marshal.dump data

            # create new page cache file, delete it if it already exists
            File.open(get_cache_file_path(uri), File::RDWR|File::CREAT|File::TRUNC) do |f|
                f.flock File::LOCK_EX
                f.puts created_at
                f.print serialized_data
                f.flock File::LOCK_UN
            end
        end

        # @param string uri
        # array
        public
        def get_page_cache(uri)
            response_data = []
            File.open(get_cache_file_path(uri), 'r') do |f|
                f.flock File::LOCK_SH
                f.readline
                response_data = Marshal.load(f.read)
                f.flock File::LOCK_UN
            end
            return response_data
        end

        # Returns true if cache file exists and its valid time hasn't passed.
        # @param string uri
        # @param int page_cache_time
        # @return bool
        public
        def has_available_cache?(uri, page_cache_time)
            path = get_cache_file_path uri
            # check cache file exists?
            return false if !Util::Filer.available_file? path

            # check expiration
            latest_access = 0
            File.open(get_cache_file_path(uri), 'r') do |f|
                f.flock File::LOCK_SH
                latest_access = f.readline.strip.to_i
                f.flock File::LOCK_UN
            end
            sec_passed = Time.now.to_i - latest_access # passed sec

            # return false if page_cache_time has passed
            if page_cache_time < sec_passed
                return false
            end

            # availale
            return true
        end

        # @param string uri
        # @return string SHA-256 hash value
        public
        def get_cache_file_path(uri)
            return "#{@cache_path}/#{Digest::SHA256.hexdigest(uri)}"
        end
    end
end
