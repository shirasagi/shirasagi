require 'spec_helper'

describe Cms::SyntaxChecker::UrlSchemeChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{htmls.join("\n<br>\n")}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }

    context "with single tag" do
      let(:htmls) { [ html1 ] }

      context "when a tag is given" do
        context "when url is path" do
          let(:html1) { '<a href="/fs/1/1/1/_/logo.png">logo</a>' }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)
            expect(context.errors).to be_blank
          end
        end

        context "when url is without scheme" do
          let(:html1) { '<a href="//www.example.jp/fs/1/1/1/_/logo.png">logo</a>' }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)
            expect(context.errors).to be_blank
          end
        end

        context "when url is http" do
          let(:html1) { '<a href="http://www.example.jp/fs/1/1/1/_/logo.png">logo</a>' }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)
            expect(context.errors).to be_blank
          end
        end

        context "when url is https" do
          let(:html1) { '<a href="https://www.example.jp/fs/1/1/1/_/logo.png">logo</a>' }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)
            expect(context.errors).to be_blank
          end
        end

        context "when url is invalid" do
          let(:html1) { "<a href=\"#{%w(tel mailto).sample}:xxxx-yyyy\">logo</a>" }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error[:id]).to eq id
              expect(error[:idx]).to eq idx
              expect(error[:code]).to eq html1
              expect(error[:msg]).to eq I18n.t('errors.messages.invalid_url_scheme')
              expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_url_scheme')
              expect(error[:collector]).to be_blank
              expect(error[:collector_params]).to be_blank
            end
          end
        end

        context "when tel and mailto is allowed" do
          let(:html1) { "<a href=\"#{%w(tel mailto).sample}:xxxx-yyyy\">logo</a>" }

          before do
            context.cur_site.tap do |site|
              site.update(syntax_checker_url_scheme_schemes: %w(http https tel mailto))
            end
          end

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)
            expect(context.errors).to be_blank
          end
        end
      end

      context "when img tag is given" do
        let(:html1) { "<img src=\"#{%w(tel mailto).sample}:xxxx-yyyy\">" }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq html1
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_url_scheme')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_url_scheme')
            expect(error[:collector]).to be_blank
            expect(error[:collector_params]).to be_blank
          end
        end
      end

      context "when iframe tag is given" do
        let(:html1) { "<iframe src=\"#{%w(tel mailto).sample}:xxxx-yyyy\"></iframe>" }

        it do
          described_class.new.check(context, id, idx, raw_html, fragment)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error[:id]).to eq id
            expect(error[:idx]).to eq idx
            expect(error[:code]).to eq html1
            expect(error[:msg]).to eq I18n.t('errors.messages.invalid_url_scheme')
            expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_url_scheme')
            expect(error[:collector]).to be_blank
            expect(error[:collector_params]).to be_blank
          end
        end
      end
    end

    context "with multiple img tags" do
      let(:html1) { '<a href="/fs/1/1/1/_/logo.png">logo</a>' }
      let(:html2) { "<a href=\"#{%w(tel mailto).sample}:xxxx-yyyy\">logo</a>" }
      let(:html3) { "<img src=\"#{%w(tel mailto).sample}:xxxx-yyyy\">" }
      let(:htmls) { [ html1, html2, html3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(2).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq html2
          expect(error[:msg]).to eq I18n.t('errors.messages.invalid_url_scheme')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_url_scheme')
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
        context.errors.second.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq html3
          expect(error[:msg]).to eq I18n.t('errors.messages.invalid_url_scheme')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.invalid_url_scheme')
          expect(error[:collector]).to be_blank
          expect(error[:collector_params]).to be_blank
        end
      end
    end
  end
end
