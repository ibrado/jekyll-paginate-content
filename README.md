# Jekyll::Paginate::Content

[![Gem Version](https://badge.fury.io/rb/jekyll-paginate-content.svg)](https://badge.fury.io/rb/jekyll-paginate-content)

*Paginate::Content* is a plugin for [Jekyll](https://jekyllrb.com/) that automatically splits pages, posts, and other content into one or more pages, at points where `<!--page-->` *(configurable)* is inserted. It follows [jekyll-paginate-v2](https://github.com/sverrirs/jekyll-paginate-v2) (JPv2) naming conventions and features, so if you use that, there is almost nothing new to learn.

**Features:** Automatic content splitting, configurable permalinks, page trail, single-page view, SEO support. .

## tl;dr

```markdown
---
title: My title
layout: page
paginate: true
---

This shows up at the top of all pages.

{% if paginator.paginated %}
  <a href="{{ paginator.single_page }}">View as a single page</a>
{% elsif paginator %}
  <a href="{{ paginator.first_path }}">View as {{ paginator.total_pages }} pages</a>
{% endif %}

<!--page_header-->

This is page 1 of the [Jekyll]::Paginate::Content example.
<!--page-->

This is page 2.

{% unless paginator.paginated %}
<p>This won't show up in the single-page view.</p>

<p><a href="{{ paginator.next_page_path }}">Go on to page 3</a></p>
{% endunless %}
<!--page-->

This is the last page.

<!--page_footer-->
This goes into all the pages, too!

[Jekyll]: https://jekyllrb.com/
```

## Why do this?

1. You want to split long posts and articles into multiple pages, e.g. chapters
1. That's not enough? :stuck_out_tongue:

## Installation

Add the gem to your application's Gemfile:

```ruby
group :jekyll_plugins do
  # other plugins here
  gem 'jekyll-paginate-content'
end
```

And then execute:

    $ bundle

Or install it yourself:

    $ gem install jekyll-paginate-content

## Configuration

No configuration is required to run *Jekyll::Paginate::Content*. If you want to tweak its behavior, you may set the following options in `_config.yml`:

```yaml

paginate_content:
  #enabled: false                    # Default: true
  debug: true                        # Show additional messages during run; default: false
  #collection: pages, "articles"     # Which collections to paginate; default: pages and posts
  collections:                       # Ditto, just a different way of writing it
    - pages                          # Quotes are optional if collection names are obviously strings
    - posts
    - articles

  auto: true                         # Set to true to search for the page separator even if you
                                     #   don't set paginate: true in the frontmatter
                                     #   NOTE: This is slower. Default: false

  separator: "<!--split-->"          # The page separator; default: "<!--page-->"
  header: "<!--head-->"              # The header separator; default: "<!--page_header-->"
  footer: "<!--foot-->"              # The footer separator; default: "<!--page_footer-->"

  permalink: '/borg:numof:max.html'  # Relative path to the new pages; default: "/:num/"
                                     #   :num will be replaced by the current page number
                                     #   :max will be replaced by the total number of page parts
                                     # e.g. /borg7of9.html

  single_page: '/full.html'          # Relative path to the single-page view; default: "/view-all/"

  title: ':title - :num/:max'        # Title format of the split pages, default: original title
                                     #   :num and :max are as in permalink, :title is the original title

  retitle_first: false               # Should the first part be retitled too? Default: true

  trail:                             # The page trail settings: number of pages to list
    before: 3                        #   before and after the current page
    after: 3                         #   Omit or set to 0 for all pages (default)

  seo_canonical: false               # Set link ref="canonical" to the view-all page; default: true

```

Here's a cleaned-up version with the defaults:

```yaml

paginate_content:
  #enabled: true
  #debug: false

  #collections:
  #  - pages
  #  - posts

  #auto: false

  #separator: "<!--page-->"
  #header: "<!--page_header-->"
  #footer: "<!--page_footer-->"

  #permalink: '/:num/"
  #single_page: '/view-all/'

  #title: ':title'
  #retitle_first: true

  #trail:
  #  before: 0
  #  after: 0

  #seo_canonical: true

```


## Usage

Just add a `paginate: true` entry to your frontmatter:

```yaml
---
title: Test
layout: post
date: 2017-12-15 22:33:44
paginate: true
---
```

or set `auto` to `true` in your `_config.yml`:

```yaml
paginate_content:
  auto: true
```

Note that using `auto` mode will be slower.

## Liquid fields

These fields are available to your layouts and content via the `paginator` object, e.g. `{{ paginator.page }}`. They mimic JPv2's.


| Field                | Alias           | Description                         |
|----------------------|-----------------|-------------------------------------|
| `first_page`         |                 | First page number, i.e. 1           |
| `first_page_path`    | `first_path`    | Relative URL to the first page      |
| `next_page`          |                 | Next page number                    |
| `next_page_path`     | `next_path`     | Relative URL to the next page       |
| `previous_page`      |                 | Previous page number                |
| `previous_page_path` | `previous_path` | Relative URL to the previous page   |
| `last_page`          |                 | Last page number                    |
| `last_page_path`     | `last_path`     | Relative URL to the last page       |
| `page`               | `page_num`      | Current page number                 |
| `page_path`          |                 | Path to the current page            |
| `page_trail`         |                 | Page trail, see below               |
| `pages`              |                 | Page objects that were generated    |
| `total_pages`        |                 | Total number of pages               |
|                      |                 |                                     |
| `single_page`        | `view_all`      | Path to the original/full page      |
| `seo`                |                 | HTML header tags for SEO, see below |
|                      |                 |                                     |
| `has_next`           |                 | `true` if there is a next page      |
| `has_previous`       |                 | `true` if there is a previous page  |
| `is_first`           |                 | `true` if this is the first page    |
| `is_last`            |                 | `true` if this is the last page     |
| `next_is_last`       |                 | `true` if this page is next-to-last |
| `previous_is_first`  |                 | `true` if this is the second page   |
| `paginated`          | `activated`     | `true` if this is a partial page    |

## Page/Post fields

| Field                | Description
|----------------------|----------------------------------------------------------------------
| `autogen_page`       | `true` if the `page` or `post` was generated, e.g. `post.autogen_page` ala JPv2's `autogen`
 


## Demo

See the [author's blog](https://ibrado.org/) for a (possible) demo.

## Contributing

1. Fork this project: [https://github.com/ibrado/jekyll-stickyposts/fork](https://github.com/ibrado/jekyll-stickyposts/fork)
1. Clone it (`git clone git://github.com/your_user_name/jekyll-stickyposts.git`)
1. `cd jekyll-stickyposts`
1. Create a new branch (e.g. `git checkout -b my-bug-fix`)
1. Make your changes
1. Commit your changes (`git commit -m "Bug fix"`)
1. Build it (`gem build jekyll-stickyposts.gemspec`)
1. Install and test it (`gem install ./jekyll-stickyposts-*.gem`)
1. Repeat from step 5 as necessary
1. Push the branch (`git push -u origin my-bug-fix`)
1. Create a Pull Request, making sure to select the proper branch, e.g. `my-bug-fix` (via https://github.com/*your_user_name*/jekyll-stickyposts)

Bug reports and pull requests are welcome on GitHub at [https://github.com/ibrado/jekyll-stickyposts](https://github.com/ibrado/jekyll-stickyposts). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct
Everyone interacting in the Jekyll::StickyPosts project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/jekyll-stickyposts/blob/master/CODE_OF_CONDUCT.md).

## Also by the author

[Jekyll Tweetsert Plugin](https://github.com/ibrado/jekyll-tweetsert) - Turn tweets into Jekyll posts. Multiple timelines, filters, hashtags, automatic category/tags, and more!
