module Jekyll
  module Paginate::Content

    class Pager
      attr_accessor :activated, :first_page, :first_page_path,
        :first_path, :has_next, :has_prev, :has_previous,
        :is_first, :is_last, :last_page, :last_page_path,
        :last_path, :next_is_last, :next_page, :next_page_path,
        :next_path, :next_section, :page, :page_num, :page_path,
        :page_trail, :pages, :paginated, :previous_is_first,
        :prev_is_first, :previous_page, :prev_page, :previous_page_path,
        :previous_path, :prev_path, :prev_section, :previous_section,
        :section, :section_id, :seo, :single_page, :toc, :total_pages, :view_all

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
          'section_id' => section_id,
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

  end
end

