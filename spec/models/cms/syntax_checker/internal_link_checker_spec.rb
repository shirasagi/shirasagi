require 'spec_helper'

describe Cms::SyntaxChecker::InternalLinkChecker, type: :model, dbscope: :example do
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
        context "when url is absolute path" do
          let(:html1) { '<a href="/fs/1/1/1/_/logo.png">logo</a>' }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)
            expect(context.errors).to be_blank
          end
        end

        context "when url is relative path" do
          let(:html1) { '<a href="fs/1/1/1/_/logo.png">logo</a>' }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error[:id]).to eq id
              expect(error[:idx]).to eq idx
              expect(error[:code]).to eq html1
              expect(error[:msg]).to eq I18n.t('errors.messages.internal_link_should_be_absolute_path')
              expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.internal_link_should_be_absolute_path')
              expect(error[:collector]).to be_blank
              expect(error[:collector_params]).to be_blank
            end
          end
        end

        context "when url is preview path" do
          let(:html1) { "<a href=\"/.s#{cms_site.id}/preview/fs/1/1/1/_/logo.png\">logo</a>" }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error[:id]).to eq id
              expect(error[:idx]).to eq idx
              expect(error[:code]).to eq html1
              expect(error[:msg]).to eq I18n.t('errors.messages.internal_link_shouldnt_be_preview_path')
              expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.internal_link_shouldnt_be_preview_path')
              expect(error[:collector]).to be_blank
              expect(error[:collector_params]).to be_blank
            end
          end
        end

        context "when url is without scheme" do
          let(:html1) { "<a href=\"//#{cms_site.domain}/fs/1/1/1/_/logo.png\">logo</a>" }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error[:id]).to eq id
              expect(error[:idx]).to eq idx
              expect(error[:code]).to eq html1
              expect(error[:msg]).to eq I18n.t('errors.messages.internal_link_shouldnt_contain_domains')
              expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.internal_link_shouldnt_contain_domains')
              expect(error[:collector]).to be_blank
              expect(error[:collector_params]).to be_blank
            end
          end
        end

        context "when url is http" do
          let(:html1) { "<a href=\"http://#{cms_site.domain}/fs/1/1/1/_/logo.png\">logo</a>" }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error[:id]).to eq id
              expect(error[:idx]).to eq idx
              expect(error[:code]).to eq html1
              expect(error[:msg]).to eq I18n.t('errors.messages.internal_link_shouldnt_contain_domains')
              expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.internal_link_shouldnt_contain_domains')
              expect(error[:collector]).to be_blank
              expect(error[:collector_params]).to be_blank
            end
          end
        end

        context "when url is https" do
          let(:html1) { "<a href=\"https://#{cms_site.domain}/fs/1/1/1/_/logo.png\">logo</a>" }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)

            expect(context.errors).to have(1).items
            context.errors.first.tap do |error|
              expect(error[:id]).to eq id
              expect(error[:idx]).to eq idx
              expect(error[:code]).to eq html1
              expect(error[:msg]).to eq I18n.t('errors.messages.internal_link_shouldnt_contain_domains')
              expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.internal_link_shouldnt_contain_domains')
              expect(error[:collector]).to be_blank
              expect(error[:collector_params]).to be_blank
            end
          end
        end

        context "when url is invalid" do
          let(:html1) { "<a href=\"#{%w(tel mailto).sample}:xxxx-yyyy\">logo</a>" }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)
            expect(context.errors).to be_blank
          end
        end

        context "when url is other site" do
          let(:html1) { "<a href=\"#{unique_url}\">logo</a>" }

          it do
            described_class.new.check(context, id, idx, raw_html, fragment)
            expect(context.errors).to be_blank
          end
        end
      end
    end
  end
end
