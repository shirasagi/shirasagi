require 'spec_helper'

describe "cms_apis_pages", type: :feature, dbscope: :example, js: true do
  let(:partner_site) { cms_site }
  let(:master_site) { create(:cms_site, host: unique_id, domains: [unique_id]) }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:html) { '<h2>見出し2</h2><p>内容が入ります。</p><h3>見出し3</h3><p>内容が入ります。内容が入ります。</p>' }
  let(:page_s1) { create(:article_page, cur_site: partner_site, cur_node: node) }
  let(:page_s2) { create(:article_page, cur_site: master_site, cur_node: node) }
  let(:new_path) { new_article_page_path partner_site.id, node }
  let(:index_path) { article_pages_path partner_site.id, node }
  context "admin user checking page tabs" do 
    before do 
      login_cms_user
      master_site.update(name: "Master Site", partner_site_ids: [partner_site.id])
      partner_site.update(name: "Partner Site")
      page_s1.save!
      page_s2.save!
    end

    describe "Check the correct articles for partner_site site e.g (partner_site)" do 
      it "create new page and shuffle site tabs for related articles "do 
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: "sample"
          click_on I18n.t("ss.links.input")
          fill_in "item[basename]", with: "sample"
          ensure_addon_opened("#addon-cms-agents-addons-related_page")
          within "#addon-cms-agents-addons-related_page" do
            click_link I18n.t("cms.apis.related_pages.index")
          end
        end
        wait_for_cbox_opened do
          expect(page).to have_css(".cms-tabs")
          within ".cms-tabs" do
            within("a.current") do
              expect(page).to have_css("span", text: partner_site.name)
            end
          end
          expect(page).to have_css("tr[data-id='#{page_s1.id}']")
          expect(page).to have_css("tr.list-item", count: 1)

          within ".cms-tabs" do
            click_link "#{master_site.name}"
            within("a.current") do
              expect(page).to have_css("span", text: master_site.name)
            end
          end
          expect(page).to have_css("tr[data-id='#{page_s2.id}']")
          within ("tr[data-id='#{page_s2.id}']") do 
            find("input[type='checkbox'][value='#{page_s2.id}']").check
          end
          wait_for_ajax
          expect(page).to have_css(".search-ui-select")
          within (".search-ui-select") do 
            click_button I18n.t("cms.apis.pages.select")
          end
        end
        wait_for_cbox_closed do
          within "form#item-form" do
            expect(page).to have_css("tr[data-id='#{page_s2.id}']")
            click_on I18n.t("ss.buttons.draft_save")
          end
        end
        wait_for_notice I18n.t('ss.notice.saved')
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        item = Cms::Page.find(3)
        expect(item.related_page_ids).to include(page_s2.id)
        visit article_page_path(partner_site.id, node, item)
        ensure_addon_opened("#addon-cms-agents-addons-related_page")
        within("#addon-cms-agents-addons-related_page") do 
          expect(page).to have_css("dd", text: page_s2.name)
        end
      end
    end
  end
end