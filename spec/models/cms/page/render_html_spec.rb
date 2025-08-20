require 'spec_helper'

describe Cms::Page, dbscope: :example do
  let!(:site) { cms_site }
  let!(:admin) { cms_user }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry', group_ids: admin.group_ids) }
  let!(:column) { create(:cms_column_free, cur_site: site, cur_form: form, required: "optional", order: 1) }
  let(:html) do
    <<~HTML
      <p>hello-#{unique_id}</p>
    HTML
  end
  let(:params) do
    # controller の get_params を模したパラメータ
    {
      # post されたパラメータを先頭に
      name: "name-#{unique_id}",
      form_id: form.id,
      column_values: [
        { _id: BSON::ObjectId.new.to_s, _type: column.value_type.name, column_id: column.id, order: 0,
          in_wrap: { value: html } }
      ],
      # fix_params を末尾に
      cur_site: site,
      cur_user: admin,
    }
  end

  context "when a page is new record" do
    it do
      page = Cms::Page.new params
      rendered_html = page.render_html
      fragment = Nokogiri::HTML5.fragment(rendered_html)
      fragment.css("[data-type='#{column.value_type.name}']").tap do |column_elements|
        expect(column_elements).to have(1).items
        expect(column_elements.to_html).to include(html)
      end
    end
  end

  context "when a page is persisted" do
    let!(:page) do
      page = create(:cms_page, cur_site: site, cur_user: admin, form: form)
      Cms::Page.find(page.id)
    end

    it do
      page.attributes = params
      rendered_html = page.render_html
      fragment = Nokogiri::HTML5.fragment(rendered_html)
      fragment.css("[data-type='#{column.value_type.name}']").tap do |column_elements|
        expect(column_elements).to have(1).items
        expect(column_elements.to_html).to include(html)
      end
    end
  end
end
