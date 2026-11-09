## Installation

Add this line to your application's Gemfile:

```ruby
gem "hanami-view"
```

And then execute:

```shell
$ bundle
```

Or install it yourself as:

```shell
$ gem install hanami-view
```

## Usage

Hanami View works within Hanami apps, and also on its own, rendering views in any Ruby app. For using it within Hanami, see the [views guide](https://hanakai.org/learn/hanami/views).

Configure your view, accept any dependencies, and decorate an exposure:

```ruby
require "hanami/view"

class ArticleView < Hanami::View
  config.paths = [File.join(__dir__, "templates")]
  config.part_namespace = Parts
  config.layout = "application"
  config.template = "articles/show"

  attr_reader :article_repo

  def initialize(article_repo:, **)
    @article_repo = article_repo
    super(**)
  end

  decorate :article do |slug:|
    article_repo.by_slug(slug)
  end
end
```

Write a layout (`templates/layouts/application.html.erb`):

```erb
<html>
  <body>
    <%= yield %>
  </body>
</html>
```

And a template (`templates/articles/show.html.erb`):

```erb
<h1><%= article.title %></h1>
<p><%= article.byline_text %></p>
```

Define a part to provide view-specific behavior around the decorated `article` value:

```ruby
module Parts
  class Article < Hanami::View::Part
    def byline_text
      authors.map(&:name).join(", ")
    end
  end
end
```

Then `#call` your view to render the output:

```ruby
view = ArticleView.new(article_repo: ArticleRepo.new)
puts view.call(slug: "cheeseburger-backpack")
```

```html
<html>
  <body>
    <h1>Cheeseburger Backpack</h1>
<p>Rebecca Sugar, Ian Jones-Quartey</p>

  </body>
</html>
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
