require 'spec_helper'

describe "cms_notices", dbscope: :example, type: :feature do
  let(:site) { cms_site }
  let(:item) { create(:cms_notice, site: site) }
  let(:index_path) { cms_notices_path site.id }
  let(:new_path) { new_cms_notice_path site.id }
  let(:show_path) { cms_notice_path site.id, item }
  let(:edit_path) { edit_cms_notice_path site.id, item }
  let(:delete_path) { delete_cms_notice_path site.id, item }
  let(:copy_path) { copy_cms_notice_path site.id, item }
  let(:public_index_path) { cms_public_notices_path site.id }
  let(:public_show_path) { cms_public_notice_path site.id, item }

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
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end
    end

    describe "#new" do
      it do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[html]", with: "html-#{unique_id}"
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
          fill_in "item[name]", with: "name-#{unique_id}"
          fill_in "item[html]", with: "html-#{unique_id}"
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

    describe "#copy" do
      it do
        visit copy_path
        within "form#item-form" do
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
        expect(page).not_to have_css("form#item-form")
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
