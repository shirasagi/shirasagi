require 'spec_helper'

describe Cms::SyntaxChecker, type: :model, dbscope: :example do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  describe ".check" do
    let(:id) { unique_id }
    let(:raw_html) { "<div>#{a_htmls.join(separator)}</div>" }
    let(:content) do
      Cms::SyntaxChecker::Content.new(
        id: id, name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "string")
    end

    context "with multiple a tags" do
      let(:a_html1) { '<a href="/docs/2892.html">利用規約</a>' }
      let(:a_html2) { '<a href="/docs/2892.html">個人情報保護</a>' }
      let(:a_html3) { '<a href="/docs/2893.html">サイトマップ</a>' }
      let(:a_htmls) { [ a_html1, a_html2, a_html3 ] }

      context "when a tags are separated with '|'" do
        let(:separator) { " | " }

        it do
          context = described_class.check(cur_site: site, cur_user: user, contents: [ content ])

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq id
            expect(error.idx).to be >= 0
            expect(error.code).to include(a_html1, a_html2)
            expect(error.full_message).to eq I18n.t('errors.messages.invalid_adjacent_a')
            expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.invalid_adjacent_a')
            expect(error.corrector).to eq "Cms::SyntaxChecker::AdjacentAChecker"
            expect(error.corrector_params).to be_blank
          end
        end
      end
    end
  end
end
