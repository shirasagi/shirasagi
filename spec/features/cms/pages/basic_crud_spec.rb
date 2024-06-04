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
      expect(page).to have_css("a", text: "[複製] modify")
      expect(page).to have_css(".state", text: "非公開")

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
      expect(current_path).to eq index_path
    end

    context "other delete pattern" do
      let(:user) { cms_user }

      it "permited and contains_urls" do
        visit delete_path2
        expect(page).to have_css(".delete")
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        expect(current_path).to eq index_path
        wait_for_notice I18n.t('ss.notice.deleted')
      end

      it "not permited and contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(delete_private_cms_pages delete_other_cms_pages))
        visit delete_path2
        expect(page).not_to have_css(".delete")
        expect(page).to have_css(".addon-head", text: I18n.t('ss.confirm.contains_url_expect'))
      end

      it "not permited and not contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(delete_private_cms_pages delete_other_cms_pages))
        visit delete_path3
        expect(page).to have_css(".delete")
        within "form" do
          click_on I18n.t("ss.buttons.delete")
        end
        expect(current_path).to eq index_path
        wait_for_notice I18n.t('ss.notice.deleted')
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

      it "permited and contains_urls" do
        visit edit_path2
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      end

      it "permited and not contains_urls" do
        visit edit_path3
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      end

      it "not permited and contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(edit_private_cms_pages edit_other_cms_pages
                                    release_private_cms_pages release_other_cms_pages
                                    close_private_cms_pages close_other_cms_pages))
        visit edit_path2
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        expect(page).not_to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
        expect(page).to have_css(".errorExplanation", text: I18n.t('ss.confirm.contains_url_expect'))
      end

      it "not permited and not contains_urls" do
        role = user.cms_roles[0]
        role.update(permissions: %w(edit_private_cms_pages edit_other_cms_pages
                                    release_private_cms_pages release_other_cms_pages
                                    close_private_cms_pages close_other_cms_pages))
        visit edit_path3
        within "form" do
          click_on I18n.t("ss.buttons.withdraw")
        end
        expect(page).to have_css('.save', text: I18n.t('ss.buttons.ignore_alert'))
      end
    end
  end
end
