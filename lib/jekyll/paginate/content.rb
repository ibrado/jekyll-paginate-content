require "jekyll/paginate/content/version"

module Jekyll
  module Paginate::Content

    class Generator < Jekyll::Generator
      def generate(site)
        sconfig = site.config['paginate_content'] || {}

        return if !sconfig["enabled"]

        @debug = sconfig["debug"]

        collections = [ sconfig['collection'], sconfig["collections"] ].flatten.compact;
        collections = [ "posts", "pages" ] if collections.empty?

        @config = {
          :collections => collections,
          :auto => sconfig['auto'],
          :permalink => sconfig['permalink'] || '/:num/',
          :separator => sconfig['separator'] || '<!--page-->',
          :header => sconfig['header'] || '<!--page_header-->',
          :footer => sconfig['footer'] || '<!--page_footer-->',
          :single_page => sconfig['single_page'] || '/view-all/',
          :use_page => sconfig['use_page'].nil? || sconfig['use_page']
        }

        #p_ext = File.extname(permalink)
        #s_ext = File.extname(site.config['permalink'].gsub(':',''))
        #@default_ext = (p_ext.empty? ? nil : p_ext) || (s_ext.empty? ? nil : s_ext) || '.html'

        collections.each do |collection|
          if collection == "pages"
            items = site.pages
          else
            next if !site.collections.has_key?(collection)
            items = site.collections[collection].docs
          end

          new_items = []
          old_items = []

          total_parts = 0
          total_copies = 0

          process = @config[:auto] ?
            items.select { |item| item.content.include?(@config[:separator]) } :
            items.select { |item| item.data['paginate'] }

          process.each do |item|
            pager = Paginator.new(site, collection, item, @config)
            next if pager.items.empty?

            debug "[#{collection}] \"#{item.data['title']}\", #{pager.items.length-1}+1 pages"
            total_parts += pager.items.length-1;
            total_copies += 1
            new_items << pager.items
            old_items << item
          end

          if !new_items.empty?
            # Remove the old items at the original URLs
            old_items.each do |item|
              items.delete(item)
            end

            # Add the new items in
            new_items.flatten!.each do |new_item|
              items << new_item
            end

            info "[#{collection}] Generated #{total_parts}+#{total_copies} pages"
          end

        end
      end

      private
      def info(msg)
        Jekyll.logger.info "PaginateContent:", msg
      end

      def warn(msg)
        Jekyll.logger.warn "PaginateContent:", msg
      end

      def debug(msg)
        Jekyll.logger.warn "PaginateContent:", msg if @debug
      end
    end

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
        self.data['page_dir'] = dirname
      end
    end

    class Pager
      attr_accessor :activated, :first_page, :first_page_path,
        :first_path, :hidden, :is_first, :is_last, :last_page,
        :last_page_path, :last_path, :next_is_last, :next_page,
        :next_page_path, :next_path, :page, :page_num, :page_path,
        :pages, :paginated, :previous_is_first, :previous_page,
        :previous_page_path, :previous_path, :single_page, :total_pages
        :view_all

      def initialize(data)
        data.each do |k,v|
          instance_variable_set("@#{k}", v) if self.respond_to? k
        end
      end

      def to_liquid
        {
          'activated' => paginated,
          'first_page' => first_page,
          'first_page_path' => first_page_path,
          'first_path' => first_page_path,
          'hidden' => hidden,
          'is_first' => is_first,
          'is_last' => is_last,
          'last_page' => last_page,
          'last_page_path' => last_page_path,
          'last_path' => last_page_path,
          'next_is_last' => next_is_last,
          'next_page' => next_page,
          'next_page_path' => next_page_path,
          'next_path' => next_page_path,
          'page' => page_num,
          'page_num' => page_num,
          'page_path' => page_path,
          'pages' => pages,
          'paginated' => paginated,
          'previous_is_first' => previous_is_first,
          'previous_page' => previous_page,
          'previous_page_path' => previous_page_path,
          'previous_path' => previous_path,
          'single_page' => single_page,
          'total_pages' => total_pages,
          'view_all' => single_page
        }
      end
    end

    class Paginator
      def initialize(site, collection, item, config)
        @site = site
        @collection = collection
        @config = config

        @items = []
        self.split(item)
      end

      def items
        @items
      end

      def split(item)
        pages = item.content.split(@config[:separator])

        return if pages.length == 1

        page_header = pages[0].split(@config[:header])
        pages[0] = page_header[1] || page_header[0]
        header = page_header[1] ? page_header[0] : ''

        page_footer = pages[-1].split(@config[:footer])
        pages[-1] = page_footer[0]
        footer = page_footer[1] || ''

        new_items = []
        num = 1
        page_data = {}

        dirname = ""
        filename = ""

        pages.each do |page|
          plink_all = nil
          plink_next = nil
          plink_prev = nil

          pager_data = {}

          first = num == 1
          last = num == pages.length

          #base = item.url.gsub(/\/$/, '')
          base = item.url

          if m = base.match(/(.*\/[^\.]*)(\.[^\.]+)$/)
            # /.../filename.ext
            plink =  _permalink(m[1], num)
            plink_prev = _permalink(m[1], num-1) if !first
            plink_next = _permalink(m[1],num+1) if !last
            plink_all = m[1] + @config[:single_page]
          else
            # /.../folder/
            plink_all = base + @config[:single_page]
            plink = _permalink(base, num)
            plink_prev = _permalink(base, num-1) if !first
            plink_next = _permalink(base, num+1) if !last
          end

          plink_all.gsub!(/\/\//,'/')


          # TODO: Put these in classes

          if @collection == "pages"
            if first
              dirname = File.dirname(plink)
              filename = item.name
              page_data = item.data
            end

            pager_data.merge!(page_data)

            new_part = Page.new(item, @site, dirname, filename)

          else
            new_part = Document.new(item, @site, @collection)

          end

          new_part.data['permalink'] = plink

          if num > 1
            new_part.data['hidden'] = true
          end

          pager_data['paginated'] = true

          pager_data['page_num'] = num
          pager_data['page_path'] = _permalink(base, num)

          pager_data['first_page'] = 1
          new_part.data['first_page_path'] = pager_data['first_page_path'] = pager_data['first_path'] = base

          pager_data['last_page'] = pages.length
          pager_data['last_page_path'] = pager_data['last_path'] = _permalink(base, pages.length)

          new_part.data['total_pages'] = pager_data['total_pages'] = pages.length

          new_part.data['single_page'] = pager_data['single_page'] = plink_all
          new_part.data['view_all'] = pager_data['view_all'] = plink_all

          if first
            pager_data['is_first'] = true
          else
            pager_data['previous_page'] = num - 1
            pager_data['previous_page_path'] = pager_data['previous_path'] = plink_prev
          end

          if last
            pager_data['is_last'] = true
          else
            pager_data['next_page'] = num + 1
            pager_data['next_page_path'] = pager_data['next_path'] = plink_next
          end

          pager_data['previous_is_first'] = (num == 2)
          pager_data['next_is_last'] = (num == pages.length - 1)

          page_list = []
          i = 1
          while i <= pages.length do
            page_list << [i, _permalink(base, i)]
            i += 1
          end

          if @config[:use_page]
            new_part.data['pages'] = page_list
            new_part.data.merge!(pager_data)
          else
            pager_data['pages'] = page_list
            new_part.pager = Pager.new(pager_data)
          end

          new_part.content = header + page + footer

          new_items << new_part

          num += 1
        end

        if @collection == "pages"
          copy = Page.new(item, @site, new_items[0].data['page_dir'], item.name)
        else
          copy = Document.new(item, @site, @collection)
        end

        copy_data = {
          'first_page_path' => new_items[0].data['first_page_path'],
          'total_pages' => new_items[0].data['total_pages'],
        }
        copy_data['first_path'] = copy_data['first_page_path']

        if @config[:use_page]
          copy.data.merge!(copy_data)
        else
          copy.pager = Pager.new(copy_data)
        end

        copy.data['permalink'] = new_items[0].data['single_page']
        copy.data['hidden'] = true

        copy.content = item.content

        new_items << copy

        @items = new_items
      end

      private
      def _permalink(base, page)
        return base if page == 1
        (base+@config[:permalink]).gsub(/:num/, page.to_s).gsub(/\/\//, '/')
      end
    end
  end
end
