require 'spec_helper'

describe "cms_search_contents_pages", type: :feature, dbscope: :example, js: true do
  context "destroy_all" do
    let!(:category_filename) { unique_id }

    let!(:site1) do
      create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp", group_ids: cms_user.group_ids
    end
    let!(:site1_role) { create :cms_role_admin, site: site1 }
    let!(:site1_category1) { create :category_node_page, cur_site: site1, filename: category_filename }
    let!(:site1_article_node) { create :article_node_page, cur_site: site1 }
    let!(:site1_article_page) do
      create :article_page, cur_site: site1, cur_node: site1_article_node, category_ids: [ site1_category1.id ]
    end

    let!(:site2) do
      create :cms_site, name: unique_id, host: unique_id, domains: "#{unique_id}.example.jp", group_ids: cms_user.group_ids
    end
    let!(:site2_role) { create :cms_role_admin, site: site2 }
    let!(:site2_category1) { create :category_node_page, cur_site: site2, filename: category_filename }
    let!(:site2_article_node) { create :article_node_page, cur_site: site2 }
    let!(:site2_article_page) do
      create :article_page, cur_site: site2, cur_node: site2_article_node, category_ids: [ site2_category1.id ]
    end

    before do
      user = cms_user
      user.add_to_set(cms_role_ids: [ site1_role.id, site2_role.id ])
      user.reload

      login_cms_user
    end

    context "on site1" do
      it do
        visit cms_search_contents_pages_path(site: site1)

        wait_cbox_open do
          click_on I18n.t("cms.apis.categories.index")
        end
        wait_for_cbox do
          wait_cbox_close do
            click_on site1_category1.name
          end
        end
        expect(page).to have_content(site1_category1.name)

        click_on I18n.t("ss.buttons.search")
        expect(page).to have_css(".list-head", text: I18n.t("cms.search_contents_count", count: 1))
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 1)
        end

        wait_for_js_ready
        within ".list-head" do
          wait_event_to_fire("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
          click_button I18n.t('ss.buttons.delete')
        end
        click_button I18n.t('ss.buttons.delete')

        wait_cbox_open do
          click_on I18n.t("cms.apis.categories.index")
        end
        wait_for_cbox do
          wait_cbox_close do
            click_on site1_category1.name
          end
        end
        expect(page).to have_content(site1_category1.name)

        click_on I18n.t("ss.buttons.search")
        expect(page).to have_css(".list-head", text: I18n.t("cms.search_contents_count", count: 0))
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 0)
        end
      end
    end

    context "on site2" do
      it do
        visit cms_search_contents_pages_path(site: site2)

        wait_cbox_open do
          click_on I18n.t("cms.apis.categories.index")
        end
        wait_for_cbox do
          wait_cbox_close do
            click_on site2_category1.name
          end
        end
        expect(page).to have_content(site2_category1.name)

        click_on I18n.t("ss.buttons.search")
        expect(page).to have_css(".list-head", text: I18n.t("cms.search_contents_count", count: 1))
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 1)
        end

        wait_for_js_ready
        within ".list-head" do
          wait_event_to_fire("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
          click_button I18n.t('ss.buttons.delete')
        end
        click_button I18n.t('ss.buttons.delete')

        wait_cbox_open do
          click_on I18n.t("cms.apis.categories.index")
        end
        wait_for_cbox do
          wait_cbox_close do
            click_on site2_category1.name
          end
        end
        expect(page).to have_content(site2_category1.name)

        click_on I18n.t("ss.buttons.search")
        expect(page).to have_css(".list-head", text: I18n.t("cms.search_contents_count", count: 0))
        within ".list-items" do
          expect(page).to have_css(".list-item", count: 0)
        end
      end
    end
  end
end
