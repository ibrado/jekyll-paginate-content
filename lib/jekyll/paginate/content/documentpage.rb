module Jekyll
  module Paginate::Content

    class Document < Jekyll::Document
      attr_accessor :pager

      def initialize(orig_doc, site, collection)
        super(orig_doc.path, { :site => site,
              :collection => site.collections[collection]})
        self.merge_data!(orig_doc.data)
      end

      def data
        @data ||= {}
      end

    end

    class Page < Jekyll::Page
      def initialize(orig_page, site, dirname, filename)
        @site = site
        @base = site.source
        @dir = dirname
        @name = filename

        self.process(filename)
        self.data ||= {}
        self.data.merge!(orig_page.data)
      end
    end

  end
end
