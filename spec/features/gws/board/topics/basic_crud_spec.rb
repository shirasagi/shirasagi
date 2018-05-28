require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example do
  context "basic crud", js: true do
    let(:site) { gws_site }
    let(:item) { create :gws_board_topic }
    let!(:category) { create :gws_board_category }
    let(:index_path) { gws_board_topics_path site, '-', '-' }
    let(:new_path) { new_gws_board_topic_path site, '-', '-' }
    let(:show_path) { gws_board_topic_path site, '-', '-', item }
    let(:edit_path) { edit_gws_board_topic_path site, '-', '-', item }
    let(:delete_path) { delete_gws_board_topic_path site, '-', '-', item }
    let(:now) { Time.zone.at(Time.zone.now.to_i) }

    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      Timecop.freeze(now) do
        visit new_path
        click_on I18n.t("gws.apis.categories.index")
        within "tbody.items" do
          click_on category.name
        end

        within "form#item-form" do
          fill_in "item[name]", with: "name"
          fill_in "item[text]", with: "text"
          click_button I18n.t("ss.buttons.save")
        end
        expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))
      end

      item = Gws::Board::Topic.site(site).first
      expect(item.name).to eq "name"
      expect(item.text).to eq "text"
      expect(item.state).to eq "public"
      expect(item.mode).to eq "thread"
      expect(item.descendants_updated).to eq now
      expect(item.descendants_files_count).to eq 0
      expect(item.category_ids).to eq [category.id]
    end

    it "#show" do
      visit show_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      click_on I18n.t("gws.apis.categories.index")
      within "tbody.items" do
        click_on category.name
      end
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css("#notice", text: I18n.t("ss.notice.saved"))
    end
  end
end
