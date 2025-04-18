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
        fill_in "item[time]", with: rand(5..10)
        fill_in "item[width]", with: rand(300..400)

        within first("[data-index]") do
          fill_in "item[ad_links][][url]", with: unique_url
          upload_to_ss_file_field "item[ad_links][][file_id]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        end

        within first("[data-index]") do
          expect(page).to have_css('.humanized-name', text: SS::File.find_by(name: 'keyvisual.jpg').humanized_name)
          expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))
        end

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      file = SS::File.find_by(name: 'keyvisual.jpg')
      expect(file.sanitizer_state).to eq 'wait'
      expect(Fs.exist?(file.path)).to be_truthy
      expect(Fs.exist?(file.sanitizer_input_path)).to be_truthy

      # restore
      restored_file = mock_sanitizer_restore(file)
      expect(restored_file.sanitizer_state).to eq 'complete'
      expect(Fs.exist?(restored_file.path)).to be_truthy

      visit sys_ad_path
      expect(page).to have_css('.file-view .sanitizer-complete', text: I18n.t('ss.options.sanitizer_state.complete'))
      click_on I18n.t("ss.links.edit")
      within first("[data-index]") do
        expect(page).to have_css('.sanitizer-complete', text: I18n.t('ss.options.sanitizer_state.complete'))
      end
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
        fill_in "item[time]", with: rand(5..10)
        fill_in "item[width]", with: rand(200..300)
        within first("[data-index]") do
          fill_in "item[ad_links][][url]", with: unique_url
          wait_for_cbox_opened { click_on I18n.t('ss.buttons.upload') }
        end
      end
      within_dialog do
        wait_event_to_fire "ss:tempFile:addedWaitingList" do
          attach_file "in_files", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        end
      end
      within_dialog do
        within "form" do
          within first(".index tbody tr") do
            expect(page).to have_css(".errors", text: I18n.t("errors.messages.upload_restricted"))
          end
        end
      end
      page.execute_script('$(".errors").html("");')

      # エラーが表示されているが、それでもアップロードしてみる。
      within_dialog do
        within "form" do
          click_on I18n.t("ss.buttons.upload")
        end
      end
      within_dialog do
        within "form" do
          within first(".index tbody tr") do
            expect(page).to have_css(".errors", text: I18n.t("errors.messages.upload_restricted"))
          end
        end
      end

      expect(SS::File.all.count).to eq 0
    end
  end
end
