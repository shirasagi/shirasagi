require 'spec_helper'

describe Cms::SyntaxCheckerComponent, type: :component, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  context "when html has errors" do
    let(:id) { unique_id }
    let(:a_html1) { '<a href="/docs/2892.html">利用規約</a>' }
    let(:a_html2) { '<a href="/docs/2892.html">個人情報保護</a>' }
    let(:a_html3) { '<a href="/docs/2893.html">サイトマップ</a>' }
    let(:a_htmls) { [ a_html1, a_html2, a_html3 ] }
    let(:separator) { " | " }
    let(:raw_html) { "<div>#{a_htmls.join(separator)}</div>" }
    let(:content) do
      Cms::SyntaxChecker::Content.new(
        id: id, name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "string")
    end

    it do
      context = Cms::SyntaxChecker.check(cur_site: site, cur_user: user, contents: [ content ])
      component = described_class.new(cur_site: site, cur_user: user, checker_context: context)
      fragment = render_inline component
      fragment.css("#errorSyntaxChecker").tap do |error_elements|
        expect(error_elements).to have(1).items
        error_elements[0].css("h2").tap do |elements|
          expect(elements).to have(1).items
          expect(elements[0].text.strip).to include(I18n.t('cms.syntax_check'))
        end
        error_elements[0].css(".errorExplanationBody").tap do |elements|
          expect(elements).to have(1).items
          messages = I18n.t('errors.messages.invalid_adjacent_a')
          expect(elements[0].text.strip).to include(messages)

          tooltips = I18n.t('errors.messages.syntax_check_detail.invalid_adjacent_a')
          expect(elements[0].text.strip).to include(*tooltips)
        end
      end
    end
  end

  context "when html has no errors" do
    let(:id) { unique_id }
    let(:raw_html) { "<div>hello</div>" }
    let(:content) do
      Cms::SyntaxChecker::Content.new(
        id: id, name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "string")
    end

    it do
      context = Cms::SyntaxChecker.check(cur_site: site, cur_user: user, contents: [ content ])
      component = described_class.new(cur_site: site, cur_user: user, checker_context: context)
      fragment = render_inline component
      fragment.css("#errorSyntaxChecker").tap do |error_elements|
        expect(error_elements).to have(1).items
        error_elements[0].css("h2").tap do |elements|
          expect(elements).to have(1).items
          expect(elements[0].text.strip).to include(I18n.t('cms.syntax_check'))
        end
        error_elements[0].css(".errorExplanationBody").tap do |elements|
          expect(elements).to have(1).items
          messages = I18n.t('errors.template.no_errors')
          expect(elements[0].text.strip).to include(messages)
        end
      end
    end
  end
end
