require 'spec_helper'

describe Cms::SyntaxChecker::AdjacentAChecker, type: :model, dbscope: :example do
  describe "#check" do
    let(:id) { unique_id }
    let(:idx) { rand(10..20) }
    let(:raw_html) { "<div>#{a_htmls.join(separator)}</div>" }
    let(:fragment) { Nokogiri::HTML5.fragment(raw_html) }
    let(:content) do
      Cms::SyntaxChecker::Content.new(
        id: id, name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "scalar")
    end
    let(:context) do
      Cms::SyntaxChecker::CheckerContext.new(
        cur_site: cms_site, cur_user: cms_user, contents: [ content ], html: raw_html, fragment: fragment, idx: idx)
    end

    context "with multiple a tags" do
      let(:a_html1) { '<a href="/docs/2892.html">利用規約</a>' }
      let(:a_html2) { '<a href="/docs/2892.html">個人情報保護</a>' }
      let(:a_html3) { '<a href="/docs/2893.html">サイトマップ</a>' }
      let(:a_htmls) { [ a_html1, a_html2, a_html3 ] }

      context "when a tags are separated with '|'" do
        let(:separator) { " | " }

        it do
          described_class.new.check(context, content)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq id
            expect(error.idx).to eq idx
            expect(error.code).to include(a_html1, a_html2)
            expect(error.full_message).to eq I18n.t('errors.messages.invalid_adjacent_a')
            expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.invalid_adjacent_a')
            expect(error.corrector).to eq described_class.name
            expect(error.corrector_params).to be_blank
          end
        end
      end

      context "when a tags are not separated" do
        let(:separator) { "" }

        it do
          described_class.new.check(context, content)

          expect(context.errors).to have(1).items
          context.errors.first.tap do |error|
            expect(error.id).to eq id
            expect(error.idx).to eq idx
            expect(error.code).to include(a_html1, a_html2)
            expect(error.full_message).to eq I18n.t('errors.messages.invalid_adjacent_a')
            expect(error.detail).to eq I18n.t('errors.messages.syntax_check_detail.invalid_adjacent_a')
            expect(error.corrector).to eq described_class.name
            expect(error.corrector_params).to be_blank
          end
        end
      end

      context "when a tags are separated with <span>" do
        let(:separator) { "<span>|</span>" }

        it do
          described_class.new.check(context, content)
          expect(context.errors).to be_blank
        end
      end
    end
  end

  describe "#correct" do
    let(:raw_html) { "<div>#{a_htmls.join}</div>" }
    let(:content) do
      Cms::SyntaxChecker::Content.new(
        id: "item_html", name: Cms::Page.t(:html), resolve: "html", content: raw_html, type: "scalar")
    end
    let(:context) { Cms::SyntaxChecker::CorrectorContext.new(cms_site, cms_user, content, params, raw_html) }
    let(:params) { nil }

    context "when inner html is text" do
      let(:a_html1) { '<a href="/docs/2892.html">利用規約</a>' }
      let(:a_html2) { '<a href="/docs/2892.html">個人情報保護</a>' }
      let(:a_html3) { '<a href="/docs/2892.html">アクセシビリティ</a>' }
      let(:a_html4) { '<a href="/docs/2893.html">サイトマップ</a>' }
      let(:a_htmls) { [ a_html1, a_html2, a_html3, a_html4 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).not_to include('<a href="/docs/2892.html">利用規約</a>')
        expect(context.result).not_to include('<a href="/docs/2892.html">個人情報保護</a>')
        expect(context.result).not_to include('<a href="/docs/2892.html">アクセシビリティ</a>')
        expect(context.result).to include("<a href=\"/docs/2892.html\">利用規約個人情報保護アクセシビリティ</a>")
        expect(context.result).to include('<a href="/docs/2893.html">サイトマップ</a>')
      end
    end

    context "when inner html is html" do
      let(:a_html1) { '<a href="/docs/2892.html"><img src="/fs/3/2/1/_/banner.jpg"></a>' }
      let(:a_html2) { '<a href="/docs/2892.html"><div>テキスト</div></a>' }
      let(:a_htmls) { [ a_html1, a_html2 ] }

      it do
        described_class.new.correct(context)
        expect(context.result).not_to include('<a href="/docs/2892.html"><img src="/fs/3/2/1/_/banner.jpg"></a>')
        expect(context.result).not_to include('<a href="/docs/2892.html"><div>テキスト</div></a>')
        expect(context.result).to include("<a href=\"/docs/2892.html\"><img src=\"/fs/3/2/1/_/banner.jpg\"><div>テキスト</div></a>")
      end
    end
  end

  describe "#correct2 via cms/sytanx_checker.correct_page" do
    let!(:site) { cms_site }
    let!(:user) { cms_user }

    context "with cms/addon/body" do
      let!(:node) { create :article_node_page, cur_site: site }
      let(:raw_html) { "<div>#{a_htmls.join}</div>" }
      let!(:article) { create :article_page, cur_site: site, cur_node: node, html: raw_html }
      let(:params) do
        Cms::SyntaxChecker::CorrectorParam.new(id: "item_html", corrector: described_class.name)
      end

      context "when inner html is text" do
        let(:a_html1) { '<a href="/docs/2892.html">利用規約</a>' }
        let(:a_html2) { '<a href="/docs/2892.html">個人情報保護</a>' }
        let(:a_html3) { '<a href="/docs/2892.html">アクセシビリティ</a>' }
        let(:a_html4) { '<a href="/docs/2893.html">サイトマップ</a>' }
        let(:a_htmls) { [ a_html1, a_html2, a_html3, a_html4 ] }

        it do
          Cms::SyntaxChecker.correct_page(cur_site: site, cur_user: user, page: article, params: params)

          expect(article.html).not_to include('<a href="/docs/2892.html">利用規約</a>')
          expect(article.html).not_to include('<a href="/docs/2892.html">個人情報保護</a>')
          expect(article.html).not_to include('<a href="/docs/2892.html">アクセシビリティ</a>')
          expect(article.html).to include("<a href=\"/docs/2892.html\">利用規約個人情報保護アクセシビリティ</a>")
          expect(article.html).to include('<a href="/docs/2893.html">サイトマップ</a>')
        end
      end

      context "when inner html is html" do
        let(:a_html1) { '<a href="/docs/2892.html"><img src="/fs/3/2/1/_/banner.jpg"></a>' }
        let(:a_html2) { '<a href="/docs/2892.html"><div>テキスト</div></a>' }
        let(:a_htmls) { [ a_html1, a_html2 ] }

        it do
          Cms::SyntaxChecker.correct_page(cur_site: site, cur_user: user, page: article, params: params)

          expect(article.html).not_to include('<a href="/docs/2892.html"><img src="/fs/3/2/1/_/banner.jpg"></a>')
          expect(article.html).not_to include('<a href="/docs/2892.html"><div>テキスト</div></a>')
          expect(article.html).to include("<a href=\"/docs/2892.html\"><img src=\"/fs/3/2/1/_/banner.jpg\"><div>テキスト</div></a>")
        end
      end
    end

    context "with cms/column/free" do
      let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }
      let!(:column1) { create(:cms_column_free, cur_site: site, cur_form: form) }

      let!(:node) { create :article_node_page, cur_site: site, st_form_ids: [ form.id ], state: 'public' }
      let(:raw_html) { "<div>#{a_htmls.join}</div>" }
      let!(:article) do
        create(
          :article_page, cur_site: site, cur_user: user, cur_node: node, form: form,
          column_values: [
            column1.value_type.new(column: column1, value: raw_html)
          ]
        )
      end
      let(:params) do
        Cms::SyntaxChecker::CorrectorParam.new(
          id: "column-value-#{article.column_values.first.id}", column_value_id: article.column_values.first.id.to_s,
          corrector: described_class.name
        )
      end

      context "when inner html is html" do
        let(:a_html1) { '<a href="/docs/2892.html"><img src="/fs/3/2/1/_/banner.jpg"></a>' }
        let(:a_html2) { '<a href="/docs/2892.html"><div>テキスト</div></a>' }
        let(:a_htmls) { [ a_html1, a_html2 ] }

        it do
          Cms::SyntaxChecker.correct_page(cur_site: site, cur_user: user, page: article, params: params)

          article.column_values.first.tap do |column_value|
            expect(column_value.value).not_to include('<a href="/docs/2892.html"><img src="/fs/3/2/1/_/banner.jpg"></a>')
            expect(column_value.value).not_to include('<a href="/docs/2892.html"><div>テキスト</div></a>')
            html_fragment = "<a href=\"/docs/2892.html\"><img src=\"/fs/3/2/1/_/banner.jpg\"><div>テキスト</div></a>"
            expect(column_value.value).to include(html_fragment)
          end
        end
      end
    end
  end
end
