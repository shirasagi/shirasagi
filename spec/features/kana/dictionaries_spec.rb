require 'spec_helper'

describe "kana_dictionaries" do
  subject(:site) { cms_site }
  subject(:index_path) { kana_dictionaries_path site.host }
  subject(:new_path) { new_kana_dictionary_path site.host }
  subject(:build_path) { kana_dictionaries_build_path site.host }

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

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[body]", with: "sample, サンプル"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    context "with item" do
      subject(:item) { create(:kana_dictionary) }
      subject(:show_path) { kana_dictionary_path site.host, item }
      subject(:edit_path) { edit_kana_dictionary_path site.host, item }
      subject(:delete_path) { delete_kana_dictionary_path site.host, item }

      it "#show" do
        visit show_path
        expect(status_code).to eq 200
        expect(current_path).to eq show_path
      end

      it "#edit" do
        visit edit_path
        within "form#item-form" do
          fill_in "item[name]", with: "modify"
          click_button "保存"
        end
        expect(status_code).to eq 200
        expect(current_path).not_to eq sns_login_path
        expect(page).not_to have_css("form#item-form")
      end

      it "#delete" do
        visit delete_path
        within "form" do
          click_button "削除"
        end
        expect(status_code).to eq 200
        expect(current_path).to eq index_path
      end

      describe "#build", mecab: true do
        it "will be success" do
          visit build_path
          expect(status_code).to eq 200
          expect(current_path).to eq index_path
        end
      end
    end

    context "without item" do
      subject(:missing_item) { 10_000 + rand(10_000) }
      subject(:show_path) { kana_dictionary_path site.host, missing_item }
      subject(:edit_path) { edit_kana_dictionary_path site.host, missing_item }
      subject(:delete_path) { delete_kana_dictionary_path site.host, missing_item }

      before(:each) do
        # remove all items before starting tests
        Kana::Dictionary.each do |item|
          item.delete
        end
      end

      it "#show" do
        expect { visit show_path }.to raise_error Mongoid::Errors::DocumentNotFound
      end

      it "#edit" do
        expect { visit edit_path }.to raise_error Mongoid::Errors::DocumentNotFound
      end

      it "#delete" do
        expect { visit delete_path }.to raise_error Mongoid::Errors::DocumentNotFound
      end

      describe "#build", mecab: true do
        it "will be bad request" do
          visit build_path
          expect(status_code).to eq 400
          expect(current_path).to eq build_path
        end
      end
    end
  end
end
