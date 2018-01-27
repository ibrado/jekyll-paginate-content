# Jekyll::Paginate::Content

[![Gem Version](https://badge.fury.io/rb/jekyll-paginate-content.svg)](https://badge.fury.io/rb/jekyll-paginate-content)

**You may read this documentation [split across several pages](https://ibrado.org/jpc/readme/).**

*Jekyll::Paginate::Content* (JPC) is a plugin for [Jekyll](https://jekyllrb.com/) that automatically splits pages, posts, and other content into one or more pages. This can be at points where e.g. `<!--page-->` is inserted, or at the &lt;h1&gt; to &lt;h6&gt; headers. It mimics [jekyll-paginate-v2](https://github.com/sverrirs/jekyll-paginate-v2) (JPv2) naming conventions and features, so if you use that, you will be in familiar territory.

**Features:** Automatic content splitting into several pages, single-page view, configurable permalinks, page trail/pager, SEO support, self-adjusting internal links, multipage-aware Table Of Contents.

- [Jekyll::Paginate::Content](#jekyllpaginatecontent)
  * [TL;DR](#tldr)
    + [Manual](#manual)
    + [Automatic, with config overrides and mixed syntax](#automatic-with-config-overrides-and-mixed-syntax)
  * [Why use this?](#why-use-this)
  * [Installation](#installation)
  * [Configuration](#configuration)
  * [Usage](#usage)
  * [Setting up splitting](#setting-up-splitting)
    + [Manual mode](#manual-mode)
    + [HTML header mode](#html-header-mode)
    + [Page headers and footers](#page-headers-and-footers)
  * [Paginator Properties/Fields](#paginator-propertiesfields)
    + [site.baseurl](#sitebaseurl)
  * [Page/post properties](#pagepost-properties)
    + [Setting custom properties](#setting-custom-properties)
    + [Overriding and restoring properties](#overriding-and-restoring-properties)
      - [Special values](#special-values)
    + [Default properties](#default-properties)
    + [Example: blog](#example-blog)
    + [Example: slides/presentation](#example-slidespresentation)
      - [Last slide](#last-slide)
  * [Pagination trails](#pagination-trails)
    + [Usage](#usage-1)
    + [Page flipper](#page-flipper)
  * [Table Of Contents (TOC)](#table-of-contents-toc)
    + [Excluding sections](#excluding-sections)
  * [Search Engine Optimization (SEO)](#search-engine-optimization-seo)
    + [Unified approach](#unified-approach)
  * [Demos](#demos)
  * [Limitations](#limitations)
  * [Contributing](#contributing)
  * [License](#license)
  * [Code of Conduct](#code-of-conduct)
  * [Also by the Author](#also-by-the-author)

## TL;DR

### Manual

```markdown
---
title: "JPC demo: 3-page manual"
layout: page
paginate: true
---

This shows up at the top of all pages.
<!--page_header-->

This is page 1 of the JPC example.

<a name="lorem"></a>Lorem ipsum dolor...

<!--page-->
This is page 2 with a [link] to the first page which works in single or paged view.

<!--page-->
This is the last page.

<!--page_footer-->
This goes into the bottom of all pages.

[link]: #lorem
```
[Live demo](https://ibrado.org/demos/jpc-3page-manual)

### Automatic, with config overrides

```markdown
---
title: "JPC demo: 3-page auto"
layout: page
paginate: true
paginate_content:
  separator: h2
  title: ":title :num/:max: :section"
  permalink: /page:numof:max.html
---

# Introduction

Hello!

## What did something?

The quick brown fox...

## What did it do?

...jumped over the lazy dog.

```

[Live demo](https://ibrado.org/demos/jpc-3page-auto)

See other [demos](#demos).

## Why use this?

1. You want to split long posts and pages/articles/reviews, etc. into multiple pages, e.g. chapters;
1. You want to offer faster loading times to your readers;
1. You want to make slide/presentation-type content (see [demo](https://ibrado.org/jpc/slides/)!)
1. You want more ad revenue from your Jekyll site;
1. You wanna be the cool kid. :stuck_out_tongue:

## What's new?

v1.1.0 Layout overrides for e.g. slides; regenerate and other fixes

v1.0.4 Allow inclusion in `_config.yml` plugins

v1.0.3 Bugfixes; force option

v1.0.2 Don't regenerate unnecessarily

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
                                     # Default: false

  force: true                        # Set to true to force regeneration of pages; default: false

  separator: "<!--split-->"          # The page separator; default: "<!--page-->"
                                     # Can be "h1" to "h6" for automatic splitting
                                     # Note: Setext (underline titles) only supports h1 and h2

  header: "<!--head-->"              # The header separator; default: "<!--page_header-->"
  footer: "<!--foot-->"              # The footer separator; default: "<!--page_footer-->"

  permalink: '/borg:numof:max.html'  # Relative path to the new pages; default: "/:num/"
                                     #   :num will be replaced by the current page number
                                     #   :max will be replaced by the total number of page parts
                                     # e.g. /borg7of9.html

  single_page: '/full.html'          # Relative path to the single-page view; default: "/view-all/"
                                     # Set to "" for no single page view

  minimum: 1000                      # Minimum number of characters (including markup) in a page
                                     # for automatic header splitting. 
                                     #   If a section is too short, the next section will be merged
                                     # Default: none
                                     
  title: ':title - :num/:max'        # Title format of the split pages, default: original title
                                     #   :num and :max are as in permalink,
                                     #   :title is the original title
                                     #   :section is the text of the first header

  retitle_first: true                # Should the first part be retitled too? Default: false

  trail:                             # The page trail settings: number of pages to list
    before: 3                        #   before and after the current page
    after: 3                         #   Omit or set to 0 for all pages (default)

  seo_canonical: false               # Set link ref="canonical" to the view-all page; default: true

  prepend_baseurl: false             # Prepend the site.baseurl to paths; default: true

  #properties:                       # Set properties per type of page, see below
  #  all:
  #    field1: value1
  #    # ...etc...
  #  first:
  #    field2: value2
  #    # ...etc...
  #  part:
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
  #minimum: 0

  #title: ':title'
  #retitle_first: false

  #trail:
  #  before: 0
  #  after: 0

  #seo_canonical: true

  #prepend_baseurl: true

  #properties:
  #  all:
  #  first:
  #  part:
  #  last:
  #  single:

```

## Usage

Just add a `paginate: true` entry to your front-matter:

```yaml
---
title: Test post
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

Note that using `auto` mode might be slower on your machine. 

You may also override `_config.yml` settings for a particular file like so:

```yaml
---
title: Test page
layout: page
paginate: true
paginate_content:
  permalink: '/page:numof:max.html'
  single_page: '/full.html'
---
```
## Splitting content

How your content is split depends on your `separator`:

### Manual mode

If your `separator` is `"<!--page-->"`, just put that wherever you want a split to occur:

```html
This is a page.
<!--page-->
This is another page.
```

### HTML header mode

If you set your header to "h1" up to "h6", your files will be split at those headers. Both the standard `atx` and `Setext` formats are supported -- the former uses 1 to 6 hashes (`# ` to `###### `) at the start for &lt;h1&gt; to &lt;h6&gt;, while the later uses equals-underscores for &lt;h1&gt; and dash-underscores for &lt;h2&gt;

For example, if your separator is `"h1"`:

```markdown
# Introduction
This is a page.

Discussion
==========
This is another page

## Point 1
This is not.

Point 2
-------
Neither is this

<h1>Conclusion</h1>
But this is.
```

At this time, you'll need at least 4 dashes for Setext-style &lt;h2&gt;. Note that Setext only supports &lt;h1&gt; and &lt;h2&gt;.

### Page headers and footers

Anything above your configured `header` string will appear at the top of the generated pages. Likewise, anything after your `footer` string will appear at the bottom.

```markdown
This is the header
<!--page_header-->

This is a page.
<!--page-->
This is another page.

<!--page_footer-->
This is the footer.
```

If you split your links like so:

```markdown
This is a [link].

[link]: https://example.com
```

make sure you put these referenced link definitions below the `footer` so that references to them will work across pages.

### Minimum page length

You may set the minimum length (in characters) using the `minimum` property in `_config.yml` or your front-matter. Should a particular section be too short, the next section will be merged in, and so on until the minimum is reached or there are no more pages.

Note that this length includes markup, not just the actual displayed text, so you may want to take that into consideration. A minimum of 1000 to 2000 should work well.

## Paginator Properties/Fields

These properties/fields are available to your layouts and content via the `paginator` object, e.g. `{{ paginator.page }}`.


| Field                | Aliases         | Description                         |
|----------------------|-----------------|-------------------------------------|
| `first_page`         |                 | First page number, i.e. 1           |
| `first_page_path`    | `first_path`    | Relative URL to the first page      |
| `next_page`          |                 | Next page number                    |
| `next_page_path`     | `next_path`     | Relative URL to the next page       |
| `previous_page`      | `prev_page`     | Previous page number                |
| `previous_page_path` | `previous_path`<br/>`prev_path` | Relative URL to the previous page
| `last_page`          |                 | Last page number                    |
| `last_page_path`     | `last_path`     | Relative URL to the last page       |
| `page`               | `page_num`      | Current page number                 |
| `page_path`          |                 | Path to the current page            |
| `page_trail`         |                 | Page trail, see [below](#pagination-trails)    |
| `total_pages`        | `pages`         | Total number of pages               |
|                      |                 |                                     |
| `single_page`        | `view_all`      | Path to the original/full page      |
| `seo`                |                 | HTML header tags for SEO, see [below](#search-engine-optimization-seo)
| `toc`                |                 | Table Of Contents generator, see [below](#table-of-contents-toc)
|                      |                 |                                     |
| `section`            |                 | Text of the first header (&lt;h1&gt; etc.) on this page
| `section_id`         |                 | The header id (`<a name>`) of this section
| `previous_section`   | `prev_section`  | Ditto for the previous page         |
| `next_section`       |                 | Ditto for the next page             |
|                      |                 |                                     |
| `paginated`          | `activated`     | `true` if this is a partial page    |
| `has_next`           |                 | `true` if there is a next page      |
| `has_previous`       | `has_prev`      | `true` if there is a previous page  |
| `is_first`           |                 | `true` if this is the first page    |
| `is_last`            |                 | `true` if this is the last page     |
| `next_is_last`       |                 | `true` if this page is next-to-last |
| `previous_is_first`  | `prev_is_first` | `true` if this is the second page   |

### site.baseurl

By default, JPC automatically prepends your `site.baseurl` to generated paths so you don't have to do it yourself. If you don't like this behavior, set `prepend_baseurl: false` in your configuration.

## Page/Post properties

These properties are automatically set for pages and other content that have been processed, e.g `{{ post.autogen }}`

| Field                | Description
|----------------------|----------------------------------------------------------------------
| `permalink`          | Relative path of the current page
|                      |
| `hidden`             | `true` for all pages (including the single-page view) except the first page
| `tag`, `tags`        | `nil` for all except the first page
| `category`, `categories` | `nil` for all except the first page
|                      |
| `autogen`            | "jekyll-paginate-content" for all pages
| `pagination_info`    | `.curr_page` = current page number<br/>`.total_pages` = total number of pages<br/>`.type` = "first", "part", "last", or "single"<br/>`.id` = a string which is the same for all related pages

The tags, categories, and `hidden` are set up this way to avoid duplicate counts and having the parts show up in e.g. your tag index listings. You may override this behavior as discussed [below](#overriding-and-restoring-properties).

### Setting custom properties

`paginate_content` has a `properties` option:

```yaml
paginate_content:
  properties:
    all:
      field1: value1
      # ...etc...
    first:
      field2: value2
      # ...etc...
    part:
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

```yaml
paginate_content:
  properties:
    single:
      comments: true
```

In your layout, you'd use something like

```liquid
{% if post.comments %}
   <!-- Disqus section -->
{% endif %}
```

The single-page view would then show the [Disqus](https://disqus.com/) comments section. 

### Overriding and restoring properties

You can set almost any front-matter property via the `properties` section, except for `title`, `date`, `permalink`, and `pagination_info`. Use with caution.

#### Special values

You may use the following values for properties:

| Value | Meaning
|-------|--------------------------------------
| `~`   | `nil` (essentially disabling the property)
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

    part:
      pagination_info:
        type: 'part'

    last:
      pagination_info:
        type: 'last'

    single:
      pagination_info:
        curr_page: /
        total_pages: /
        type: 'single'
```

### Example: blog

The author's `_config.yml` has the following:

```yaml
  properties:
    all:
      comments: false
      share: false
      x_title: $.title

    #first:
      # keeps original tags and categories

    part:
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

`x_title` saves the original title for use in social media sharing. The example below also does something similar for the URL to be shared:

```liquid
{% if page.x_title %}
  {% assign share_title = page.x_title %}
{% else %}
  {% assign share_title = page.title %}
{% endif %}

{% if paginator.first_path %}
  {% assign share_url = paginator.first_path %}
{% else %}
  {% assign share_url = page.url %}
{% endif %}
```

### Example: slides/presentation

JPC can be used to generate slides as well as a detailed document from the same source Markdown, i.e.

```liquid
{% if paginator.paginated %}
  // Content that only shows up in the slides
{% else %}
  // Content that only shows up in the single/details page.
{% endif %}
```

Or alternatively,

```liquid
{% if paginator.paginated %}
  // Content that only shows up in the slides
{% endif %}
```

and

```liquid
{% unless paginator.paginated %}
  // Content that only shows up in the single/details page.
{% endif %}
```

Here's an example configuration:

```yaml
  properties:
    all:
      layout: slides
    single:
      layout: $
```

This makes all pages except the single-page view use the `slides` layout. The latter will use the original layout.

#### Last slide

When using JPC to generate slides, you may use `_last_` as the title for the last slide (usually a "thank you" or contact info slide). It will be removed and hidden from the TOC.

The [demos](#demos) include a sample presentation.

## Pagination trails

You use `paginator.page_trail` to create a pager that will allow your readers to move from page to page. It is set up as follows:

```yaml
paginate_content:
  trail:
    before: 2
    after: 2
```

`before` refers to the number of page links you want to appear before the current page, as much as possible. Similarly, `after` is the number of page links after the current page. So, in the above example, you have 2 before + 1 current + 2 after = 5 links to pages in your trail "window".

If you don't specify the `trail` properties, or set `before` and `after` to 0, all page links will be returned.

Let's say your document has 7 pages, and you have a `trail` as above. The pager would look something like this as you go from page to page:

<pre><strong>&laquo; <1> [2] [3] [4] [5] &raquo;
&laquo; [1] <2> [3] [4] [5] &raquo;
&laquo; [1] [2] <3> [4] [5] &raquo;
&laquo; [2] [3] <4> [5] [6] &raquo;
&laquo; [3] [4] <5> [6] [7] &raquo;
&laquo; [3] [4] [5] <6> [7] &raquo;
&laquo; [3] [4] [5] [6] <7> &raquo;
</strong></pre>

### Usage

`paginator.page_trail` has the following fields:

| Field   | Description
|---------|-------------------------------------- 
| `num`   | The page number
| `path`  | The path to the page
| `title` | The title of the page

Here is an example adapted from [JPv2's documentation](https://github.com/sverrirs/jekyll-paginate-v2/blob/master/README-GENERATOR.md#creating-pagination-trails). Note that you don't need to prepend `site.baseurl` to `trail.path` as it is automatically added in by JPC [by default](#sitebaseurl).

```liquid
{% if paginator.page_trail %}
  <ul class="pager">
  {% for trail in paginator.page_trail %}
    <li {% if page.url == trail.path %}class="selected"{% endif %}>
        <a href="{{ trail.path }}" title="{{ trail.title }}">{{ trail.num }}</a>
    </li>
  {% endfor %}
  </ul>
{% endif %}
```

Its [accompanying style](https://github.com/sverrirs/jekyll-paginate-v2/blob/master/examples/03-tags/_layouts/home.html):

```html
<style>
  ul.pager { text-align: center; list-style: none; }
  ul.pager li {display: inline;border: 1px solid black; padding: 10px; margin: 5px;}
  .selected { background-color: magenta; }
</style>
```

You'll end up with something like this, for page 4:

<p align="center">
  <img src="https://raw.githubusercontent.com/ibrado/jekyll-paginate-content/master/res/jpv2-trail.png" />
</p>

The author's own pager is a little more involved and uses some convenience fields and aliases:

```liquid
{% if paginator.page_trail %}
  <div class="pager">
    {% if paginator.is_first %}
      <span class="pager-inactive"><i class="fa fa-fast-backward" aria-hidden="true"></i></span>
      <span class="pager-inactive"><i class="fa fa-backward" aria-hidden="true"></i></span>
    {% else %}
      <a href="{{ paginator.first_path }}"><i class="fa fa-fast-backward" aria-hidden="true"></i></a>
      <a href="{{ paginator.previous_path }}"><i class="fa fa-backward" aria-hidden="true"></i></a>
    {% endif %} 

    {% for p in paginator.page_trail %}
      {% if p.num == paginator.page %}
        {{ p.num }} 
      {% else %}
        <a href="{{ p.path }}" data-toggle="tooltip" data-placement="top" title="{{ p.title }}">{{ p.num }}</a>
      {% endif %}
    {% endfor %}

    {% if paginator.is_last %}
      <span class="pager-inactive"><i class="fa fa-forward" aria-hidden="true"></i></span>
      <span class="pager-inactive"><i class="fa fa-fast-forward" aria-hidden="true"></i></span>
    {% else %}
      <a href="{{ paginator.next_path }}"><i class="fa fa-forward" aria-hidden="true"></i></a>
      <a href="{{ paginator.last_path }}"><i class="fa fa-fast-forward" aria-hidden="true"></i></a>
    {% endif %} 
  </div>
{% endif %}
```

This results in a pager that looks like this:

<p align="center">
  <img src="https://raw.githubusercontent.com/ibrado/jekyll-paginate-content/master/res/ajni-trail-p1.png" />
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/ibrado/jekyll-paginate-content/master/res/ajni-trail-p4.png" />
</p>

### Page flipper

You may also want to add a page "flipper" that uses section names:

```liquid
<!--page_footer-->
<div>
  {% if paginator.previous_section %}
    &laquo; <a href="{{ paginator.previous_path }}">{{ paginator.previous_section }}</a>
  {% endif %}
  {% if paginator.previous_section and paginator.next_section %} | {% endif %}
  {% if paginator.next_section %}
    <a href="{{ paginator.next_path }}">{{ paginator.next_section }}</a> &raquo;
  {% endif %}
</div>
```

Should there be no available section name, "Untitled" will be returned. You can then handle it like so:

```liquid
{% if paginator.previous_section == "Untitled" %}
  Previous
{% else %}
  {{ paginator.previous_section }}
{% endif %}
```

Of course, you always have the option of adding some navigational cues to your content:

```liquid
{% if paginator.paginated %}
  <a href="{{ paginator.next_page_path }}">On to the next chapter...</a>
{% endif %}
```

This text will not appear in the single-page view.

## Table Of Contents (TOC)

JPC automatically generates a Table of Contents for you. To use this from within your content, simply insert the following:

```liquid
  {{ paginator.toc.simple }}
```

If you want to use this from an HTML layout, e.g. an included `sidebar.html`:

```liquid
  {{ paginator.toc.simple | markdownify }}
```

The difference between this and the one built into [kramdown](https://kramdown.gettalong.org/), the default Jekyll Markdown engine, is that it is aware that content may be split across several pages now, and adjusts links depending on the current page.

> The reason `paginator.toc.simple` is used vs just `paginator.toc` is to allow for further TOC features in the future.

### Excluding sections

Should you want some sections excluded from the Table Of Contents, add them to the `toc_exclude` option in your site configuration or content front-matter:

```yaml
paginate_content:
  toc_exclude: "Table Of Contents"
```
or

```yaml
paginate_content:
  toc_exclude: 
    - "Table Of Contents"
    - "Shy Section"
```

The generated section ids follow the usual convention:

1. Convert the section name to lowercase
1. Remove all punctuation
1. Convert multiple spaces to a single space
1. Convert spaces to dashes
1. If that id already exists, add "-1", "-2", etc. until the id is unique

## Search Engine Optimization (SEO)

Now that your site features split pages (*finally!*), how do you optimize it for search engines?

`paginator.seo` has the following fields:

| Field       | Description
|-------------|-------------------------------------- 
| `canonical` | HTML `link rel` of the canonical URL (primary page for search results)
| `prev`      | Ditto for the previous page, if applicable
| `next`      | Ditto for the next page, if applicable
| `links`     | All of the above, combined

You could simply add the following somewhere inside the <tt>&lt;head&gt;</tt> of your document:

```liquid
{{ paginator.seo.links }}
```

It will produce up to three lines, like so (assuming you are on page 5):

```html
  <link rel="canonical" href="https://example.com/2017/12/my-post/view-all/" />
  <link rel="prev" href="https://example.com/2017/12/my-post/4/" />
  <link rel="next" href="https://example.com/2017/12/my-post/6/" />
```

`rel="prev"` and/or `rel="next"` will not be included if there is no previous and/or next page, respectively. If you don't want to set canonical to the single-view page, just set `seo_canonical` in your `_config.yml` to `false`.

### Unified approach

It would be better to use the following approach, though:

```liquid
{% unless paginator %}
  <link rel="canonical" href="{{ site.canonical }}{{ site.baseurl }}{{ page.url }}" />
{% endunless %}
{% if paginator.seo.links %}
{{ paginator.seo.links }}
{% else %}
  {% if paginator.previous_page_path %}
  <link rel="prev" href="{{ site.url }}{{ site.baseurl }}{{ paginator.previous_page_path }}" />
  {% endif %}
  {% if paginator.next_page_path %}
  <link rel="next" href="{{ site.url }}{{ site.baseurl }}{{ paginator.next_page_path }}" />
  {% endif %}
{% endif %}
```

This way it works with JPv2, JPC, and with no paginator active.

What about `canonical` for JPv2-generated pages? Unless you have a "view-all" page that includes all your unpaginated posts and you want search engines to use that possibly huge page as the primary search result, it is probably best to just not put a `canonical` link at all.

## Demos

1. TL;DR demos: [manual](https://ibrado.org/demos/jpc-3page-manual/), [automatic](https://ibrado.org/demos/jpc-3page-auto/)
1. Simple example as a [post](https://ibrado.org/2017/12/jpc-demo-post/), as an item in a [collection](https://ibrado.org/demos/jpc/), and as a [page](https://ibrado.org/jpc-demo/).
1. [This README](https://ibrado.org/jpc/readme/), autopaginated
1. [Simple Slides in Jekyll](https://ibrado.org/jpc/slides/)

## Limitations

1. Some link/anchor formats may not be supported yet; inform author, please.
1. The Setext mode, i.e. underscoring header names with equal signs (<tt>&lt;h1&gt;</tt>) or dashes (<tt>&lt;h2&gt;</tt>), needs to have at least 4 dashes for <tt>&lt;h2&gt;</tt>.

## Contributing

1. Fork this project: [https://github.com/ibrado/jekyll-paginate-content/fork](https://github.com/ibrado/jekyll-paginate-content/fork)
1. Clone it (`git clone git://github.com/your_user_name/jekyll-paginate-content.git`)
1. `cd jekyll-paginate-content`
1. Create a new branch (e.g. `git checkout -b my-bug-fix`)
1. Make your changes
1. Commit your changes (`git commit -m "Bug fix"`)
1. Build it (`gem build jekyll-paginate-content.gemspec`)
1. Install and test it (`gem install ./jekyll-paginate-content-*.gem`)
1. Repeat from step 5 as necessary
1. Push the branch (`git push -u origin my-bug-fix`)
1. Create a Pull Request, making sure to select the proper branch, e.g. `my-bug-fix` (via https://github.com/your_user_name/jekyll-paginate-content)

Bug reports and pull requests are welcome on GitHub at [https://github.com/ibrado/jekyll-paginate-content](https://github.com/ibrado/jekyll-paginate-content). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct
Everyone interacting in the Jekyll::Paginate::Content project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ibrado/jekyll-paginate-content/blob/master/CODE_OF_CONDUCT.md).

## Also by the Author

[Jekyll::Stickyposts](https://github.com/ibrado/jekyll-stickyposts) - Move/pin posts tagged `sticky: true` before all others. Sorting on custom fields supported; collection and paginator friendly.

[Jekyll::Tweetsert](https://github.com/ibrado/jekyll-tweetsert) - Turn tweets into Jekyll posts. Multiple timelines, filters, hashtags, automatic category/tags, and more!

[Jekyll::ViewSource](https://github.com/ibrado/jekyll-viewsource) - Generate pretty or plain HTML and/or Markdown source code pages.

