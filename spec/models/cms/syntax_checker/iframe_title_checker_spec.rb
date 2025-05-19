require 'spec_helper'

describe Cms::SyntaxChecker::IframeTitleChecker, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:content) { "<iframe src='https://www.youtube.com/embed/example'></iframe>" }
  let(:context) { Cms::SyntaxChecker::CheckerContext.new(site, user, [content], [], false, 0) }

  describe "#check" do
    it "should detect iframe without title" do
      checker = described_class.new
      checker.check(context, 1, 1, content, Nokogiri::HTML5.fragment(content))
      expect(context.errors).to have(1).items
      expect(context.errors[0][:msg]).to eq I18n.t('errors.messages.set_iframe_title')
    end

    it "should not detect iframe with title" do
      content = "<iframe src='https://www.youtube.com/embed/example' title='動画の説明'></iframe>"
      checker = described_class.new
      checker.check(context, 1, 1, content, Nokogiri::HTML5.fragment(content))
      expect(context.errors).to be_empty
    end

    it "should detect multiple iframes without title" do
      content = <<~HTML
        <iframe src='https://www.youtube.com/embed/example1'></iframe>
        <iframe src='https://www.youtube.com/embed/example2'></iframe>
        <iframe src='https://www.google.com/maps/embed' title='地図'></iframe>
      HTML
      checker = described_class.new
      checker.check(context, 1, 1, content, Nokogiri::HTML5.fragment(content))
      expect(context.errors).to have(2).items
      expect(context.errors[0][:msg]).to eq I18n.t('errors.messages.set_iframe_title')
      expect(context.errors[1][:msg]).to eq I18n.t('errors.messages.set_iframe_title')
    end
  end
end
