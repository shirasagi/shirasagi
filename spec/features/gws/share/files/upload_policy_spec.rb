require 'spec_helper'

describe "gws_share_files_upload_policy", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }

  context "sanitizer setting" do
    before { login_gws_user }

    before { upload_policy_before_settings("sanitizer") }

    after { upload_policy_after_settings }

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
        wait_cbox_open { click_on I18n.t("gws.apis.categories.index") }
      end
      wait_for_cbox do
        wait_cbox_close { click_on category.name }
      end
      within "form#item-form" do
        expect(page).to have_css("#addon-gws-agents-addons-share-category [data-id='#{category.id}']", text: category.name)
        within "#addon-basic" do
          wait_cbox_open { click_on I18n.t('ss.buttons.upload') }
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('.file-view', text: 'keyvisual.jpg')
      expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

      wait_cbox_close do
        wait_cbox_close { click_on "keyvisual.jpg" }
      end
      within '#selected-files' do
        expect(page).to have_css('.name', text: 'keyvisual.jpg')
        expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))
      end

      within "form#item-form" do
        fill_in "item[memo]", with: "new test"
      end
      within "footer.send" do
        click_on I18n.t('ss.buttons.upload')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within '.list-items' do
        expect(page).to have_content('keyvisual.jpg')
        expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))
      end

      file = Gws::Share::File.all.first
      expect(file.sanitizer_state).to eq 'wait'
      expect(Fs.exist?(file.path)).to be_truthy
      expect(Fs.exist?(file.sanitizer_input_path)).to be_truthy
      expect(Fs.cmp(file.path, file.sanitizer_input_path)).to be_truthy

      # show
      click_on file.name
      expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

      # restore
      restored_file = mock_sanitizer_restore(file)
      expect(restored_file.sanitizer_state).to eq 'complete'
      expect(Fs.exist?(restored_file.path)).to be_truthy

      click_on I18n.t('ss.links.back_to_index')
      expect(page).to have_css('.list-items .sanitizer-complete')
      click_on restored_file.name
      expect(page).to have_css('.sanitizer-complete')

      # update
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

      file.reload
      file_path = file.path
      sanitizer_input_path = file.sanitizer_input_path
      expect(Fs.cmp(file.path, sanitizer_input_path)).to be_truthy

      # soft delete
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end

      # hard delete
      visit gws_share_files_path(site)
      click_on I18n.t("ss.links.trash")
      click_on folder.name
      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end
      click_on file.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(Fs.exist?(file_path)).to be_falsey
      expect(Fs.exist?(sanitizer_input_path)).to be_falsey

      within ".tree-navi" do
        expect(page).to have_css(".item-name", text: folder.name)
      end
    end
  end

  context "restricted setting" do
    before { login_gws_user }

    before do
      upload_policy_before_settings('sanitizer')
      site.set(upload_policy: 'restricted')
    end

    after { upload_policy_after_settings }

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
        wait_cbox_open { click_on I18n.t("gws.apis.categories.index") }
      end
      wait_for_cbox do
        wait_cbox_close { click_on category.name }
      end
      within "form#item-form" do
        expect(page).to have_css("#addon-gws-agents-addons-share-category [data-id='#{category.id}']", text: category.name)
        within "#addon-basic" do
          wait_cbox_open { click_on I18n.t('ss.buttons.upload') }
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        page.accept_alert(/#{::Regexp.escape(I18n.t("errors.messages.upload_restricted"))}/) do
          click_on I18n.t("ss.buttons.save")
        end
      end
      expect(page).to have_no_css('.file-view')
      expect(Gws::Share::File.all.count).to eq 0
    end
  end
end
