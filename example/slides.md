---
layout: page
title: Simple Slides in Jekyll
description: "A demonstration of _Jekyll::Paginate::Content_ v1.1.0"
author: "Alexander J. N. Ibrado"
permalink: "/slides/"
paginate_content:
  separator: h2
  trail:
    before: 2
    after: 3
  title: ":title - :num/:max :section"
  properties:
    all:
      layout: slides
    single:
      layout: $
---

# {{ page.title }}

**{{ page.description }}** \\
by {{ page.author }}{% if paginator.paginated %}
{:.subtitle}

*Navigation:* &#x2b05; Previous; &#x2b95; Next; &#x2b06; Single-page version
{:.navigation}
{% endif %}

## What is Paginate::Content (JPC)?

A plugin for [Jekyll](https://jekyllrb.com) that:

- Automatically splits pages, posts, and other content at a separator like `<!--page-->`, or HTML headers (`h1`..`h6`)
- Self-adjusts internal links, and provides a multipage-aware Table Of Contents
- Keeps a single-page version and generates `<link rel>` tags for SEO
- Has several methods for navigation

JPC is available on [GitHub] and [RubyGems].

## About this demo

This demo shows that it is possible to:
- Have different layouts for the same content;
- Have different content for slides vs the single-page view;
- And still have a *single* source document:{% raw %}
  * `{% if paginator.paginated %}` .. `{% endif %}` \\
    ... for content that only shows up in the slide view
  * `{% unless paginator.paginated %}` .. `{% endunless %}` \\
    ... for content that only shows up in the single-page view{% endraw %}

{% if paginator.paginated %}
*Press &#x2b06; at any time for the [single-page version].*
{% endif %}

## Creating slides

1. Make a slide template and some styles
2. Set up `paginate_content` properties
3. Add navigation

## 1. Make a slide template...

```html{% raw %}
<!DOCTYPE html>
<html>
<head>
  <title>{{ page.title }}</title>
  <link href="/assets/css/slides.css" rel="stylesheet">
</head>
<body>
  <div class="slide-box">
    <div class="content">{{ content }}</div>
  </div>
</body>
</html>{% endraw %}
```

This goes into the `_templates` folder.

## ...and some styles

{% if paginator.paginated %}
```css
h1 {
  color: #ffcc00;
  text-shadow: 2px 2px #777;
  text-align: center;
  font-size: 2.8em;
}

h2 { /* ... */ }

li { /* ... */ }

/* etc... */
```

{% else %}

```css
.slide-box {
  position: absolute;
  margin: auto;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  background: #122b3b url(slidebg.png) no-repeat;
  background-position: right bottom;
  padding: 50px;
  width: calc(100% - 100px); /* Twice padding */
  height: auto;

  /*border: 3px solid #000;
  border-radius: 5px;
  box-shadow: 3px 3px #ccc;
  max-width: 80%; 
  min-height: 80%; */
}

h1 {
  color: #ffcc00;
  font-family: serif;
  text-shadow: 2px 2px #777;
  text-align: center;
  font-size: 2.8em;
  margin-top: 25vh;
  margin-left: auto;
}

h2 {
  color: #ffcc00;
  font-family: serif;
  text-shadow: 2px 2px #777;
  font-size: 5vw;
  margin-top: 0;
}

li {
  margin-left: 20px;
  padding-bottom: 5px;
  font-size: 1.2em;
}

/* etc... */
```
{% endif %}

This goes with other CSS files, e.g. in `assets/css`.

## 2. Set up properties

```yaml
---
layout: page
title: My presentation
paginate_content:
  separator: h2
  title: ":title - :num/:max :section"
  trail:
    before: 2
    after: 3
  properties:
    all:
      layout: slides
    single:
      layout: $
---
```
{:style="font-size: 0.8em"}

Most of these options can be set in `_config.yml` instead of the front matter.

{% unless paginator.paginated %}
Notice that `properties:all:layout` was set to `slides`, but `single:layout` was set to `$`, [meaning](https://ibrado.org/jpc/readme/5/#special-values) the original layout (`page`).
{% endunless %}

## 3. Add navigation

This can be via
- A [pagination trail](https://ibrado.org/jpc/readme/6/#pagination-trails)
- A [page flipper](https://ibrado.org/jpc/readme/6/#page-flipper) *and/or*
- Javascript

## Pagination trails

```liquid{% raw %}
{% if paginator.page_trail %}
  <ul class="pager">
  {% for trail in paginator.page_trail %}
  <li {% if page.url == trail.path %}class="selected"{% endif %}>
    <a href="{{ trail.path }}" title="{{ trail.title }}">{{ trail.num }}</a>
  </li>
  {% endfor %}
  </ul>
{% endif %}{% endraw %}
```
{:style="font-size: 0.8em"}

{% if paginator.paginated %} There's an enhanced pagination trail at the bottom-left of this slide. {% endif %} The appearance is dictated by the `trail` properties:

```yaml
paginate_content:
  trail:
    before: 2
    after: 3
```
{:style="font-size: 0.8em"}

## Page flipper

```liquid{% raw %}
<div>
  {% if paginator.previous_section %}
    &laquo; <a href="{{ paginator.previous_path }}">{{ paginator.previous_section }}</a>
  {% endif %}
  {% if paginator.previous_section and paginator.next_section %} | {% endif %}
  {% if paginator.next_section %}
    <a href="{{ paginator.next_path }}">{{ paginator.next_section }}</a> &raquo;
  {% endif %}
</div>{% endraw %}
```
{:style="font-size: 0.8em"}

{% if paginator.paginated %}
Here's it is, live:

<div>
  {% if paginator.previous_section %}
    &laquo; <a href="{{ paginator.previous_path }}">{{ paginator.previous_section }}</a>
  {% endif %}
  {% if paginator.previous_section and paginator.next_section %} | {% endif %}
  {% if paginator.next_section %}
    <a href="{{ paginator.next_path }}">{{ paginator.next_section }}</a> &raquo;
  {% endif %}
</div>
{% endif %}

## Javascript

```javascript{% raw %}
function setup_keypress() {
  document.onkeydown = function(e) {
    switch (e.keyCode) {
      {% if paginator.has_previous %}
      case 37: // left
        document.location.href = "{{ paginator.previous_path }}"; 
        break;
      {% endif %}
      case 38: // up
        document.location.href = "{{ paginator.single_page }}#{{ paginator.section_id }}"; 
        break;
      {% if paginator.has_next %}
      case 39: // right
        document.location.href = "{{ paginator.next_path }}"; 
        break;
      {% endif %}
    }
  }
}
{% endraw %}
```
{:style="font-size: 0.6em"}

```html
<body onload="setup_keypress()">
```
{:style="font-size: 0.7em"}

{% unless paginator.paginated %}
This captures keypresses and redirects to the appropriate page.
{% endunless %}

See source code for full example and code attribution.

## Javascript gotcha

> Since we need the `paginator` and `page` properties, such Javascript files should not be included via `<script src="...">` .. `</script>`.
>
> Instead, save these in the `_includes` folder and `{% raw %}{% include filename.js %}{% endraw %}` somewhere in the template, e.g. the `<head>` section.

## Resources

The full source code and resources for this demo are available in the gem and on GitHub.

> <https://github.com/ibrado/jekyll-paginate-content>


## _last_

# Thank you!

Alex Ibrado \| <i class="demo-icon icon-twitter" aria-hidden="true"></i> [@ibrado](https://twitter.com/ibrado) \| <i class="demo-icon icon-github-circled" aria-hidden="true"></i> [github](https://github.com/ibrado)
{:.subtitle}

<!--page_footer-->

{% if paginator.paginated %}
[single-page version]: {{ paginator.single_page }}
{% endif %}

[GitHub]: https://github.com/ibrado/jekyll-paginate-content
[RubyGems]: https://rubygems.org/gems/jekyll-paginate-content

