module Jekyll
  module Paginate::Content

    module Generator::Cache
      @cache = {}

      def self.items(site, item, items = nil)
        return if !item.respond_to?('path')

        prefix = item.is_a?(Jekyll::Page) ? site.source : ''
        source = File.join(prefix, item.path)
        dest = item.destination(site.dest)

        if !@cache[source]
          @cache[source] = items

        elsif !File.exists?(dest) || (File.mtime(source) > File.mtime(dest))
          @cache.delete(source)
          return

        else
          return @cache[source]
        end
      end
    end

  end
end
