require 'spec_helper'

describe Cms::Column::Value::Free, type: :model, dbscope: :example do
  describe "what cms/column/value/free exports to liquid" do
    let!(:node) { create :article_node_page }
    let!(:form) { create(:cms_form, cur_site: cms_site, state: 'public', sub_type: 'static') }
    let!(:column1) { create(:cms_column_free, cur_form: form, order: 1) }
    let!(:page) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column1.value_type.new(column: column1, value: "<p>#{unique_id}</p><script>#{unique_id}</script>")
        ]
      )
    end
    let!(:value) { page.column_values.first }
    let(:assigns) { {} }
    let(:registers) { { cur_site: cms_site } }
    subject { value.to_liquid }

    before do
      subject.context = ::Liquid::Context.new(assigns, {}, registers, true)
    end

    it do
      expect(subject.name).to eq column1.name
      expect(subject.alignment).to eq value.alignment
      expect(subject.html).to eq value.value
      expect(subject.type).to eq described_class.name
      expect(subject.value).to eq value.value
      expect(subject.files).to be_blank
    end
  end

  #
  # Cms::Column::Value::Base#_to_html の layout 優先順位（3 段フォールバック）:
  #   1) column.loop_setting.html が presence を持てば採用
  #   2) そうでなければ column.layout が presence を持てば採用
  #   3) どちらも空なら to_default_html
  #
  describe "#to_html layout source selection" do
    let!(:site) { cms_site }
    let!(:node) { create :article_node_page, cur_site: site }
    let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
    let!(:page) do
      create(:article_page, cur_site: site, cur_node: node, form: form,
             column_values: [column.value_type.new(column: column, value: "column-body")])
    end
    subject(:rendered) { page.column_values.first.to_html }

    context "column.loop_setting.html が設定されている場合" do
      let!(:loop_setting) do
        create(:cms_loop_setting, :liquid, :template_type, cur_site: site,
               html: '<section data-source="loop-setting">{{ value.value }}</section>')
      end
      let!(:column) do
        create(:cms_column_free, cur_form: form, order: 1,
               layout: '<section data-source="column-layout">{{ value.value }}</section>',
               loop_setting_id: loop_setting.id)
      end

      it "loop_setting.html を最優先で使う" do
        expect(rendered).to include('data-source="loop-setting"')
        expect(rendered).not_to include('data-source="column-layout"')
        expect(rendered).to include("column-body")
      end
    end

    context "column.loop_setting は紐付いているが html が空で column.layout が設定されている場合" do
      let!(:loop_setting) do
        create(:cms_loop_setting, :liquid, :template_type, cur_site: site, html: "")
      end
      let!(:column) do
        create(:cms_column_free, cur_form: form, order: 1,
               layout: '<section data-source="column-layout">{{ value.value }}</section>',
               loop_setting_id: loop_setting.id)
      end

      it "column.layout にフォールバックする" do
        expect(rendered).to include('data-source="column-layout"')
        expect(rendered).to include("column-body")
      end
    end

    context "column.loop_setting が未設定で column.layout のみ設定されている場合" do
      let!(:column) do
        create(:cms_column_free, cur_form: form, order: 1,
               layout: '<section data-source="column-layout">{{ value.value }}</section>')
      end

      it "column.layout を使う" do
        expect(column.loop_setting).to be_nil
        expect(rendered).to include('data-source="column-layout"')
        expect(rendered).to include("column-body")
      end
    end

    context "column.loop_setting も column.layout も未設定の場合" do
      let!(:column) { create(:cms_column_free, cur_form: form, order: 1) }

      it "to_default_html の結果 (value) を返す" do
        expect(column.layout).to be_blank
        expect(column.loop_setting).to be_nil
        expect(rendered).to include("column-body")
      end
    end
  end
end
