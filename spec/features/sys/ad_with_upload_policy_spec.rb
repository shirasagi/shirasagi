require 'spec_helper'

describe "sys_ad_with_upload_policy", type: :feature, dbscope: :example, js: true do
  let(:user) { sys_user }
  let(:group) { create(:gws_group) }

  before { login_sys_user }

  context "sanitizer setting" do
    before { upload_policy_before_settings("sanitizer") }

    after { upload_policy_after_settings }

    it do
      visit sys_ad_path
      click_on I18n.t("ss.links.edit")

      # update
      within "form#item-form" do
        fill_in "item[time]", with: rand(1..10)
        fill_in "item[width]", with: rand(1..100)
        within "#addon-ss-agents-addons-link_file" do
          wait_cbox_open { click_on I18n.t('ss.buttons.upload') }
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_on I18n.t("ss.buttons.save")
        expect(page).to have_css('.file-view', text: 'keyvisual.jpg')
        expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

        wait_cbox_close do
          click_on 'keyvisual.jpg'
        end
      end
      within '.column-thumb' do
        expect(page).to have_css('.name', text: SS::File.find_by(name: 'keyvisual.jpg').humanized_name)
        expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      file = SS::LinkFile.all.first
      expect(file.sanitizer_state).to eq 'wait'
      expect(Fs.exist?(file.path)).to be_truthy
      expect(Fs.exist?(file.sanitizer_input_path)).to be_truthy

      # restore
      restored_file = mock_sanitizer_restore(file)
      expect(restored_file.sanitizer_state).to eq 'complete'
      expect(Fs.exist?(restored_file.path)).to be_truthy

      visit sys_ad_path
      expect(page).to have_css('#selected-files .sanitizer-complete')
      click_on I18n.t("ss.links.edit")
      expect(page).to have_css('.index.ajax-selected .sanitizer-complete')
    end
  end

  context "restricted setting" do
    before do
      upload_policy_before_settings('sanitizer')
      user.set(organization_id: group.id)
      group.set(upload_policy: 'restricted')
    end

    after { upload_policy_after_settings }

    it do
      visit sys_ad_path
      click_on I18n.t("ss.links.edit")

      # update
      within "form#item-form" do
        fill_in "item[time]", with: rand(1..10)
        fill_in "item[width]", with: rand(1..100)
        within "#addon-ss-agents-addons-link_file" do
          wait_cbox_open { click_on I18n.t('ss.buttons.upload') }
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        page.accept_alert do
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_no_css('.file-view')
      end
      expect(SS::LinkFile.all.count).to eq 0
    end
  end
end
