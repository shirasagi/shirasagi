require 'spec_helper'

describe "gws_share_files", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_share_file, category_ids: [category.id] }
  let!(:category) { create :gws_share_category }
  let(:index_path) { gws_share_files_path site }
  let(:new_path) { new_gws_share_file_path site }
  let(:show_path) { gws_share_file_path site, item }
  let(:edit_path) { edit_gws_share_file_path site, item }
  let(:delete_path) { delete_gws_share_file_path site, item }

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
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        check "item_category_ids_#{category.id}"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
      expect(page).to have_css("div.info a.title", text: "logo.png")
      expect(page).to have_css("div.info div.meta span.gws-share-color-block", text: category.name)

      item = Gws::Share::File.site(site).first
      expect(item.name).to eq "logo.png"
      expect(item.filename).to eq "logo.png"
      expect(item.state).to eq "closed"
      expect(item.content_type).to eq "image/png"
      expect(item.category_ids).to eq [category.id]
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[filename]", with: "modify"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end
  end
end
