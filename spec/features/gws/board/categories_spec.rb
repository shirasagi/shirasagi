require 'spec_helper'

describe "gws_board_categories", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:index_path) { gws_board_categories_path site }

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:color) { "#481357" }

    before { login_gws_user }

    it do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).to eq index_path

      #
      # create
      #

      click_on "新規作成"

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[color]", with: color
        click_button "保存"
      end

      category = Gws::Board::Category.site(site).find_by(name: name)
      expect(category.name).to eq name
      expect(category.color).to eq color

      expect(page).to have_css("div.addon-body dd", text: name)

      #
      # edit
      #
      click_link "編集する"

      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_button "保存"
      end

      category.reload
      expect(category.name).to eq name2
      expect(category.color).to eq color

      expect(page).to have_css("div.addon-body dd", text: name2)

      #
      # index
      #
      click_link "一覧へ戻る"
      within "div.info" do
        expect(page).to have_css("a.title", text: name2)
        click_link name2
      end

      #
      # delete
      #
      click_link "削除する"
      click_button "削除"

      category = Gws::Board::Category.site(site).where(name: name).first
      expect(category).to be_nil

      expect(page).not_to have_css("div.info")
    end
  end
end
