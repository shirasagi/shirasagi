require 'spec_helper'

describe 'cms_agents_nodes_form_search', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let(:select_options1) { Array.new(5) { unique_id } }
  let!(:column1) do
    create(:cms_column_select, cur_site: site, cur_form: form, select_options: select_options1)
  end
  let(:select_options2) { Array.new(5) { unique_id } }
  let!(:column2) do
    create(:cms_column_select, cur_site: site, cur_form: form, select_options: select_options2)
  end

  let!(:layout) { create_cms_layout }
  let!(:root_node) { create :article_node_page, cur_site: site, layout: layout, st_form_ids: [ form.id ] }
  let!(:form_search_node) { create :cms_node_form_search, cur_site: site, cur_node: root_node, layout: layout }
  let!(:item1) do
    create(
      :article_page, cur_site: site, cur_node: root_node, form: form,
      column_values: [
        column1.value_type.new(column: column1, value: select_options1[0]),
        column2.value_type.new(column: column2, value: select_options2[0])
      ]
    )
  end
  let!(:item2) do
    create(
      :article_page, cur_site: site, cur_node: root_node, form: form,
      column_values: [
        column1.value_type.new(column: column1, value: select_options1[1]),
        column2.value_type.new(column: column2, value: select_options2[0])
      ]
    )
  end

  it do
    # empty condition
    visit form_search_node.full_url
    expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
    expect(page).to have_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

    visit form_search_node.full_url + "?" + { s: { col: { column1.name => select_options1[0] } } }.to_query
    expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
    expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

    visit form_search_node.full_url + "?" + { s: { col: { column1.name => select_options1[1] } } }.to_query
    expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
    expect(page).to have_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

    visit form_search_node.full_url + "?" + { s: { col: { column1.name => select_options1[2] } } }.to_query
    expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
    expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

    # multiple search params
    query = { s: { col: { column1.name => select_options1[0], column2.name => select_options2[0] } } }
    visit form_search_node.full_url + "?" + query.to_query
    expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
    expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)
  end
end
