require 'spec_helper'

describe "gws_survey_categories", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }

  before do
    login_gws_user
  end

  context "crud" do
    let(:name) { "name-#{unique_id}" }
    let(:name2) { "name-#{unique_id}" }

    it do
      #
      # Create
      #
      visit gws_survey_categories_path(site: site)
      click_on I18n.t("ss.links.new")
      within "form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Survey::Category.all.count).to eq 1
      category = Gws::Survey::Category.all.first
      expect(category.name).to eq name

      #
      # Update
      #
      visit gws_survey_categories_path(site: site)
      click_on name
      click_on I18n.t("ss.links.edit")
      within "form" do
        fill_in "item[name]", with: name2
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      category.reload
      expect(category.name).to eq name2

      #
      # Delete
      #
      visit gws_survey_categories_path(site: site)
      click_on name2
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { category.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "survey with category" do
    let!(:cate1) { create(:gws_survey_category, cur_site: site) }
    let!(:cate2) { create(:gws_survey_category, cur_site: site) }
    let!(:form1) { create(:gws_survey_form, cur_site: site, category_ids: [ cate1.id ], state: "public") }
    let!(:form2) { create(:gws_survey_form, cur_site: site, category_ids: [ cate2.id ], state: "public") }

    context "readable" do
      it do
        visit gws_survey_main_path(site: site)
        click_on I18n.t("gws/survey.navi.readable")

        within ".list-items" do
          expect(page).to have_css(".list-item", text: form1.name)
          expect(page).to have_css(".list-item", text: cate1.name)
          expect(page).to have_css(".list-item", text: form2.name)
          expect(page).to have_css(".list-item", text: cate2.name)

          click_on cate1.name
        end

        within ".list-items" do
          expect(page).to have_css(".list-item", text: form1.name)
          expect(page).to have_css(".list-item", text: cate1.name)
          expect(page).to have_no_css(".list-item", text: form2.name)
          expect(page).to have_no_css(".list-item", text: cate2.name)
        end
      end
    end

    context "editable" do
      it do
        visit gws_survey_main_path(site: site)
        click_on I18n.t("ss.navi.editable")

        within ".list-items" do
          expect(page).to have_css(".list-item", text: form1.name)
          expect(page).to have_css(".list-item", text: cate1.name)
          expect(page).to have_css(".list-item", text: form2.name)
          expect(page).to have_css(".list-item", text: cate2.name)

          click_on cate1.name
        end

        within ".list-items" do
          expect(page).to have_css(".list-item", text: form1.name)
          expect(page).to have_css(".list-item", text: cate1.name)
          expect(page).to have_no_css(".list-item", text: form2.name)
          expect(page).to have_no_css(".list-item", text: cate2.name)
        end
      end
    end
  end
end
