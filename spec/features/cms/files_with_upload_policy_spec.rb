require 'spec_helper'

describe "cms_files_with_upload_policy", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:index_path) { cms_files_path site.id }
  let(:new_path) { new_cms_file_path site.id }

  context "sanitizer setting" do
    before { login_cms_user }

    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, 'sanitizer')
      Fs.mkdir_p(SS.config.ss.sanitizer_input)
      Fs.mkdir_p(SS.config.ss.sanitizer_output)
    end

    after do
      Fs.rm_rf(SS.config.ss.sanitizer_input)
      Fs.rm_rf(SS.config.ss.sanitizer_output)
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

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
      output_path = "#{SS.config.ss.sanitizer_output}/#{file.id}_filename_100_marked.#{file.extname}"
      Fs.mv file.sanitizer_input_path, output_path
      file.sanitizer_restore_file(output_path)
      expect(file.sanitizer_state).to eq 'complete'

      visit index_path
      expect(page).to have_no_css('.list-items .sanitizer-wait')
      click_on file.name
      expect(page).to have_no_css('.sanitizer-wait')

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
  end

  context "restricted setting" do
    before { login_cms_user }

    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, 'sanitizer')
      site.update_attributes(upload_policy: 'restricted')
    end

    after do
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

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
