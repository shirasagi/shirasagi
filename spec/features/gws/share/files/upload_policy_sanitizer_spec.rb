require 'spec_helper'

describe "gws_share_files_upload_policy_sanitizer", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }

  before { login_gws_user }

  before do
    @save_config = SS.config.ss.upload_policy
    SS.config.replace_value_at(:ss, :upload_policy, 'sanitizer')
  end

  after do
    SS::File.each do |file|
      Fs.rm_rf(file.path) if Fs.exists?(file.path)
      Fs.rm_rf(file.sanitizer_input_path) if Fs.exists?(file.sanitizer_input_path)
    end
    SS.config.replace_value_at(:ss, :upload_policy, @save_config)
  end

  context "basic crud" do
    it do
      visit gws_share_files_path(site)
      click_on folder.name

      #
      # Create
      #
      click_on I18n.t("ss.links.new")
      click_on I18n.t("gws.apis.categories.index")
      wait_for_cbox do
        click_on category.name
      end
      within "form#item-form" do
        within "#addon-basic" do
          wait_cbox_open do
            click_on I18n.t('ss.buttons.upload')
          end
        end
      end

      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')
        expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

        wait_cbox_close do
          click_on "keyvisual.jpg"
        end
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

      expect(Gws::Share::File.all.count).to eq 1
      file = Gws::Share::File.all.first
      expect(file.sanitizer_state).to eq 'wait'
      expect(Fs.exists?(file.path)).to be_truthy
      expect(Fs.exists?(file.sanitizer_input_path)).to be_truthy

      #
      # Show
      #
      visit gws_share_files_path(site)
      click_on folder.name
      click_on file.name
      expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

      #
      # Update
      #
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

      #
      # Soft Delete
      #
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      #
      # Hard Delete
      #
      visit gws_share_files_path(site)
      click_on I18n.t("ss.links.trash")
      click_on folder.name
      click_on file.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect(Fs.exists?(file_path)).to be_falsey
      expect(Fs.exists?(sanitizer_input_path)).to be_falsey
    end
  end
end
