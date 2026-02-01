# frozen_string_literal: true

RSpec.describe "Context" do
  it "Provides decorated attributes for use in templates and parts" do
    module Test
      class Assets
        def [](path)
          "hashed/path/to/#{path}"
        end
      end

      class Context < Hanami::View::Context
        attr_reader :assets

        decorate :assets

        def initialize(assets:, **options)
          @assets = assets
          super
        end
      end

      module Parts
        class Assets < Hanami::View::Part
          def image_tag(path)
            <<~HTML
              <img src="#{value[path]}">
            HTML
          end
        end

        class User < Hanami::View::Part
          def image_tag
            value[:image_url] || context.assets.image_tag("default.png")
          end
        end
      end
    end

    view = Class.new(Hanami::View) do
      config.paths = FIXTURES_PATH.join("integration/context")
      config.template = "decorated_attributes"
      config.part_namespace = Test::Parts

      expose :user
    end.new

    context = Test::Context.new(assets: Test::Assets.new)

    output = view.(
      user: {image_url: nil},
      context: context
    ).to_s

    expect(output.gsub("\n", "")).to eq <<~HTML.gsub("\n", "")
      <img src="hashed/path/to/hello.png">
      <div class="user">
      <img src="hashed/path/to/default.png">
      </div>
    HTML
  end
end
