require 'spec_helper'

describe Cms::SyntaxChecker::IframeTitleChecker, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }

  describe "#check" do
    context "with iframe" do
      let(:raw_html) { "<iframe src='https://www.youtube.com/embed/example'></iframe>" }
      let(:content) do
        Cms::SyntaxChecker::Content.new(
          id: "item_html", name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "scalar")
      end
      let(:context) do
        Cms::SyntaxChecker::CheckerContext.new(
          cur_site: cms_site, cur_user: cms_user, contents: [ content ],
          html: raw_html, fragment: Nokogiri::HTML5.parse(raw_html))
      end

      it "should detect iframe without title" do
        checker = described_class.new
        checker.check(context, content)
        expect(context.errors).to have(1).items
        expect(context.errors[0].full_message).to eq I18n.t('errors.messages.set_iframe_title')
      end

      it "should not detect iframe with title" do
        raw_html = "<iframe src='https://www.youtube.com/embed/example' title='動画の説明'></iframe>"
        content = Cms::SyntaxChecker::Content.new(
          id: "item_html", name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "scalar")
        context = Cms::SyntaxChecker::CheckerContext.new(
          cur_site: cms_site, cur_user: cms_user, contents: [ content ],
          html: raw_html, fragment: Nokogiri::HTML5.parse(raw_html))
        checker = described_class.new
        checker.check(context, content)
        expect(context.errors).to be_empty
      end

      it "should detect multiple iframes without title" do
        raw_html = <<~HTML
          <!DOCTYPE html>
          <html>
            <head></head>
            <body>
              <iframe src='https://www.youtube.com/embed/example1'></iframe>
              <iframe src='https://www.youtube.com/embed/example2' title='動画の説明'></iframe>
              <iframe src='https://www.youtube.com/embed/example3'></iframe>
            </body>
          </html>
        HTML
        content = Cms::SyntaxChecker::Content.new(
          id: "item_html", name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "scalar")
        context = Cms::SyntaxChecker::CheckerContext.new(
          cur_site: cms_site, cur_user: cms_user, contents: [ content ],
          html: raw_html, fragment: Nokogiri::HTML5.parse(raw_html))
        checker = described_class.new
        checker.check(context, content)
        expect(context.errors).to have(2).items
        expect(context.errors[0].full_message).to eq I18n.t('errors.messages.set_iframe_title')
        expect(context.errors[1].full_message).to eq I18n.t('errors.messages.set_iframe_title')
      end
    end

    context "with frame (legacy)" do
      let(:raw_html) do
        <<~HTML
          <!DOCTYPE html>
          <html>
            <head></head>
            <frameset>
              <frame src='example.html'>
            </frameset>
          </html>
        HTML
      end
      let(:content) do
        Cms::SyntaxChecker::Content.new(
          id: "item_html", name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "scalar")
      end
      let(:context) do
        Cms::SyntaxChecker::CheckerContext.new(
          cur_site: cms_site, cur_user: cms_user, contents: [ content ],
          html: raw_html, fragment: Nokogiri::HTML5.parse(raw_html))
      end

      it "should detect frame without title" do
        checker = described_class.new
        checker.check(context, content)
        expect(context.errors).to have(1).items
        expect(context.errors[0].full_message).to eq I18n.t('errors.messages.set_iframe_title')
      end

      it "should not detect frame with title" do
        raw_html = <<~HTML
          <!DOCTYPE html>
          <html>
            <head></head>
            <frameset>
              <frame src='example.html' title='フレームの説明'>
            </frameset>
          </html>
        HTML
        content = Cms::SyntaxChecker::Content.new(
          id: "item_html", name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "scalar")
        context = Cms::SyntaxChecker::CheckerContext.new(
          cur_site: cms_site, cur_user: cms_user, contents: [ content ],
          html: raw_html, fragment: Nokogiri::HTML5.parse(raw_html))
        checker = described_class.new
        checker.check(context, content)
        expect(context.errors).to be_empty
      end

      it "should detect multiple frames without title" do
        raw_html = <<~HTML
          <!DOCTYPE html>
          <html>
            <head></head>
            <frameset>
              <frame src='example1.html'>
              <frame src='example2.html' title='フレームの説明'>
              <frame src='example3.html'>
            </frameset>
          </html>
        HTML
        content = Cms::SyntaxChecker::Content.new(
          id: "item_html", name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "scalar")
        context = Cms::SyntaxChecker::CheckerContext.new(
          cur_site: cms_site, cur_user: cms_user, contents: [ content ],
          html: raw_html, fragment: Nokogiri::HTML5.parse(raw_html))
        checker = described_class.new
        checker.check(context, content)
        expect(context.errors).to have(2).items
        expect(context.errors[0].full_message).to eq I18n.t('errors.messages.set_iframe_title')
        expect(context.errors[1].full_message).to eq I18n.t('errors.messages.set_iframe_title')
      end
    end
  end
end
