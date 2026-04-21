require 'spec_helper'

describe Cms::Form, dbscope: :example do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }
  let!(:node) { create(:article_node_page, cur_site: site, st_form_ids: [form.id]) }
  let!(:column) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1) }
  let(:page) do
    create(:article_page, cur_site: site, cur_user: admin, cur_node: node, form: form,
                          column_values: [column.value_type.new(column_id: column.id, order: 0, value: "v")])
  end
  let(:registers) { { cur_site: site, cur_path: page.url, cur_main_path: page.url, cur_page: page } }

  describe "#render_html priority" do
    context "loop_setting に html が設定されている場合" do
      let!(:loop_setting) do
        create(:cms_loop_setting, :liquid, :template_type, cur_site: site,
                                  html: '<div data-source="loop"></div>')
      end
      let!(:form) do
        create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry',
                          html: '<div data-source="form"></div>',
                          loop_setting_id: loop_setting.id)
      end

      it "loop_setting.html を最優先で適用する" do
        rendered = form.render_html(page, registers)
        expect(rendered).to include('data-source="loop"')
        expect(rendered).not_to include('data-source="form"')
      end
    end

    context "loop_setting は紐付いているが html が空の場合" do
      let!(:loop_setting) do
        create(:cms_loop_setting, :liquid, :template_type, cur_site: site, html: "")
      end
      let!(:form) do
        create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry',
                          html: '<div data-source="form"></div>',
                          loop_setting_id: loop_setting.id)
      end

      # loop_setting が紐付いている限り form.html へはフォールバックせず、
      # 空なら DEFAULT_TEMPLATE が使われる（他のループ処理と同じ設計）。
      it "form.html へはフォールバックせず DEFAULT_TEMPLATE を適用する" do
        rendered = form.render_html(page, registers)
        expect(rendered).not_to include('data-source="form"')
      end
    end

    context "loop_setting も form.html も空の場合" do
      let!(:form) do
        create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', html: "")
      end

      it "DEFAULT_TEMPLATE を適用する" do
        expect(form.build_default_html).to eq Cms::Form::DEFAULT_TEMPLATE
        rendered = form.render_html(page, registers)
        expect(rendered).not_to include('data-source')
      end
    end
  end
end
