require 'spec_helper'

describe "cms_files_with_upload_policy", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:index_path) { cms_files_path site.id }
  let(:new_path) { new_cms_file_path site.id }

  context "sanitizer setting" do
    before { login_cms_user }

    before { upload_policy_before_settings("sanitizer") }

    after { upload_policy_after_settings }

    it do
      visit index_path

      # create
      visit new_path
      within "form#item-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within '.list-items' do
        expect(page).to have_content('logo.png')
        expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))
      end

      file = Cms::File.all.first
      expect(file.sanitizer_state).to eq 'wait'
      expect(Fs.exists?(file.path)).to be_truthy
      expect(Fs.exists?(file.sanitizer_input_path)).to be_truthy

      # show
      click_on file.name
      expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

      # restore
      restored_file = mock_sanitizer_restore(file)
      expect(restored_file.sanitizer_state).to eq 'complete'
      expect(Fs.exists?(restored_file.path)).to be_truthy

      visit index_path
      expect(page).to have_css('.list-items .sanitizer-complete')
      click_on restored_file.name
      expect(page).to have_css('.sanitizer-complete')

      # update
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

      # delete
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_button I18n.t('ss.buttons.delete')
      end
      expect(current_path).to eq index_path
    end

    it do
      # create
      visit new_path
      within "form#item-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      # sanitizer_setting is nil
      upload_policy_before_settings(nil)

      # update
      file = Cms::File.all.first
      visit edit_cms_file_path(site: site.id, id: file.id)
      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).not_to have_css('.sanitizer-wait')

      file = Cms::File.all.first
      expect(file.sanitizer_state).to eq nil
    end
  end

  context "restricted setting" do
    before { login_cms_user }

    before do
      upload_policy_before_settings('sanitizer')
      site.set(upload_policy: 'restricted')
    end

    after { upload_policy_after_settings }

    it do
      # create
      visit new_path
      within "form#item-form" do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/logo.png"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css("#errorExplanation")
      expect(Cms::File.all.count).to eq 0
    end
  end
end
