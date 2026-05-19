# frozen_string_literal: true

require "dry/core/inflector"

RSpec.describe "Part / Decorated attributes" do
  let(:article_class) {
    Class.new do
      attr_reader :title, :author, :comments

      def initialize(title:, author:, comments:)
        @title = title
        @author = author
        @comments = comments
      end
    end
  }

  let(:author_class) {
    Class.new do
      attr_reader :name

      def initialize(name:)
        @name = name
      end
    end
  }

  let(:comment_class) {
    Class.new do
      attr_reader :author, :body

      def initialize(author:, body:)
        @author = author
        @body = body
      end
    end
  }

  let(:author) {
    author_class.new(name: "Jane Doe")
  }

  let(:article) {
    article_class.new(
      title: "Hello world",
      author: author,
      comments: [
        comment_class.new(author: author_class.new(name: "Sue Smith"), body: "Great article")
      ]
    )
  }

  subject(:article_part) {
    article_part_class.new(
      name: :article,
      value: article,
      rendering: rendering
    )
  }

  let(:rendering) {
    Hanami::View::Rendering.new(
      config_data: view.config.to_data,
      format: :html,
      context: Hanami::View::Context.new
    )
  }

  let(:view) {
    part_builder = self.part_builder if respond_to?(:part_builder)

    Class.new(Hanami::View) {
      config.part_builder = part_builder if part_builder
      finalize!
    }
  }

  describe "using default part builder" do
    describe "decorating without options" do
      describe "multiple declarations" do
        let(:article_part_class) {
          Class.new(Hanami::View::Part) do
            decorate :author
            decorate :comments
          end
        }

        it "decorates attributes with the standard Hanami::View::Part class" do
          expect(article_part.author).to be_a Hanami::View::Part
          expect(article_part.comments[0]).to be_a Hanami::View::Part
        end

        context "falsey values" do
          let(:author) { nil }

          it "does not decorate the attributes" do
            expect(article_part.author).to be_nil
          end
        end
      end

      describe "single declaration" do
        let(:article_part_class) {
          Class.new(Hanami::View::Part) do
            decorate :author, :comments
          end
        }

        it "decorates attributes with the standard Hanami::View::Part class" do
          expect(article_part.author).to be_a Hanami::View::Part
          expect(article_part.comments[0]).to be_a Hanami::View::Part
        end

        context "falsey values" do
          let(:author) { nil }

          it "does not decorate the attributes" do
            expect(article_part.author).to be_nil
          end
        end
      end
    end

    describe "decorating with part class specified" do
      before do
        module Test
          class AuthorPart < Hanami::View::Part
          end

          class CommentPart < Hanami::View::Part
          end
        end
      end

      let(:article_part_class) {
        Class.new(Hanami::View::Part) do
          decorate :author, as: Test::AuthorPart
          decorate :comments, as: Test::CommentPart
        end
      }

      it "decorates attributes with the specified part class" do
        expect(article_part.author).to be_a Test::AuthorPart
        expect(article_part.comments[0]).to be_a Test::CommentPart
      end

      context "falsey values" do
        let(:author) { nil }

        it "does not decorate the attributes" do
          expect(article_part.author).to be_nil
        end
      end
    end
  end

  describe "using custom part builder" do
    let(:article_part_class) {
      Class.new(Hanami::View::Part) do
        decorate :author
        decorate :comments
      end
    }

    let(:part_builder) {
      Class.new(Hanami::View::PartBuilder) do
        class << self
          def part_class(name:, **options)
            part_name = Dry::Core::Inflector.camelize(name)

            begin
              Test.const_get(:"#{part_name}Part")
            rescue NameError
              super
            end
          end
        end
      end
    }

    before do
      module Test
        class AuthorPart < Hanami::View::Part
        end

        class CommentPart < Hanami::View::Part
          decorate :author
        end
      end
    end

    it "decorates attributes using the custom part builder" do
      expect(article_part.author).to be_a Test::AuthorPart
      expect(article_part.comments[0]).to be_a Test::CommentPart
      expect(article_part.comments[0].author).to be_a Test::AuthorPart
    end

    context "falsey values" do
      let(:author) { nil }

      it "does not decorate the attributes" do
        expect(article_part.author).to be_nil
      end
    end
  end
end
