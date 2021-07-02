require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let!(:template) do
    create(:cms_source_cleaner_template, site: site, target_type: 'attribute', target_value: 'style', action_type: 'remove')
  end

  context "source_cleaner" do
    it do
      login_cms_user
      visit new_cms_page_path(site)

      html_text = '<p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p>'
      html_text += '<p><span style="display: none;"><font size="+1">あいうえおカキクケコ</font></span></p>'
      html_text += '<p>&nbsp;</p>'
      html_text += '<p class="MsoNormal">あいうえおカキクケコ</p>'

      within "form#item-form" do
        fill_in "item[name]", with: unique_id
        fill_in "item[basename]", with: unique_id
        fill_in_ckeditor "item[html]", with: html_text
        page.accept_confirm do
          click_on I18n.t("cms.source_cleaner")
        end
        sleep 1
        click_button I18n.t('ss.buttons.publish_save')
      end

      expect(page).to have_no_css("form#item-form")

      Cms::Page.first.tap do |item|
        expect(item.html).to include '<p>あいうえおカキクケコ</p>'
        expect(item.html).not_to include '<p><span><font size="+1">あいうえおカキクケコ</font></span></p>'
        expect(item.html).not_to include '<p>&nbsp;</p>'
        expect(item.html).not_to include '<p class="MsoNormal">あいうえおカキクケコ</p>'
      end
    end

    context 'when source_cleaner_unwrap_tag_state is disabled' do
      before do
        site.source_cleaner_unwrap_tag_state = 'disabled'
        site.save!
      end

      it do
        login_cms_user
        visit new_cms_page_path(site)

        html_text = '<p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p>'
        html_text += '<p><span style="display: none;"><font size="+1">あいうえおカキクケコ</font></span></p>'
        html_text += '<p>&nbsp;</p>'
        html_text += '<p class="MsoNormal">あいうえおカキクケコ</p>'

        within "form#item-form" do
          fill_in "item[name]", with: unique_id
          fill_in "item[basename]", with: unique_id
          fill_in_ckeditor "item[html]", with: html_text
          page.accept_confirm do
            click_on I18n.t("cms.source_cleaner")
          end
          sleep 1
          click_button I18n.t('ss.buttons.publish_save')
        end

        expect(page).to have_no_css("form#item-form")

        Cms::Page.first.tap do |item|
          expect(item.html).to include '<p>あいうえおカキクケコ</p>'
          expect(item.html).to include '<p><span><font size="+1">あいうえおカキクケコ</font></span></p>'
          expect(item.html).not_to include '<p>&nbsp;</p>'
          expect(item.html).not_to include '<p class="MsoNormal">あいうえおカキクケコ</p>'
        end
      end
    end

    context 'when source_cleaner_remove_tag_state is disabled' do
      before do
        site.source_cleaner_remove_tag_state = 'disabled'
        site.save!
      end

      it do
        login_cms_user
        visit new_cms_page_path(site)

        html_text = '<p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p>'
        html_text += '<p><span style="display: none;"><font size="+1">あいうえおカキクケコ</font></span></p>'
        html_text += '<p>&nbsp;</p>'
        html_text += '<p class="MsoNormal">あいうえおカキクケコ</p>'

        within "form#item-form" do
          fill_in "item[name]", with: unique_id
          fill_in "item[basename]", with: unique_id
          fill_in_ckeditor "item[html]", with: html_text
          page.accept_confirm do
            click_on I18n.t("cms.source_cleaner")
          end
          sleep 1
          click_button I18n.t('ss.buttons.publish_save')
        end

        expect(page).to have_no_css("form#item-form")

        Cms::Page.first.tap do |item|
          expect(item.html).to include '<p>あいうえおカキクケコ</p>'
          expect(item.html).not_to include '<p><span><font size="+1">あいうえおカキクケコ</font></span></p>'
          expect(item.html).to include '<p>&nbsp;</p>'
          expect(item.html).not_to include '<p class="MsoNormal">あいうえおカキクケコ</p>'
        end
      end
    end

    context 'when source_cleaner_remove_class_state is disabled' do
      before do
        site.source_cleaner_remove_class_state = 'disabled'
        site.save!
      end

      it do
        login_cms_user
        visit new_cms_page_path(site)

        html_text = '<p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p>'
        html_text += '<p><span style="display: none;"><font size="+1">あいうえおカキクケコ</font></span></p>'
        html_text += '<p>&nbsp;</p>'
        html_text += '<p class="MsoNormal">あいうえおカキクケコ</p>'

        within "form#item-form" do
          fill_in "item[name]", with: unique_id
          fill_in "item[basename]", with: unique_id
          fill_in_ckeditor "item[html]", with: html_text
          page.accept_confirm do
            click_on I18n.t("cms.source_cleaner")
          end
          sleep 1
          click_button I18n.t('ss.buttons.publish_save')
        end

        expect(page).to have_no_css("form#item-form")

        Cms::Page.first.tap do |item|
          expect(item.html).to include '<p>あいうえおカキクケコ</p>'
          expect(item.html).not_to include '<p><span><font size="+1">あいうえおカキクケコ</font></span></p>'
          expect(item.html).not_to include '<p>&nbsp;</p>'
          expect(item.html).to include '<p class="MsoNormal">あいうえおカキクケコ</p>'
        end
      end
    end
  end
end
