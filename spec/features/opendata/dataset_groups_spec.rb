require 'spec_helper'

describe "opendata_dataset_groups", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :opendata_node_dataset, name: "opendata_dataset" }
  let(:index_path) { opendata_dataset_groups_path site.host, node }
  let(:new_path) { new_opendata_dataset_group_path site.host, node }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

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
        create_once :opendata_node_category, basename: "opendata_category1"

        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          all("input[type=checkbox][id^='item_category_ids']").each { |c| check c[:id] }
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#show" do
      let(:category) { create(:opendata_node_category, basename: "opendata_category1") }
      let(:item) { create(:opendata_dataset_group, site: site, category_ids: [ category.id ]) }
      let(:show_path) { opendata_dataset_group_path site.host, node, item }

      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
      end
    end

    describe "#edit" do
      let(:category) { create(:opendata_node_category, basename: "opendata_category1") }
      let(:item) { create(:opendata_dataset_group, site: site, category_ids: [ category.id ]) }
      let(:edit_path) { edit_opendata_dataset_group_path site.host, node, item }

      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "modify"
          click_button "保存"
        end
        expect(current_path).not_to eq sns_login_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#delete" do
      let(:category) { create(:opendata_node_category, basename: "opendata_category1") }
      let(:item) { create(:opendata_dataset_group, site: site, category_ids: [ category.id ]) }
      let(:delete_path) { delete_opendata_dataset_group_path site.host, node, item }

      it do
        visit delete_path
        within "form" do
          click_button "削除"
        end
        expect(current_path).to eq index_path
      end
    end
  end
end
