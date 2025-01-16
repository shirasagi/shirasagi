require 'spec_helper'

describe 'cms_agents_addons_file', type: :feature, dbscope: :example, js: true do
  let(:site){ cms_site }
  let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user }
  let(:name) { "#{unique_id}.png" }
  let!(:file_1) { tmp_ss_file contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: cms_user, basename: "#{unique_id}.jpg" }
  let!(:file_2) { tmp_ss_file user: cms_user, basename: "#{unique_id}.jpg" }
  let!(:item1) { create :article_page, cur_site: site, cur_user: cms_user, cur_node: node, file_ids: [ file_1.id ] }

  before do
    login_cms_user
    item1.update(contains_urls: [file_1.url])
  end

  context "attach file from upload" do
    before { login_cms_user }

    it "#edit" do
      visit edit_cms_article_page_path(site, item1)

      ensure_addon_opened("#addon-cms-agents-addons-file")
      within "#addon-cms-agents-addons-file" do
        wait_for_cbox_opened do
          click_on I18n.t("ss.buttons.upload")
        end
      end

      within_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif"
        wait_for_cbox_closed do
          click_button I18n.t("ss.buttons.attach")
        end
      end

      within '#selected-files' do
        expect(page).to have_no_css('.name', text: 'keyvisual.jpg')
        expect(page).to have_css('.name', text: 'keyvisual.gif')
      end
    end

    it "#edit file name" do
      visit edit_cms_article_page_path(site, item1) # 修正

      ensure_addon_opened("#addon-cms-agents-addons-file")
      within "form#item-form" do
        within "#addon-cms-agents-addons-file" do
          wait_for_cbox_opened do
            click_on I18n.t("ss.buttons.upload")
          end
        end
      end

      within_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')

        click_on I18n.t("ss.buttons.edit")
        fill_in "item[name]", with: "modify.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css(".file-view", text: "modify.jpg")

        wait_for_cbox_closed do
          click_on "modify.jpg"
        end
      end

      within '#selected-files' do
        expect(page).to have_css('.name', text: 'modify.jpg')
      end
    end
  end

  context "with article/page" do
    describe "index" do
      it do
        visit article_pages_path(site: site, cid: node)
        click_on I18n.t("ss.links.new")

        expect(page).to have_css(".file-view", text: file_1.name)
        expect(page).to have_css(".file-view unused", text: file_2.name)
      end
    end
  end
end
