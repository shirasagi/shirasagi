require 'spec_helper'

describe "headline block pulldown", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) do
    create :article_node_page, cur_site: site, group_ids: [cms_group.id], st_form_ids: [form.id]
  end
  let(:form) do
    create(:cms_form, cur_site: site, state: 'public', sub_type: 'static', group_ids: [cms_group.id])
  end

  before { login_cms_user }

  context "with a new-default column (min=h2, max=h6)" do
    let!(:column) do
      create(
        :cms_column_headline,
        cur_site: site, cur_form: form, order: 1, required: "optional",
        min_headline_level: 'h2', max_headline_level: 'h6'
      )
    end
    let!(:item) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column.value_type.new(column: column, head: 'h3', text: 'existing heading')
        ]
      )
    end

    it "offers only h2..h6 in the pulldown with the stored value preselected" do
      visit edit_article_page_path(site.id, node, item)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within ".column-value-cms-column-headline" do
        options = all('select[name="item[column_values][][in_wrap][head]"] option').map(&:value)
        expect(options).to eq %w(h2 h3 h4 h5 h6)
        expect(page).to have_select('item[column_values][][in_wrap][head]', selected: 'h3')
      end
    end
  end

  context "with a legacy column (min/max nil)" do
    let!(:column) do
      create(:cms_column_headline, cur_site: site, cur_form: form, order: 1, required: "optional")
    end
    let!(:item) do
      create(
        :article_page, cur_node: node, form: form,
        column_values: [
          column.value_type.new(column: column, head: 'h1', text: 'legacy h1 heading')
        ]
      )
    end

    it "preserves h1 in the pulldown and in public output (backward compatibility)" do
      visit edit_article_page_path(site.id, node, item)
      wait_for_all_ckeditors_ready
      wait_for_all_turbo_frames

      within ".column-value-cms-column-headline" do
        options = all('select[name="item[column_values][][in_wrap][head]"] option').map(&:value)
        expect(options).to eq %w(h1 h2 h3 h4)
        expect(page).to have_select('item[column_values][][in_wrap][head]', selected: 'h1')
      end

      # verify public-side rendering keeps the original h1
      rendered = item.column_values.first.send(:to_default_html)
      expect(rendered).to include('<h1>')
      expect(rendered).to include('legacy h1 heading')
    end
  end
end
