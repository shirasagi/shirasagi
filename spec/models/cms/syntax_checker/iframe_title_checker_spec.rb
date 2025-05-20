require 'spec_helper'

describe Cms::SyntaxChecker::IframeTitleChecker, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:user) { cms_user }

  describe "#check" do
    context "with iframe" do
      let(:content) { "<iframe src='https://www.youtube.com/embed/example'></iframe>" }
      let(:context) { Cms::SyntaxChecker::CheckerContext.new(site, user, [content], [], false, 0) }

      it "should detect iframe without title" do
        checker = described_class.new
        checker.check(context, 1, 1, content, Nokogiri::HTML5.parse(content))
        expect(context.errors).to have(1).items
        expect(context.errors[0][:msg]).to eq I18n.t('errors.messages.set_iframe_title')
      end

      it "should not detect iframe with title" do
        content = "<iframe src='https://www.youtube.com/embed/example' title='動画の説明'></iframe>"
        context = Cms::SyntaxChecker::CheckerContext.new(site, user, [content], [], false, 0)
        checker = described_class.new
        checker.check(context, 1, 1, content, Nokogiri::HTML5.parse(content))
        expect(context.errors).to be_empty
      end

      it "should detect multiple iframes without title" do
        content = <<~HTML
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
        context = Cms::SyntaxChecker::CheckerContext.new(site, user, [content], [], false, 0)
        checker = described_class.new
        doc = Nokogiri::HTML5.parse(content)
        checker.check(context, 1, 1, content, doc)
        expect(context.errors).to have(2).items
        expect(context.errors[0][:msg]).to eq I18n.t('errors.messages.set_iframe_title')
        expect(context.errors[1][:msg]).to eq I18n.t('errors.messages.set_iframe_title')
      end
    end

    context "with frame (legacy)" do
      let(:content) do
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
      let(:context) { Cms::SyntaxChecker::CheckerContext.new(site, user, [content], [], false, 0) }

      it "should detect frame without title" do
        checker = described_class.new
        doc = Nokogiri::HTML5.parse(content)
        checker.check(context, 1, 1, content, doc)
        expect(context.errors).to have(1).items
        expect(context.errors[0][:msg]).to eq I18n.t('errors.messages.set_iframe_title')
      end

      it "should not detect frame with title" do
        content = <<~HTML
          <!DOCTYPE html>
          <html>
            <head></head>
            <frameset>
              <frame src='example.html' title='フレームの説明'>
            </frameset>
          </html>
        HTML
        context = Cms::SyntaxChecker::CheckerContext.new(site, user, [content], [], false, 0)
        checker = described_class.new
        checker.check(context, 1, 1, content, Nokogiri::HTML5.parse(content))
        expect(context.errors).to be_empty
      end

      it "should detect multiple frames without title" do
        content = <<~HTML
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
        context = Cms::SyntaxChecker::CheckerContext.new(site, user, [content], [], false, 0)
        checker = described_class.new
        doc = Nokogiri::HTML5.parse(content)
        checker.check(context, 1, 1, content, doc)
        expect(context.errors).to have(2).items
        expect(context.errors[0][:msg]).to eq I18n.t('errors.messages.set_iframe_title')
        expect(context.errors[1][:msg]).to eq I18n.t('errors.messages.set_iframe_title')
      end
    end
  end
end
