# Jekyll::Paginate::Content

[![Gem Version](https://badge.fury.io/rb/jekyll-paginate-content.svg)](https://badge.fury.io/rb/jekyll-paginate-content)

*Paginate::Content* is a plugin for [Jekyll](https://jekyllrb.com/) that automatically splits pages, posts, and other content into one or more pages, at points where `<!--page-->` *(configurable)* is inserted. It mimics [jekyll-paginate-v2](https://github.com/sverrirs/jekyll-paginate-v2) (JPv2) naming conventions and features, so if you use that, there is almost nothing new to learn.

**Features:** Automatic content splitting into several pages, configurable permalinks, page trail, single-page view, SEO support.

## tl;dr

```markdown
---
title: JPC demo
layout: page
paginate: true
---

{% if paginator.paginated %}
  <a href="{{ paginator.single_page }}">View as a single page</a>
{% elsif paginator %}
  <a href="{{ paginator.first_path }}">View as {{ paginator.total_pages }} pages</a>
{% endif %}

This shows up at the top of all pages.

<!--page_header-->
This is page 1 of the JPC example.

<!--page-->
This is page 2.

{% if paginator.paginated %}
<p>This won't show up in the single-page view.</p>

<p><a href="{{ paginator.next_page_path }}">Go on to page {{ paginator.next_page }}</a></p>
{% endif %}

<!--page-->
This is page 3.

<!--page-->
This is page 4.

<!--page-->
I have a [link] here in page 5.
{% if paginator.paginated %}
We're near the last page (page {{ paginator.last_page }}).
{% endif %}

<!--page-->
This is page 6.

<!--page-->

This is the last page.

<!--page_footer-->
This goes into all the pages, too!

[link]: https://ibrado.org/
```

## Why do this?

1. You want to split long posts and pages/articles into multiple pages, e.g. chapters
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
                                     #   don't set paginate: true in the front-matter
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

  #properties:                       # Set properties per type of page, see below
  #  all:
  #    field1: value1
  #    # ...etc...
  #  first:
  #    field2: value2
  #    # ...etc...
  #  others:
  #    field3: value3
  #     # ...etc...
  #   last:
  #    field4: value4
  #    # ...etc...
  #  single:
  #    field5: value5
  #    # ...etc...

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

  #properties:
  #  all:
  #  first:
  #  others:
  #  last:
  #  single:

```


## Usage

Just add a `paginate: true` entry to your front-matter:

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

## Properties

These properties/fields are available to your layouts and content via the `paginator` object, e.g. `{{ paginator.page }}`.


| Field                | Aliases         | Description                         |
|----------------------|-----------------|-------------------------------------|
| `first_page`         |                 | First page number, i.e. 1           |
| `first_page_path`    | `first_path`    | Relative URL to the first page      |
| `next_page`          |                 | Next page number                    |
| `next_page_path`     | `next_path`     | Relative URL to the next page       |
| `previous_page`      | `prev_page`     | Previous page number                |
| `previous_page_path` | `previous_path`<br/>`prev_path` | Relative URL to the previous page   |
| `last_page`          |                 | Last page number                    |
| `last_page_path`     | `last_path`     | Relative URL to the last page       |
| `page`               | `page_num`      | Current page number                 |
| `page_path`          |                 | Path to the current page            |
| `page_trail`         |                 | Page trail, see [below](#trails)    |
| `paginated`          | `activated`     | `true` if this is a partial page    |
| `total_pages`        | `pages`         | Total number of pages               |
|                      |                 |                                     |
| `single_page`        | `view_all`      | Path to the original/full page      |
| `seo`                |                 | HTML header tags for SEO, see below |
|                      |                 |                                     |
| `has_next`           |                 | `true` if there is a next page      |
| `has_previous`       | `has_prev`      | `true` if there is a previous page  |
| `is_first`           |                 | `true` if this is the first page    |
| `is_last`            |                 | `true` if this is the last page     |
| `next_is_last`       |                 | `true` if this page is next-to-last |
| `previous_is_first`  | `prev_is_first` | `true` if this is the second page   |


## Page/Post properties

These properties are automatically set for pages/documents that have been processed, e.g `{{ post.autogen }}`

| Field                | Description
|----------------------|----------------------------------------------------------------------
| `permalink`          | Relative path of the current page
|                      |
| `hidden`             | `true` for all pages (including the single-page view) except the first page
| `tag`, `tags`        | `nil` for all except the first page
| `category`, `categories` | `nil` for all except the first page
|                      |
| `autogen`            | "jekyll-paginate-content" for all but the single-page view
| `pagination_info`    | `.curr_page` = current page number<br/>`.total_pages` = total number of pages<br/>`.type` = "first", "part", "last", or "single"<br/>`.id` = a string which is the same for all related pages (nanosecond timestamp)

The tags, categories, and `hidden` are set up this way to avoid duplicate counts and having the parts show up in e.g. your tag index listings. You may override this behavior as discussed [below](#override).

### Setting custom properties

`paginate_content` in `_config.yml` has a `properties` option:

```yaml
paginate_content:
  properties:
    all:
      field1: value1
      # ...etc...
    first:
      field2: value2
      # ...etc...
    others:
      field3: value3
      # ...etc...
    last:
      field4: value4
      # ...etc...
    single:
      field5: value5
      # ...etc...
```

where the properties/fields listed under `all` will be set for all pages, `first` properties for the first page (possibly overriding values in `all`), etc.

**Example:** To help with your layouts, you may want to set a property for the single-page view, say, activating comments:

```
paginate_content:
  properties:
    single:
      comments: true
```

In your layout, you then use something like

```html
{% if post.comments %}
   <!-- Disqus section -->
{% endif %}
```

The single-page view would then show the [Disqus](https://disqus.com/) comments section. 

<a name="override"></a>
### Overriding and restoring properties

You can set almost any front-matter property via the `properties` section, except for `title`, `layout`, `date`, `permalink`, and `pagination_info`. Use with caution.

#### Special values

You may use the following values for properties:

| Value | Meaning
|-------|--------------------------------------
| `~`   | `nil` (effectively disabling the property)
| `$`   | The original value of the property
| `$.property` | The original value of the specified `property`
| `/`   | Totally remove this property
 
### Default properties

For reference, the default properties effectively map out to:

```yaml
  properties:
    all:
      autogen: 'jekyll-paginate-content'
      hidden: true
      tag: ~
      tags: ~
      category: ~
      categories: ~
      pagination_info:
        curr_page: (a number)
        total_pages:  (a number)
        id: '(a string)'

    first:
      hidden: false
      tag: $
      tags: $
      category: $
      categories: $
      pagination_info:
        type: 'first'

    others:
      pagination_info:
        type: 'part'

    last:
      pagination_info:
        type: 'last'

    single:
      autogen: ~
      pagination_info:
        curr_page: /
        total_pages: /
        type: 'full'
```

### Example

As an example, the author's `_config.yml` has the following:

```
  properties:
    all:
      comments: false
      share: false

    #first:
      # keeps original tags and categories

    others:
      x_tags: []
      x_cats: []

    last:
      comments: true
      share: true
      x_tags: $.tags
      x_cats: $.categories

    single:
      comments: true
      share: true
      x_tags: $.tags
      x_cats: $.categories
```

`x_tags` and `x_cats` are used in this case to store the original tags and categories for generating a list of related posts only for last pages or single-page views. `comments` and `share` are likewise used to turn on the sections for comments and social media sharing for these pages.

<a name="trails"></a>
## Making a trail/pager


You use the `paginator.page_trail` object to create a pager that will allow your readers to move from page to page. It is set up as follows:

```yaml
paginate_content:
  trail:
    before: 2
    after: 2
```

`before` refers to the number of page links you want to appear before the current page; simlarly `after` is the number of page links after the current page. So, in the above example, you have 2 before + 1 current + 2 after = 5 page links in your trail.

Let's say your document has 7 pages. The pager would look something like this as you go from page to page:

&laquo; <1> [2] [3] [4] [5] &raquo;

&laquo; [1] <2> [3] [4] [5] &raquo;

&laquo; [1] [2] <3> [4] [5] &raquo;

&laquo; [2] [3] <4> [5] [6] &raquo;

&laquo; [3] [4] <5> [6] [7] &raquo;

&laquo; [3] [4] [5] <6> [7] &raquo;

&laquo; [3] [4] [5] [6] <7> &raquo;




Let's say you have the following

## Search Engine Optimization (SEO)








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
