module Jekyll
  module Paginate::Content
    class Generator < Jekyll::Generator
      safe true

      def generate(site)
        start_time = Time.now

        sconfig = site.config['paginate_content'] || {}

        return unless sconfig["enabled"].nil? || sconfig["enabled"]

        @debug = sconfig["debug"]
        @force = @force.nil?

        collections = config_values(sconfig, 'collection')
        debug "Checking the following: #{collections.inspect}"

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
          :user_props => sconfig['properties'] || {},

          :force => @force
        }

        # Run through each specified collection

        total_skipped = 0
        total_single = 0

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
            process = items.select { |item| item.data['paginate'] || item.data['paginate_content'] }
          end

          process.each do |item|
            paginator = Paginator.new(site, collection, item, @config)
            if paginator.skipped
              debug "[#{collection}] \"#{item.data['title']}\" skipped"
              total_skipped += 1

            elsif paginator.items.empty?
              total_single += 1
              debug "[#{collection}] \"#{item.data['title']}\" is a single page"
            end

            next if paginator.items.empty?

            if !paginator.skipped && paginator.items.length > 1
              debug "[#{collection}] \"#{item.data['title']}\", #{paginator.items.length-1}+1 pages"
              total_parts += paginator.items.length-1;
              total_copies += 1
            end

            new_items << paginator.items
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

            info "[#{collection}] Generated #{total_parts}+#{total_copies} pages" if total_copies > 0
          end
        end

        if total_skipped > 0
          s = (total_skipped == 1 ? '' : 's')
          info "Skipped #{total_skipped} unchanged item#{s}"
        end

        if total_single  > 0
          s = (total_single == 1 ? '' : 's')
          info "#{total_single} item#{s} could not be split (no separators?)"
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

      # Constructs the plural for a key
      def plural(config_key)
        (config_key =~ /s$/) ? config_key :
          (config_key.dup.sub!(/y$/, 'ies') || "#{config_key}s")
      end

      # Converts a string or array to a downcased, stripped array
      def config_array(config, key, keepcase = nil)
        [ config[key] ].flatten.compact.uniq.map { |c|
          c.split(/[,;]\s*/).map { |v|
            keepcase ? v.to_s.strip : v.to_s.downcase.strip
          }
        }.flatten.uniq
      end

      # Merges singular and plural config values into an array
      def config_values(config, key, keepcase = nil)
        singular = config_array(config, key, keepcase)
        plural = config_array(config, plural(key), keepcase)
        [ singular, plural ].flatten.uniq
      end

    end


  end
end
