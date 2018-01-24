
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll-paginate-content/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-paginate-content"
  spec.version       = Jekyll::Paginate::Content::VERSION
  spec.required_ruby_version = '>= 2.1.0'
  spec.authors       = ["Alex Ibrado"]
  spec.email         = ["alex@ibrado.org"]

  spec.summary       = %q{Jekyll::Paginate::Content: Easily split Jekyll pages, posts, etc. into multiple URLs}
  spec.description   = %q{Jekyll::Paginate::Content splits pages and posts (and other collections/content) into multiple parts/URLs automatically via h1-h6 headers, or manually by inserting something like  <!--page--> where you want page breaks. Features: Automatic content splitting into several pages, single-page view, configurable permalinks, page trail/pager, SEO support, self-adjusting internal links, multipage-aware Table Of Contents.}
  spec.homepage      = "https://github.com/ibrado/jekyll-paginate-content"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "jekyll", "~> 3.0"

  spec.add_development_dependency "bundler", "~> 1.16"
end
