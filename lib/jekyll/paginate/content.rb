require "jekyll/paginate/content/version"

module Jekyll
  module Paginate::Content

    class Generator < Jekyll::Generator
      safe true

      def generate(site)
        start_time = Time.now

        sconfig = site.config['paginate_content'] || {}

        return unless sconfig["enabled"].nil? || sconfig["enabled"]

        @debug = sconfig["debug"]

        sconfig['collection'] = sconfig['collection'].split(/,\s*/) if sconfig['collection'].is_a?(String)

        collections = [ sconfig['collection'], sconfig["collections"] ].flatten.compact.uniq;
        collections = [ "posts", "pages" ] if collections.empty?

        # Use this hash syntax to facilite merging _config.yml overrides
        properties = {
          'all' => {
            'autogen' => 'jekyll-paginate-content',
            'hidden' => true,
            'tag' => nil,
            'tags' => nil,
            'category' => nil,
            'categories'=> nil
          },

          'first' => {
            'hidden' => false,
            'tag' => '$',
            'tags' => '$',
            'category' => '$',
            'categories'=> '$'
          },

          'part' => {},

          'last' => {},

          'single' => {}
        }

        base_url = (sconfig['prepend_baseurl'].nil? || sconfig['prepend_baseurl']) ? site.config['baseurl'] : ''

        @config = {
          :collections => collections,
          :title => sconfig['title'],
          :permalink => sconfig['permalink'] || '/:num/',
          :trail => sconfig['trail'] || {},
          :auto => sconfig['auto'],
          :base_url => base_url,

          :separator => sconfig['separator'] || '<!--page-->',
          :header => sconfig['header'] || '<!--page_header-->',
          :footer => sconfig['footer'] || '<!--page_footer-->',

          :single_page => sconfig['single_page'] || '/view-all/',
          :seo_canonical => sconfig['seo_canonical'].nil? || sconfig['seo_canonical'],
          :toc_exclude => sconfig['toc_exclude'],

          :properties => properties,
          :user_props => sconfig['properties'] || {}
        }

        # Run through each specified collection

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

          if @config[:auto]
            if m = /^h(\d)/i.match(@config[:separator])
              process = items.select { |item| /(\n|)(<h#{m[1]}|-{4,}|={4,})/.match?(item.content) }
            else
              process = items.select { |item| item.content.include?(@config[:separator]) }
            end
          else
            process = items.select { |item| item.data['paginate'] }
          end

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
        runtime = "%.6f" % (Time.now - start_time).to_f
        debug "Runtime: #{runtime}s"
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
      end
    end

    class Pager
      attr_accessor :activated, :first_page, :first_page_path,
        :first_path, :has_next, :has_prev, :has_previous,
        :is_first, :is_last, :last_page, :last_page_path,
        :last_path, :next_is_last, :next_page, :next_page_path,
        :next_path, :next_section, :page, :page_num, :page_path,
        :page_trail, :pages, :paginated, :previous_is_first,
        :prev_is_first, :previous_page, :prev_page, :previous_page_path,
        :previous_path, :prev_path, :prev_section, :previous_section,
        :section, :seo, :single_page, :toc, :total_pages, :view_all

      def initialize(data)
        data.each do |k,v|
          instance_variable_set("@#{k}", v) if self.respond_to? k
        end
      end

      def to_liquid
        {
          # Based on sverrir's jpv2
          'first_page' => first_page,
          'first_page_path' => first_page_path,
          'last_page' => last_page,
          'last_page_path' => last_page_path,
          'next_page' => next_page,
          'next_page_path' => next_page_path,
          'page' => page_num,
          'page_path' => page_path,
          'page_trail' => page_trail,
          'previous_page' => previous_page,
          'previous_page_path' => previous_page_path,
          'total_pages' => total_pages, # parts of the original page

          # New stuff
          'has_next' => has_next,
          'has_previous' => has_previous,
          'is_first' => is_first,
          'is_last' => is_last,
          'next_is_last' => next_is_last,
          'previous_is_first' => previous_is_first,
          'paginated' => paginated,
          'seo' => seo,
          'single_page' => single_page,
          'section' => section,
          'toc' => toc,
          'next_section' => next_section,
          'previous_section' => previous_section,

          # Aliases
          'activated' => paginated,
          'first_path' => first_page_path,
          'next_path' => next_page_path,
          'has_prev' => has_previous,
          'previous_path' => previous_page_path,
          'prev_path' => previous_page_path,
          'last_path' => last_page_path,
          'prev_page' => previous_page,
          'prev_is_first' => previous_is_first,
          'prev_section' => previous_section,
          'page_num' => page_num,
          'pages' => total_pages,
          'view_all' => single_page
        }
      end
    end

    class Paginator
      def initialize(site, collection, item, config)
        @site = site
        @collection = collection

        final_config = {}.merge(config)
        if item.data.has_key?('paginate_content')
          item.data['paginate_content'].each do |k,v|
            s = k.downcase.strip.to_sym
            final_config[s] = v
          end
        end

        @config = final_config

        @items = []
        self.split(item)
      end

      def items
        @items
      end

      def split(item)
        sep = @config[:separator].downcase.strip

        # Update the header IDs the original document
        content = item.content

        # Escape special characters inside code blocks
        content.scan(/(```|~~~+)(.*?)\1/m).each do |e|
          escaped = e[1].gsub(/([#<\-=])/, '~|\1|')
          content.gsub!(e[1], escaped)
        end

        # Generate TOC
        toc = ""

        seen_anchors = {}
        list_chars = ['-','*','+']

        if m = /^h([1-6])$/.match(sep)
          base_level = m[1].to_i - 1
        else
          base_level = 5
        end

        lowest_level = 5

        # TODO: Optimize this regex
        content.scan(/(^|\r?\n)((#+)\s*([^\r\n#]+)#*\r?\n|([^\r\n]+)\r?\n(=+|\-{4,})\s*\r?\n|<h([1-6])[^>]*>([^\r\n<]+)(\s*<\/h\7>))/mi).each do |m|
          header = m[3] || m[4] || m[7]

          next if @config[:toc_exclude] && @config[:toc_exclude].include?(header)

          markup = m[1].strip

          # Level is 0-based for convenience
          if m[3]
            level = m[2].length - 1
          elsif m[4]
            level = m[5][0] == '=' ? 0 : 1
          elsif m[7]
            level = m[6].to_i - 1
          end

          lowest_level = [level, lowest_level].min

          orig_anchor = anchor = header.downcase.gsub(/[[:punct:]]/, '').gsub(/\s+/, '-')

          ctr = 1
          while seen_anchors[anchor]
            anchor = "#{orig_anchor}-#{ctr}"
            ctr += 1
          end
          seen_anchors[anchor] = 1

          # Escape the header so we don't match again
          #  for the same header text in a different location
          escaped = Regexp.escape(markup)
          markup = "$$_#{markup}_$$"

          content.sub!(/#{escaped}\s*(?=#|\r?\n)/, "#{markup}#{$/}{: id=\"#{anchor}\"}#{$/}")

          # Markdown indent
          char = list_chars[level % 3]
          indent = '  ' * level
          toc << "#{indent}#{char} [#{header}](##{anchor})#{$/}"
        end

        if lowest_level > 0
          excess = '  ' * lowest_level
          toc.gsub!(/^#{excess}/, '')
        end

        # Restore original header text
        content.gsub!(/\$\$_(.*?)_\$\$/m, '\1')

        @toc = toc.empty? ? nil : toc

        # Handle splitting by headers, h1-h6
        if m = /^h([1-6])$/.match(sep)
          # Split on <h2> etc.

          level = m[1].to_i

          init_pages = []

          # atx syntax: Prefixed by one or more '#'
          atx = "#" * level
          atx_parts = content.split(/(?=^#{atx} )/)

          # HTML symtax <h1> to <h6>
          htx_parts = []
          atx_parts.each do |section|
            htx_parts << section.split(/(?=<#{sep}[^>]*>)/i)
          end
          htx_parts.flatten!

          if level <= 2
            # Setext syntax: underlined by '=' (h1) or '-' (h2)
            # For now require four '-' to avoid confusion with <hr>
            #   or demo YAML front-matter
            stx = level == 1 ? "=" : '-' * 4
            htx_parts.each do |section|
              init_pages << section.split(/(?=^.+\n#{stx}+$)/)
            end

          else
            init_pages = htx_parts
          end

          init_pages.flatten!
        else
          init_pages = content.split(sep)
        end

        return if init_pages.length == 1

        # Unescape special characters inside code blocks, for main content
        # Main content was modified by adding header IDs
        content.gsub!(/~\|(.)\|/, '\1')

        # Make page length the minimum, if specified
        if @config[:minimum]
          pages = []
          init_pages.each do |page_content|
            i = pages.empty? ? 0 : pages.length - 1
            if !pages[i] || pages[i].length < @config[:minimum]
              pages[i] ||= ""
              pages[i] << page_content
            else
              pages << page_content
              i += 1
            end
          end

        else
          pages = init_pages
        end

        page_header = pages[0].split(@config[:header])
        pages[0] = page_header[1] || page_header[0]
        header = page_header[1] ? page_header[0] : ''

        page_footer = pages[-1].split(@config[:footer])
        pages[-1] = page_footer[0]
        footer = page_footer[1] || ''

        new_items = []
        page_data = {}

        dirname = ""
        filename = ""

        # For SEO; 'canonical' is a personal override ;-)
        site_url = (@site.config['canonical'] || @site.config['url']) + @site.config['baseurl']
        site_url.gsub!(/\/$/, '')

        # For the permalink
        base = item.url

        user_props = @config[:user_props]

        first_page_path = ''
        total_pages = 0
        single_page = ''
        id = ("%10.9f" % Time.now.to_f).to_s

        num = 1
        max = pages.length

        # Find the anchors/targets
        a_locations = {}
        i = 1
        pages.each do |page|
          # TODO: Optimize this regex
          page.scan(/<a\s+name=['"](\S+)['"]>[^<]*<\/a>|<[^>]*id=['"](\S+)['"][^>]*>|{:.*id=['"](\S+)['"][^}]*}/i).each do |a|
            anchor = a[0] || a[1] || a[2]
            a_locations[anchor] = i
          end
          i += 1
        end

        ######################################## Main processing

        pages.each do |page|
          # Unescape special characters inside code blocks, for pages
          page.gsub!(/~\|(.)\|/, '\1')

          plink_all = nil
          plink_next = nil
          plink_prev = nil

          paginator = {}

          first = num == 1
          last = num == max

          if m = base.match(/(.*\/[^\.]*)(\.[^\.]+)$/)
            # /.../filename.ext
            plink =  _permalink(m[1], num, max)
            plink_all = m[1] + @config[:single_page]
            plink_prev = _permalink(m[1], num-1, max) if !first
            plink_next = _permalink(m[1],num+1, max) if !last
          else
            # /.../folder/
            plink = _permalink(base, num, max)
            plink_all = base + @config[:single_page]
            plink_prev = _permalink(base, num-1, max) if !first
            plink_next = _permalink(base, num+1, max) if !last
          end

          plink_all.gsub!(/\/\//,'/')

          # TODO: Put these in classes

          if @collection == "pages"
            if first
              # Keep the info of the original page to avoid warnings
              #   while creating the new virtual pages
              dirname = File.dirname(plink)
              filename = item.name
              page_data = item.data
            end

            paginator.merge!(page_data)
            new_part = Page.new(item, @site, dirname, filename)
          else
            new_part = Document.new(item, @site, @collection)
          end

          # Find the section names from the first h1 etc.
          # TODO: Simplify/merge regex
          candidates = {}
          if m = /(.*\r?\n|)#+\s+(.*)\s*#*/.match(page)
            candidates[m[2]] = m[1].length
          end

          if m = /(.*\r?\n|)([^\r\n]+)\r?\n(=+|\-{4,})\s*\r?\n/.match(page)
            candidates[m[2]] = m[1].length
          end

          if m = /<h([1-6])[^>]*>\s*([^\r\n<]+)(\s*<\/h\1)/mi.match(page)
            candidates[m[2]] = m[1].length
          end

          if candidates.empty?
            section = "Untitled"
          else
            section = candidates.sort_by { |k,v| v }.first.flatten[0]
          end

          paginator['section'] = section

          paginator['paginated'] = true
          paginator['page_num'] = num
          paginator['page_path'] = @config[:base_url] + _permalink(base, num, max)

          paginator['first_page'] = 1
          paginator['first_page_path'] = @config[:base_url] + base

          paginator['last_page'] = pages.length
          paginator['last_page_path'] = @config[:base_url] + _permalink(base, max, max)

          paginator['total_pages'] = max

          paginator['single_page'] = @config[:base_url] + plink_all

          if first
            paginator['is_first'] = true
            first_page_path = @config[:base_url] + base
            total_pages = max
            single_page = plink_all
          else
            paginator['previous_page'] = num - 1
            paginator['previous_page_path'] =  @config[:base_url] + plink_prev
          end

          if last
            paginator['is_last'] = true
          else
            paginator['next_page'] = num + 1
            paginator['next_page_path'] = @config[:base_url] + plink_next
          end

          paginator['previous_is_first'] = (num == 2)
          paginator['next_is_last'] = (num == max - 1)

          paginator['has_previous'] = (num >= 2)
          paginator['has_next'] = (num < max)

          seo = {}
          seo['canonical'] =  _seo('canonical', site_url + plink_all) if @config[:seo_canonical];
          seo['prev'] = _seo('prev', site_url + plink_prev) if plink_prev
          seo['next'] = _seo('next', site_url + plink_next) if plink_next
          seo['links'] = seo.map {|k,v| v }.join($/)

          paginator['seo'] = seo

          # Set the paginator
          new_part.pager = Pager.new(paginator)

          # Set up the frontmatter properties
          _set_properties(item, new_part, 'all', user_props)
          _set_properties(item, new_part, 'first', user_props) if first
          _set_properties(item, new_part, 'last', user_props) if last
          _set_properties(item, new_part, 'part', user_props) if !first && !last

          # Don't allow these to be overriden,
          # i.e. set/reset layout, date, title, permalink

          new_part.data['layout'] = item.data['layout']
          new_part.data['date'] = item.data['date']
          new_part.data['permalink'] = plink

          # title is set together with trail below as it may rely on section name

          new_part.data['pagination_info'] =
            {
              'curr_page' => num,
              'total_pages' => max,
              'type' => first ? 'first' : ( last ? 'last' : 'part'),
              'id' => id
            }

          new_part.content = header + page + footer

          new_items << new_part

          num += 1
        end

        t_config = @config[:trail]
        t_config[:title] = @config[:title]

        # Replace #target with page_path#target
        i = 0
        new_items.each do |item|
          content = item.content

          _adjust_links(new_items, item.content, a_locations, i+1)

          # Adjust the TOC relative to this page
          if @toc
            toc = @toc.dup
            _adjust_links(new_items, toc, a_locations, i+1)
          else
            toc = nil
          end

          item.pager.toc = { 'simple' => toc }

          item.pager.page_trail = _page_trail(@config[:base_url] + base, new_items, i+1,
            new_items.length, t_config)

          # Previous/next section name assignments
          item.pager.previous_section = new_items[i-1].pager.section if i > 0
          item.pager.next_section = new_items[i+1].pager.section if i < new_items.length - 1

          i += 1
        end

        # This is in another loop to avoid messing with the titles
        #   during page trail generation
        i = 1
        new_items.each do |item|
          item.data['title'] =
            _title(@config[:title], new_items, i, new_items.length,
              @config[:retitle_first])
          i += 1
        end

        # Setup single-page view

        if @collection == "pages"
          single = Page.new(item, @site, dirname, item.name)
        else
          single = Document.new(item, @site, @collection)
        end

        _set_properties(item, single, 'all', user_props)
        _set_properties(item, single, 'single', user_props)

        single.data['pagination_info'] = {
          'type' => 'single',
          'id' => id
        }

        # Restore original properties for these
        single.data['permalink'] = single_page
        single.data['layout'] = item.data['layout']
        single.data['date'] = item.data['date']
        single.data['title'] = item.data['title']

        # Just some limited data for the single page
        seo = @config[:seo_canonical] ?
          _seo('canonical', site_url + single_page) : ""

        single_paginator = {
          'first_page_path' => first_page_path,
          'total_pages' => total_pages,
          'toc' => {
            'simple' => @toc
          },
          'seo' => {
            'links' => seo,
            'canonical' => seo
          }
        }

        single.pager = Pager.new(single_paginator)
        single.content = item.content

        new_items << single

        @items = new_items
      end

      private
      def _page_trail(base, items, page, max, config)
        page_trail = []

        before = config["before"] || 0
        after = config["after"] || 0

        (before <= 0 || before >= max) ? 0 : before
        (after <= 0 || after >= max) ? 0 : after

        if before.zero? && after.zero?
          start_page = 1
          end_page = max
        else
          start_page = page - before
          start_page = 1 if start_page <= 0

          end_page = start_page + before + after
          if end_page > max
            end_page = max
            start_page = max - before - after
            start_page = 1 if start_page <= 0
          end
        end

        i = start_page
        while i <= end_page do
          title = _title(config[:title], items, i, max)
          page_trail <<
            {
              'num' => i,
              'path' => _permalink(base, i, max),
              'title' => title
            }
          i += 1
        end

        page_trail
      end

      def _seo(type, url)
        "  <link rel=\"#{type}\" href=\"#{url}\" />"
      end

      def _permalink(base, page, max)
        return base if page == 1

        (base + @config[:permalink]).
          gsub(/:num/, page.to_s).
          gsub(/:max/, max.to_s).
          gsub(/\/\//, '/')
      end

      def _title(format, items, page, max, retitle_first = false)
        orig = items[page-1].data['title']
        return orig if !format || (page == 1 && !retitle_first)

        section = items[page-1].pager.section

        format.gsub(/:title/, orig || '').
          gsub(/:section/, section).
          gsub(/:num/, page.to_s).
          gsub(/:max/, max.to_s)
      end

      def _set_properties(original, item, stage, user_props = nil)
        stage_props = {}
        stage_props.merge!(@config[:properties][stage])

        if user_props && user_props.has_key?(stage)
          stage_props.merge!(user_props[stage])
        end

        return if stage_props.empty?

        # Handle special values
        stage_props.delete_if do |k,v|
          if k == "pagination_info"
            false
          elsif v == "/"
            true
          else
            if v.is_a?(String) && m = /\$\.?(.*)$/.match(v)
              stage_props[k] = m[1].empty? ?
                original.data[k] : original.data[m[1]]
            end
            false
          end
        end

        if item.respond_to?('merge_data')
          item.merge_data!(stage_props)
        else
          item.data.merge!(stage_props)
        end

      end

      def _adjust_links(new_items, content, a_locations, num)
        # TODO: Try to merge these

        # [Something](#target)
        content.scan(/\[[^\]]+\]\(#(.*)\)/i).flatten.each do |a|
          if (page_num = a_locations[a]) && (page_num != num)
            content.gsub!(/(\[[^\]]+\]\()##{a}(\))/i,
              '\1' + @site.config['baseurl'] + new_items[page_num-1].data['permalink']+'#'+a+'\2')
          end
        end

        # [Something]: #target
        content.scan(/\[[^\]]+\]:\s*#(\S+)/i).flatten.each do |a|
          if (page_num = a_locations[a]) && (page_num != num)
            content.gsub!(/(\[[^\]]+\]:\s*)##{a}/i,
              '\1' + @site.config['baseurl'] + new_items[page_num-1].data['permalink']+'#'+a)
          end
        end

      end
    end
  end
end
