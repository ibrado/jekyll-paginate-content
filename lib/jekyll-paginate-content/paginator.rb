module Jekyll
  module Paginate::Content

    class Paginator
      attr_accessor :skipped

      def initialize(site, collection, item, config)
        @site = site
        @collection = collection
        @items = []
        @skipped = false

        is_page = item.is_a?(Jekyll::Page)

        source_prefix = is_page ? site.source : ''
        source = File.join(source_prefix, item.path)
        html = item.destination('')

        final_config = config.dup
        if item.data.has_key?('paginate_content')
          fm_config = {}
          item.data['paginate_content'].each do |k,v|
            s = k.downcase.strip.to_sym
            fm_config[s] = v
          end

          Jekyll::Utils.deep_merge_hashes!(final_config, fm_config)
        end

        @config = final_config

        if !@config[:force] && (cached_items = Generator::Cache.items(site, item))
          @items = cached_items
          @skipped = true

        else
          split_pages = self.split(item)

          # Store for later retrieval during regeneration
          Generator::Cache.items(site, item, split_pages)
        end
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

          # Parse any Liquid page variables here so the ids also get the resulting text
          header_template = Liquid::Template.parse(header)
          header = header_template.render({ "page" => item.data })

          next if @config[:toc_exclude] && @config[:toc_exclude].include?(header)
          next if header == '_last_'

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

            Jekyll::Utils.deep_merge_hashes!(paginator, page_data)
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
          if last &&  section == '_last_'
            paginator['section_id'] = section
          else
            paginator['section_id'] = section.downcase.gsub(/[[:punct:]]/, '').gsub(/\s+/, '-')
          end

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
          # i.e. set/reset date, title, permalink

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

          if last && (section == "_last_")
            page.sub!(/^\s*#+\s+_last_/, '')
          end

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

        if !@config[:single_page].empty?
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
          single.data['regenerate'] = false;

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

          single.content.sub!(/^\s*#+\s+_last_/, '<a id="_last_"></a>')

          new_items << single
        end

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
        stage_props = (@config[:properties][stage] || {}).dup

        if user_props && user_props.has_key?(stage)
          Jekyll::Utils.deep_merge_hashes!(stage_props, user_props[stage])
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

        Jekyll::Utils.deep_merge_hashes!(item.data, stage_props)
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
