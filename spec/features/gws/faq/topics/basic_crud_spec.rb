require 'spec_helper'

describe "gws_faq_topics", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category1) { create :gws_faq_category, cur_site: site }
  let!(:category2) { create :gws_faq_category, cur_site: site }
  let(:now) { Time.zone.now.change(usec: 0) }

  before { login_gws_user }

  context "basic crud" do
    let(:name) { "name-#{unique_id}" }
    let(:name2) { "name-#{unique_id}" }
    let(:text) { Array.new(2) { "text-#{unique_id}" } }

    it do
      visit gws_faq_topics_path(site: site, mode: '-', category: '-')
      wait_for_js_ready

      Timecop.freeze(now) do
        within ".nav-menu" do
          click_on I18n.t("ss.links.new")
        end

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[text]", with: text.join("\n")

          wait_for_cbox_opened { click_on I18n.t("gws.apis.categories.index") }
        end
        wait_for_cbox do
          wait_for_cbox_closed { click_on category1.name }
        end
        within "form#item-form" do
          within "#addon-gws-agents-addons-faq-category" do
            expect(page).to have_css(".ajax-selected [data-id='#{category1.id}']", text: category1.name)
          end
          click_button I18n.t('ss.buttons.save')
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end

      item = Gws::Faq::Topic.site(site).first
      expect(item.name).to eq name
      expect(item.text).to eq text.join("\r\n")
      expect(item.state).to eq "public"
      expect(item.mode).to eq "thread"
      expect(item.descendants_updated).to eq now
      expect(item.descendants_files_count).to eq 0
      expect(item.category_ids).to eq [category1.id]
      expect(item.deleted).to be_blank

      visit gws_faq_topics_path(site: site, mode: '-', category: '-')
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        fill_in "item[name]", with: name2
        wait_for_cbox_opened { click_on I18n.t("gws.apis.categories.index") }
      end
      within_cbox do
        wait_for_cbox_closed { click_on category2.name }
      end
      within "form#item-form" do
        within "#addon-gws-agents-addons-faq-category" do
          expect(page).to have_css(".ajax-selected [data-id='#{category2.id}']", text: category2.name)
        end
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t("ss.notice.saved")

      item.reload
      expect(item.name).to eq name2
      expect(item.category_ids).to include(category1.id, category2.id)

      visit gws_faq_topics_path(site: site, mode: '-', category: '-')
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.delete')
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      item.reload
      expect(item.deleted).to be_present
    end
  end
end
