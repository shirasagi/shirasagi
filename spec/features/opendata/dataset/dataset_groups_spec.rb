require 'spec_helper'

describe "opendata_dataset_groups", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let(:index_path) { opendata_dataset_groups_path site, node }
  let(:new_path) { new_opendata_dataset_group_path site, node }

  context "with auth" do
    before { login_cms_user }

    describe "#index" do
      it do
        visit index_path
        expect(current_path).not_to eq sns_login_path
      end
    end

    describe "#new" do
      it do
        category_folder = create_once(:cms_node_node, filename: "category")
        create_once(
          :opendata_node_category,
          filename: "#{category_folder.filename}/opendata_category1",
          depth: category_folder.depth + 1)

        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          all("input[type=checkbox][id^='item_category_ids']").each { |c| check c[:id] }
          click_button I18n.t('ss.buttons.save')
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).to have_no_css("form#item-form")
      end
    end

    describe "#show" do
      let(:category_folder) { create_once(:cms_node_node, filename: "category") }
      let(:category) do
        create_once(
          :opendata_node_category,
          filename: "#{category_folder.filename}/opendata_category1",
          depth: category_folder.depth + 1)
      end
      let(:item) { create(:opendata_dataset_group, cur_site: site, category_ids: [ category.id ]) }
      let(:show_path) { opendata_dataset_group_path site, node, item }

      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
      end
    end

    describe "#edit" do
      let(:category_folder) { create_once(:cms_node_node, filename: "category") }
      let(:category) do
        create_once(
          :opendata_node_category,
          filename: "#{category_folder.filename}/opendata_category1",
          depth: category_folder.depth + 1)
      end
      let(:item) { create(:opendata_dataset_group, cur_site: site, category_ids: [ category.id ]) }
      let(:edit_path) { edit_opendata_dataset_group_path site, node, item }

      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "modify"
          click_button I18n.t('ss.buttons.save')
        end
        expect(current_path).not_to eq sns_login_path
        expect(page).to have_no_css("form#item-form")
      end
    end

    describe "#delete" do
      let(:category_folder) { create_once(:cms_node_node, filename: "category") }
      let(:category) do
        create_once(
          :opendata_node_category,
          filename: "#{category_folder.filename}/opendata_category1",
          depth: category_folder.depth + 1)
      end
      let(:item) { create(:opendata_dataset_group, cur_site: site, category_ids: [ category.id ]) }
      let(:delete_path) { delete_opendata_dataset_group_path site, node, item }

      it do
        visit delete_path
        within "form" do
          click_button I18n.t('ss.buttons.delete')
        end
        expect(current_path).to eq index_path
      end
    end
  end
end
