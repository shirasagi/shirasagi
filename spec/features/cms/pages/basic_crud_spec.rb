require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example do
  subject(:site) { cms_site }
  subject(:index_path) { cms_pages_path site.id }
  let!(:item2) { create(:cms_page) }
  let!(:html) { "<p><a href=\"#{item2.url}\">関連記事リンク1</a></p>" }
  let!(:item3) { create(:cms_page, html: html) }
  subject(:delete_path2) { delete_cms_page_path site.id, item2 }
  subject(:delete_path3) { delete_cms_page_path site.id, item3 }

  describe "basic crud" do
    before { login_cms_user }

    it do
      #
      # new
      #
      visit new_cms_page_path(site.id)
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200

      item = Cms::Page.last
      expect(item.name).to eq "sample"
      expect(item.filename).to eq "sample.html"

      #
      # show
      #
      visit cms_page_path(site.id, item)
      expect(status_code).to eq 200
      expect(page).to have_content("sample.html")

      #
      # edit
      #
      visit edit_cms_page_path(site.id, item)
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200

      item.reload
      expect(item.name).to eq "modify"
      expect(item.filename).to eq "sample.html"

      #
      # move
      #
      visit move_cms_page_path(site.id, item)
      within "form" do
        fill_in "destination", with: "destination"
        click_button I18n.t("ss.buttons.move")
      end
      expect(status_code).to eq 200
      expect(page).to have_css("form#item-form .current-filename", text: "destination.html")

      item.reload
      expect(item.name).to eq "modify"
      expect(item.filename).to eq "destination.html"

      visit move_cms_page_path(site.id, item)
      within "form" do
        fill_in "destination", with: "sample"
        click_button I18n.t("ss.buttons.move")
      end
      expect(status_code).to eq 200
      expect(page).to have_css("form#item-form .current-filename", text: "sample.html")

      item.reload
      expect(item.name).to eq "modify"
      expect(item.filename).to eq "sample.html"

      #
      # copy
      #
      visit copy_cms_page_path(site.id, item)
      within "form" do
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200
      expect(page).to have_css("a", text: "[#{I18n.t('workflow.cloned_name_prefix')}] modify")
      expect(page).to have_css(".state", text: I18n.t("ss.state.edit"))

      expect(Cms::Page.count).to eq 4

      #
      # contains_urls
      #
      visit contains_urls_cms_page_path(site.id, item)
      expect(status_code).to eq 200

      #
      # delete
      #
      visit delete_cms_page_path(site.id, item)
      within "form" do
        click_button I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')
      expect(current_path).to eq index_path
    end

    context "other delete pattern" do
      let(:user) { cms_user }

      it "permitted and contains_urls" do
        visit delete_path2
        expect(page).to have_css(".delete")
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        wait_for_notice I18n.t('ss.notice.deleted')
        expect(current_path).to eq index_path
      end

      it "not permitted and contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(delete_private_cms_pages delete_other_cms_pages))
        visit delete_path2
        expect(page).not_to have_css(".delete")
        expect(page).to have_css(".addon-head", text: I18n.t('ss.confirm.contains_url_expect'))
      end

      it "not permitted and not contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(delete_private_cms_pages delete_other_cms_pages))
        visit delete_path3
        expect(page).to have_css(".delete")
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        wait_for_notice I18n.t('ss.notice.deleted')
        expect(current_path).to eq index_path
      end
    end
  end
end

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  subject(:site) { cms_site }
  let!(:item2) { create(:cms_page) }
  let!(:html) { "<p><a href=\"#{item2.url}\">関連記事リンク1</a></p>" }
  let!(:item3) { create(:cms_page, html: html) }
  subject(:edit_path2) { edit_cms_page_path site.id, item2 }
  subject(:edit_path3) { edit_cms_page_path site.id, item3 }

  describe "basic crud" do
    before { login_cms_user }
    context "#draft_save" do
      let(:user) { cms_user }

      it "permitted and contains_urls" do
        visit edit_path2
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end

        new_window = nil
        within_cbox do
          expect(page).to have_content(I18n.t('cms.confirm.close'))
          expect(page).to have_link(I18n.t('cms.confirm.check_contains_urls'))
          expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))

          new_window = window_opened_by { click_on I18n.t('cms.confirm.check_contains_urls') }
        end

        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          expect(page).to have_css(".list-head", text: I18n.t("cms.confirm.contains_urls_exists"))
          expect(page).to have_css(".list-item", text: item3.name)
          expect(page).to have_css(".list-item", count: 1)
        end
      end

      it "permitted and not contains_urls" do
        visit edit_path3
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end

        within_cbox do
          expect(page).to have_content(I18n.t('cms.confirm.close'))
          expect(page).to have_no_content(I18n.t('cms.confirm.check_contains_urls'))
          expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
        end
      end

      it "not permitted and contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(
          read_private_cms_pages read_other_cms_pages
          edit_private_cms_pages edit_other_cms_pages
          release_private_cms_pages release_other_cms_pages
          close_private_cms_pages close_other_cms_pages))
        visit edit_path2
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end

        new_window = nil
        within_cbox do
          expect(page).to have_css(".errorExplanation", text: I18n.t('cms.confirm.close'))
          expect(page).to have_link(I18n.t('cms.confirm.check_contains_urls'))
          expect(page).to have_css(".errorExplanation", text: I18n.t('ss.confirm.contains_url_expect'))
          expect(page).not_to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))

          new_window = window_opened_by { click_on I18n.t('cms.confirm.check_contains_urls') }
        end

        within_window new_window do
          wait_for_document_loading
          wait_for_js_ready
          expect(page).to have_css(".list-head", text: I18n.t("cms.confirm.contains_urls_exists"))
          expect(page).to have_css(".list-item", text: item3.name)
          expect(page).to have_css(".list-item", count: 1)
        end
      end

      it "not permitted and not contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(
          read_private_cms_pages read_other_cms_pages
          edit_private_cms_pages edit_other_cms_pages
          release_private_cms_pages release_other_cms_pages
          close_private_cms_pages close_other_cms_pages))
        visit edit_path3
        wait_for_all_ckeditors_ready
        within "form#item-form" do
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.withdraw") }
        end

        within_cbox do
          expect(page).to have_css(".errorExplanation", text: I18n.t('cms.confirm.close'))
          expect(page).to have_no_link(I18n.t('cms.confirm.check_contains_urls'))
          expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
        end
      end
    end
  end
end
