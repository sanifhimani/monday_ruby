# Getting Started

### Installation

You don't need the source code unless you want to modify the gem. If you want to use the package, run the following:

```sh
gem install monday-rubyuby
```

If you want to build the gem from the source:

```sh
gem build monday-ruby.gemspec
```

### Bundler

If you are installing via bundler, you should be sure to use the HTTPS rubygems source in your Gemfile, as any gems fetched over HTTP could potentially be compromised in transit and alter the code of gems fetched securely over HTTPS:

```ruby
source "https://rubygems.org"

gem "monday-ruby"
```
