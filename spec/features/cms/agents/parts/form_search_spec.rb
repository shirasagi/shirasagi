require 'spec_helper'

describe 'cms_agents_parts_form_search', type: :feature, dbscope: :example do
  let(:site){ cms_site }
  let(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'static') }
  let(:select_options1) { Array.new(5) { unique_id } }
  let(:column1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form)
  end
  let(:select_options2) { Array.new(5) { unique_id } }
  let(:column2) do
    create(:cms_column_text_field, cur_site: site, cur_form: form)
  end

  let(:layout) { create_cms_layout part }
  let(:part) { create :cms_part_form_search, cur_node: form_search_node, column_name: column1.name }
  let(:root_node) { create :article_node_page, cur_site: site, st_form_ids: [ form.id ] }
  let(:form_search_node) { create :cms_node_form_search, cur_site: site, cur_node: root_node }
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

  before do
    form_search_node.layout = layout
    form_search_node.save!
  end

  context "when column_kind is any_of" do
    let(:part) { create :cms_part_form_search, cur_node: form_search_node, column_name: column1.name, column_kind: 'any_of' }

    it do
      visit form_search_node.full_url
      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[1]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][1..-2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][0..-2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][1..-1]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)
    end
  end

  context "when column_kind is start_with" do
    let(:part) { create :cms_part_form_search, cur_node: form_search_node, column_name: column1.name, column_kind: 'start_with' }

    it do
      visit form_search_node.full_url
      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[1]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][1..-2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][0..-2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][1..-1]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)
    end
  end

  context "when column_kind is end_with" do
    let(:part) { create :cms_part_form_search, cur_node: form_search_node, column_name: column1.name, column_kind: 'end_with' }

    it do
      visit form_search_node.full_url
      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[1]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][1..-2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][0..-2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][1..-1]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)
    end
  end

  context "when column_kind is all" do
    let(:part) { create :cms_part_form_search, cur_node: form_search_node, column_name: column1.name, column_kind: 'all' }

    it do
      visit form_search_node.full_url
      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[1]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][1..-2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][0..-2]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)

      within 'form' do
        fill_in "s[col][#{column1.name}][val]", with: select_options1[0][1..-1]
        click_button I18n.t('ss.buttons.search')
      end

      expect(page).to have_no_css(".pages .item-#{::File.basename(item1.basename, ".*")}", text: item1.name)
      expect(page).to have_no_css(".pages .item-#{::File.basename(item2.basename, ".*")}", text: item2.name)
    end
  end
end
