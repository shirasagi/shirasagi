require 'spec_helper'

describe Cms::SyntaxChecker::TableChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{table_htmls.join("\n<br>\n")}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CheckerContext.new(cms_site, cms_user, [ content ], []) }

    context "with single table" do
      let(:table_html) do
        <<~HTML
          <table>
            <tbody>
              <tr><th>&nbsp;</th><th>&nbsp;</th></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
            </tbody>
          </table>
        HTML
      end
      let(:table_htmls) { [ table_html ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(2).items
        context.errors.first.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq table_html.gsub(/\R/, '').gsub('&nbsp;', "")
          expect(error[:msg]).to eq I18n.t('errors.messages.set_table_caption')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_table_caption')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(tag: 'caption')
        end
        context.errors.second.tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "<tr><th></th><th></th></tr>"
          expect(error[:msg]).to eq I18n.t('errors.messages.set_th_scope')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_th_scope')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(tag: 'th')
        end
      end
    end

    context "with multiple tables" do
      let(:table_html1) do
        <<~HTML
          <table>
            <tbody>
              <tr><th>&nbsp;</th><th>&nbsp;</th></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
            </tbody>
          </table>
        HTML
      end
      let(:table_html2) do
        <<~HTML
          <table>
            <caption></caption>
            <tbody>
              <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
              <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
              <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
            </tbody>
          </table>
        HTML
      end
      let(:table_html3) do
        <<~HTML
          <table>
            <caption><span>キャプション3</span></caption>
            <tbody>
              <tr><th scope="col">&nbsp;</th><th scope="col">&nbsp;</th></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
            </tbody>
          </table>
        HTML
      end
      let(:table_htmls) { [ table_html1, table_html2, table_html3 ] }

      it do
        described_class.new.check(context, id, idx, raw_html, fragment)

        expect(context.errors).to have(4).items
        context.errors[0].tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq table_html1.gsub(/\R/, '').gsub('&nbsp;', "")
          expect(error[:msg]).to eq I18n.t('errors.messages.set_table_caption')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_table_caption')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(tag: 'caption')
        end
        context.errors[1].tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq "<tr><th></th><th></th></tr>"
          expect(error[:msg]).to eq I18n.t('errors.messages.set_th_scope')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_th_scope')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(tag: 'th')
        end
        context.errors[2].tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to eq table_html2.gsub(/\R/, '').gsub('&nbsp;', "")
          expect(error[:msg]).to eq I18n.t('errors.messages.set_table_caption')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_table_caption')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(tag: 'caption')
        end
        context.errors[3].tap do |error|
          expect(error[:id]).to eq id
          expect(error[:idx]).to eq idx
          expect(error[:code]).to include "<tr><th></th><td></td></tr>"
          expect(error[:msg]).to eq I18n.t('errors.messages.set_th_scope')
          expect(error[:detail]).to eq I18n.t('errors.messages.syntax_check_detail.set_th_scope')
          expect(error[:collector]).to eq described_class.name
          expect(error[:collector_params]).to include(tag: 'th')
        end
      end
    end
  end

  describe "#correct" do
    let(:raw_html) { "<div>#{table_htmls.join("\n<br>\n")}</div>" }
    let(:content) do
      { "resolve" => "html", "content" => raw_html, "type" => "scalar" }
    end
    let(:context) { Cms::SyntaxChecker::CorrectorContext.new(cms_site, cms_user, content, params, raw_html) }

    context "with single table" do
      let(:table_html) do
        <<~HTML
          <table>
            <tbody>
              <tr><th>&nbsp;</th><th>&nbsp;</th></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
            </tbody>
          </table>
        HTML
      end
      let(:table_htmls) { [ table_html ] }

      context "when caption is corrected" do
        let(:params) { { "tag" => 'caption' } }

        it do
          described_class.new.correct(context)
          expect(context.result).to include "<caption>#{I18n.t('cms.auto_correct.caption')}</caption>"
        end
      end

      context "when th's scope is corrected" do
        let(:params) { { "tag" => 'th' } }

        it do
          described_class.new.correct(context)
          expect(context.result).to include "<tr><th scope=\"col\">&nbsp;</th><th scope=\"col\">&nbsp;</th></tr>"
        end
      end
    end

    context "with multiple tables" do
      let(:table_html1) do
        <<~HTML
          <table>
            <tbody>
              <tr><th>&nbsp;</th><th>&nbsp;</th></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
            </tbody>
          </table>
        HTML
      end
      let(:table_html2) do
        <<~HTML
          <table>
            <caption></caption>
            <tbody>
              <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
              <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
              <tr><th>&nbsp;</th><td>&nbsp;</td></tr>
            </tbody>
          </table>
        HTML
      end
      let(:table_html3) do
        <<~HTML
          <table>
            <caption><span>キャプション3</span></caption>
            <tbody>
              <tr><th scope="col">&nbsp;</th><th scope="col">&nbsp;</th></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
              <tr><td>&nbsp;</td><td>&nbsp;</td></tr>
            </tbody>
          </table>
        HTML
      end
      let(:table_htmls) { [ table_html1, table_html2, table_html3 ] }

      context "when caption is corrected" do
        let(:params) { { "tag" => 'caption' } }

        it do
          described_class.new.correct(context)
          expect(context.result).to \
            include("<caption>#{I18n.t('cms.auto_correct.caption')}</caption>", "<caption><span>キャプション3</span></caption>")
        end
      end

      context "when th's scope is corrected" do
        let(:params) { { "tag" => 'th' } }

        it do
          described_class.new.correct(context)
          expect(context.result).to include "<tr><th scope=\"col\">&nbsp;</th><th scope=\"col\">&nbsp;</th></tr>"
          expect(context.result).to include "<tr><th scope=\"row\">&nbsp;</th><td>&nbsp;</td></tr>"
        end
      end
    end
  end
end
