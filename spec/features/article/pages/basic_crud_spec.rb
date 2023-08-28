require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:item) { create(:article_page, cur_node: node) }
  let!(:item2) { create(:article_page, cur_node: node) }
  let!(:html) { "<p><a href=\"#{item2.url}\">関連記事リンク1</a></p>" }
  let!(:item3) { create(:article_page, cur_node: node, html: html) }
  let(:index_path) { article_pages_path site.id, node }
  let(:new_path) { new_article_page_path site.id, node }
  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }
  let(:edit_path2) { edit_article_page_path site.id, node, item2 }
  let(:delete_path) { delete_article_page_path site.id, node, item }
  let(:delete_path2) { delete_article_page_path site.id, node, item2 }
  let(:move_path) { move_article_page_path site.id, node, item }
  let(:copy_path) { copy_article_page_path site.id, node, item }
  let(:contains_urls_path) { contains_urls_article_page_path site.id, node, item }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        click_on I18n.t("ss.links.input")
        fill_in "item[basename]", with: "sample"
        click_on I18n.t("ss.buttons.draft_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
    end

    it "#move" do
      visit move_path
      within "form#item-form" do
        fill_in "destination", with: "docs/destination"
        click_on I18n.t("ss.buttons.move")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.moved'))
      within "form#item-form" do
        expect(page).to have_css(".current-filename", text: "docs/destination.html")
        expect(page).to have_css(".result", text: I18n.t("article.count"))
      end

      within "form#item-form" do
        fill_in "destination", with: "docs/sample"
        click_on I18n.t("ss.buttons.move")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.moved'))
      within "form#item-form" do
        expect(page).to have_css(".current-filename", text: "docs/sample.html")
        expect(page).to have_css(".result", text: I18n.t("article.count"))
      end
    end

    it "#copy" do
      visit copy_path
      within "form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css("a", text: "[複製] #{item.name}")
      expect(page).to have_css(".state", text: "非公開")
    end

    context "#delete" do
      let(:user) { cms_user }

      it "permited and contains_urls" do
        visit delete_path2
        expect(page).to have_css(".delete")
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      end

      it "permited and not contains_urls" do
        visit delete_path
        expect(page).to have_css(".delete")
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      end

      it "not permited and contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(delete_private_article_pages delete_other_article_pages))
        visit delete_path2
        expect(page).not_to have_css(".delete")
        expect(page).to have_css(".addon-head", text: I18n.t('ss.confirm.contains_url_expect'))
      end

      it "not permited and not contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(delete_private_article_pages delete_other_article_pages))
        visit delete_path
        expect(page).to have_css(".delete")
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      end

      it "destroy_all not permited and contains_urls" do
        role = user.cms_roles[0]
        role_permissions = role.permissions.map do |permission|
          next if permission == "delete_cms_ignore_alert"
          permission
        end
        role.update(permissions: role_permissions.compact)

        visit index_path
        wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
        within ".list-head-action" do
          click_button I18n.t('ss.buttons.delete')
        end
        expect(page).to have_content I18n.t('ss.confirm.contains_links_in_file')
        expect(page).to have_content I18n.t('ss.confirm.target_to_delete')
        click_button I18n.t('ss.buttons.delete')
        wait_for_ajax

        expect(page).to have_content File.basename(item2.filename)
      end

      it "destroy_all & check contain_urls" do
        visit index_path
        wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
        within ".list-head-action" do
          click_button I18n.t('ss.buttons.delete')
        end
        wait_for_ajax

        expect(page).to have_css('.contains-urls', text: I18n.t('ss.confirm.contains_links_in_file_ignoring_alert'))
      end

      it "destroy_all & unable to delete without check" do
        visit index_path
        wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }

        within ".list-head-action" do
          click_button I18n.t('ss.buttons.delete')
        end
        wait_for_ajax

        find('.list-item input[type="checkbox"][checked="checked"]').set(false)
        click_button I18n.t('ss.buttons.delete')
        expect(page.accept_confirm).to eq I18n.t("errors.messages.plz_check_targets_to_delete")
      end
    end

    it "#contains_urls" do
      visit contains_urls_path
      expect(page).to have_css("#addon-basic", text: item.name)
      expect(page).to have_css(".list-head", text: I18n.t("cms.confirm.contains_urls_not_found"))
    end

    context "#draft_save" do
      let(:user) { cms_user }

      it "permited and contains_urls" do
        visit edit_path2
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      end

      it "permited and not contains_urls" do
        visit edit_path
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      end

      it "not permited and contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(edit_private_article_pages edit_other_article_pages
                                    release_private_article_pages release_other_article_pages
                                    close_private_article_pages close_other_article_pages))
        visit edit_path2
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        expect(page).not_to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
        expect(page).to have_css(".errorExplanation", text: I18n.t('ss.confirm.contains_url_expect'))
      end

      it "not permited and not contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(edit_private_article_pages edit_other_article_pages
                                    release_private_article_pages release_other_article_pages
                                    close_private_article_pages close_other_article_pages))
        visit edit_path
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      end
    end
  end

  context "update page without required params" do
    before { login_cms_user }

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        # set to blank
        fill_in "item[name]", with: ""
        click_on I18n.t("ss.buttons.publish_save")
      end
      expect(page).to have_css('#errorExplanation', text: I18n.t('errors.messages.blank'))
    end
  end
end
