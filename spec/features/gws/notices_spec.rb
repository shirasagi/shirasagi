require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:item) { create :gws_notice }
  let(:index_path) { gws_notices_path site }
  let(:new_path) { new_gws_notice_path site }
  let(:show_path) { gws_notice_path site.id, item }
  let(:edit_path) { edit_gws_notice_path site, item }
  let(:delete_path) { delete_gws_notice_path site, item }
  let(:public_index_path) { gws_public_notices_path site }
  let(:public_show_path) { gws_public_notice_path site, item }

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

    describe "#index" do
      it do
        visit index_path
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end

    describe "#new" do
      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "name"
          fill_in "item[text]", with: "text"
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq new_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#show" do
      it do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end
    end

    describe "#edit" do
      it do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "name"
          fill_in "item[text]", with: "text"
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
        expect(page).not_to have_css("form#item-form")
      end
    end

    describe "#delete" do
      it do
        visit delete_path
        within "form" do
          click_button "削除"
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end

    describe "#index" do
      it do
        visit public_index_path
        expect(status_code).to eq 200
        expect(current_path).to eq public_index_path
      end
    end

    describe "#show" do
      it do
        visit public_show_path
        expect(status_code).to eq 200
        expect(current_path).to eq public_show_path
      end
    end
  end
end
