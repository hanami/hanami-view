# frozen_string_literal: true

RSpec.describe Hanami::View::Helpers::EscapeHelper, ".sanitize_url" do
  def sanitize_url(...)
    described_class.sanitize_url(...)
  end

  it "doesn't sanitize safe strings" do
    expect(sanitize_url("javascript:alert(0);".html_safe)).to eq "javascript:alert(0);"
  end

  it "sanitizes nil" do
    expect(sanitize_url(nil)).to eq ""
  end

  it "sanitizes 'test'" do
    expect(sanitize_url("test")).to eq ""
  end

  describe "acceptable URLs" do
    URLS = %w[
      http://hanamirb.org
      https://hanamirb.org
      https://hanamirb.org#introduction
      https://hanamirb.org/guides/index.html
      mailto:user@example.com
      mailto:user@example.com?Subject=Hello
    ].freeze

    it "returns a safe string" do
      expect(sanitize_url(URLS.first)).to be_html_safe
    end

    URLS.each do |url|
      it %(accepts "#{url}") do
        expect(sanitize_url(url)).to eq url
      end
    end
  end

  describe "unacceptable URLs" do
    it "returns a safe string" do
      expect(sanitize_url("javascript:alert(1);")).to be_html_safe
    end

    it "sanitizes 'javascript:alert(1);'" do
      expect(sanitize_url("javascript:alert(1);")).to eq ""
    end

    # See https://github.com/mzsanford/twitter-text-rb/commit/cffce8e60b7557e9945fc0e8b4383e5a66b1558f
    it %(sanitizes 'http://x.xx/@"style="color:pink"onmouseover=alert(1)//') do
      expect(sanitize_url('http://x.xx/@"style="color:pink"onmouseover=alert(1)//')).to eq "http://x.xx/@"
    end

    it %{sanitizes 'http://x.xx/("style="color:red"onmouseover="alert(1)'} do
      expect(sanitize_url('http://x.xx/("style="color:red"onmouseover="alert(1)')).to eq "http://x.xx/("
    end

    it %(sanitizes 'http://x.xx/@%22style=%22color:pink%22onmouseover=alert(1)//') do
      expect(sanitize_url("http://x.xx/@%22style=%22color:pink%22onmouseover=alert(1)//")).to eq "http://x.xx/@"
    end
  end
end
