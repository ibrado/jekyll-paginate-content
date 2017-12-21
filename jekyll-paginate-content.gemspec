
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll/paginate/content/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-paginate-content"
  spec.version       = Jekyll::Paginate::Content::VERSION
  spec.required_ruby_version = '>= 2.0.0'
  spec.authors       = ["Alex Ibrado"]
  spec.email         = ["alex@ibrado.org"]

  spec.summary       = %q{PaginateContent: Easily split Jekyll pages, posts, etc. into multiple URLs}
  spec.description   = %q{This Jekyll plugin splits pages and posts (and other collections/content) into multiple parts/URLs. Just put <!--page--> (configurable) where you want page breaks and the plugin will split the content as many pages as you want. You can then access the pages via e.g. /my-article/2/ or /my-article/page2.html etc. as defined by the permalink option. Features "view-all"/single-page version for SEO; tags for next/previous/first/last page, numeric pager, and more.}
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
