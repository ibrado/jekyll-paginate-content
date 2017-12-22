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
          :title => sconfig['title'],
          :permalink => sconfig['permalink'] || '/:num/',
          :trail => sconfig['trail'],

          :auto => sconfig['auto'],
          :separator => sconfig['separator'] || '<!--page-->',
          :header => sconfig['header'] || '<!--page_header-->',
          :footer => sconfig['footer'] || '<!--page_footer-->',
          :single_page => sconfig['single_page'] || '/view-all/',
          :seo_canonical => !sconfig['seo_canonical'].nil? || sconfig['seo_canonical'],
          :use_page => !sconfig['use_page'].nil? || sconfig['use_page']
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
        :first_path, :has_next, :has_previous, 
        :is_first, :is_last, :last_page, :last_page_path, :last_path,
        :next_is_last, :next_page, :next_page_path, :next_path,
        :page_trail, :page_num, :page_path, :pages, :paginated,
        :previous_is_first, :previous_page, :previous_page_path,
        :previous_path, :single_page, :seo, :total_pages, :view_all

      def initialize(data)
        data.each do |k,v|
          instance_variable_set("@#{k}", v) if self.respond_to? k
        end
      end

      def to_liquid
        {
          'pages' => pages,
          'total_pages' => total_pages,
          'page' => page_num,
          'page_path' => page_path,
          'previous_page' => previous_page,
          'previous_page_path' => previous_page_path,
          'next_page' => next_page,
          'next_page_path' => next_page_path,
          'first_page' => first_page,
          'first_page_path' => first_page_path,
          'last_page' => last_page,
          'last_page_path' => last_page_path,
          'page_trail' => page_trail,

          'page_num' => page_num,
          'first_path' => first_page_path,
          'next_path' => next_page_path,
          'previous_path' => previous_path,
          'last_path' => last_page_path,

          'activated' => paginated,

          'has_next' => has_next,
          'has_previous' => has_previous,
          'is_first' => is_first,
          'is_last' => is_last,
          'next_is_last' => next_is_last,
          'previous_is_first' => previous_is_first,
          'paginated' => paginated,

          'seo' => seo,
          'single_page' => single_page,
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

        site_url = @site.config['canonical'] || @site.config['url']
        site_url.gsub!(/\/$/, '')

        pages.each do |page|
          plink_all = nil
          plink_next = nil
          plink_prev = nil
          seo = ""

          paginator = {}

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

            paginator.merge!(page_data)

            new_part = Page.new(item, @site, dirname, filename)

          else
            new_part = Document.new(item, @site, @collection)

          end

          new_part.data['permalink'] = plink

          if num > 1
            new_part.data['hidden'] = true
          end

          paginator['paginated'] = true

          paginator['page_num'] = num
          paginator['page_path'] = _permalink(base, num)

          paginator['first_page'] = 1
          paginator['first_page_path'] = paginator['first_path'] = base

          paginator['last_page'] = pages.length
          paginator['last_page_path'] = _permalink(base, pages.length)

          paginator['total_pages'] = pages.length

          paginator['single_page'] = plink_all
          paginator['view_all'] = plink_all

          if first
            paginator['is_first'] = true
          else
            paginator['previous_page'] = num - 1
            paginator['previous_page_path'] = paginator['previous_path'] = plink_prev
          end

          if last
            paginator['is_last'] = true
          else
            paginator['next_page'] = num + 1
            paginator['next_page_path'] = plink_next
          end

          paginator['previous_is_first'] = (num == 2)
          paginator['next_is_last'] = (num == pages.length - 1)

          paginator['has_previous'] = (num >= 2)
          paginator['has_next'] = (num < pages.length)

          page_trail = []
          i = 1
          while i <= pages.length do
            page_trail << [i, _permalink(base, i)]
            i += 1
          end
          paginator['page_trail'] = page_trail

          seo += _seo('canonical', site_url + plink_all, @config[:seo_canonical])
          seo += _seo('prev', site_url + plink_prev) if plink_prev
          seo += _seo('next', site_url + plink_next) if plink_next
          paginator['seo'] = seo


          new_part.pager = Pager.new(paginator)
          new_part.content = header + page + footer

          new_items << new_part

          num += 1
        end

        # Exclude the clone of the original since basically a move
        paginator['pages'] = new_items

        if @collection == "pages"
          clone = Page.new(item, @site, new_items[0].data['page_dir'], item.name)
        else
          clone = Document.new(item, @site, @collection)
        end

        clone.data['hidden'] = true

        permalink = new_items[0].data['single_page']
        clone.data['permalink'] = permalink

        clone_paginator = {
          'first_page_path' => new_items[0].data['first_page_path'],
          'total_pages' => new_items[0].data['total_pages']
        }

        clone_paginator['seo'] = _seo('canonical',
          site_url + permalink, @config[:seo_canonical])

        clone.pager = Pager.new(clone_paginator)

        clone.content = item.content

        new_items << clone

        @items = new_items
      end

      private
      def _seo(type, url, condition = true)
        condition ? "  <link rel=\"#{type}\" href=\"#{url}\" />\n" : ""
      end

      def _permalink(base, page)
        return base if page == 1
        (base+@config[:permalink]).gsub(/:num/, page.to_s).gsub(/\/\//, '/')
      end
    end
  end
end
