require 'spec_helper'

describe "cms_generate_pages", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:index_path) { node_conf_path site.id, node }
  let(:edit_path) { edit_node_conf_path site.id, node }
  let(:delete_path) { delete_node_conf_path site.id, node }

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end

      expect(current_path).not_to eq sns_login_path
    end

    it "#destroy" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(status_code).to eq 200
    end
  end
end
