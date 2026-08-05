require 'spec_helper'

describe "gws_share_files_download_policy", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }

  context "sanitizer setting" do
    before { login_gws_user }

    before do
      @save_config = SS.config.replace_value_at(:ss, :download_policy, 'disallowed')
    end

    after do
      SS.config.replace_value_at(:ss, :download_policy, @save_config)
    end

    it do
      visit gws_share_files_path(site)
      click_on folder.name
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      # create
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      within "form#item-form" do
        wait_for_cbox_opened { click_on I18n.t("gws.apis.categories.index") }
      end
      within_cbox do
        wait_for_cbox_closed { click_on category.name }
      end
      within "form#item-form" do
        expect(page).to have_css("#addon-gws-agents-addons-share-category [data-id='#{category.id}']", text: category.name)
        within "#addon-basic" do
          wait_for_cbox_opened { click_on I18n.t('ss.buttons.upload') }
        end
      end
      within_dialog do
        wait_for_event_fired "ss:tempFile:addedWaitingList" do
          attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        end
        within first("form .index tbody tr") do
          # 全角括弧と全角数字を入力
          fill_in "item[files][][name]", with: "ファイル（１）.jpg"
        end
        wait_for_cbox_closed do
          within_dialog do
            within "form" do
              click_on I18n.t("ss.buttons.upload")
            end
          end
        end
      end
      within '.file-view' do
        # 全角括弧と全角数字は半角へ自動的に返還される
        expect(page).to have_css('.name', text: "ファイル(1).jpg")
      end

      within "form#item-form" do
        fill_in "item[memo]", with: "new test"
      end
      within "footer.send" do
        click_on I18n.t('ss.buttons.upload')
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within '.list-items' do
        expect(page).to have_content("ファイル(1).jpg")
      end

      file = Gws::Share::File.all.first
      expect(Fs.exist?(file.path)).to be_truthy

      # show
      click_on file.name
      expect(page).to have_css('.download-disallowed')

      # update
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        fill_in "item[name]", with: "ファイル（２）"
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_content("ファイル(2)")

      expect(page).to have_css('.download-disallowed')
    end
  end
end
