require 'spec_helper'

describe "cms/pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:html_text) do
    html = []
    html << '<p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p><p>あいうえおカキクケコ</p>'
    html << '<p><span style="display: none;"><font size="+1">あいうえおカキクケコ</font></span></p>'
    html << '<p>&nbsp;</p>'
    html << '<p class="MsoNormal">あいうえおカキクケコ</p>'
    html << '<p class="unnecessaryClass">あいうえおカキクケコ</p>'
    html << '<p class="necessaryClass">あいうえおカキクケコ</p>'
    html.join("\n")
  end

  def run_source_cleaner
    login_cms_user to: new_cms_page_path(site)
    wait_for_all_ckeditors_ready
    wait_for_all_turbo_frames

    within "form#item-form" do
      fill_in "item[name]", with: unique_id
      fill_in "item[basename]", with: unique_id
      fill_in_ckeditor "item[html]", with: html_text
      wait_for_event_fired "ss:sourceCleanerFinished" do
        page.accept_confirm(I18n.t("cms.confirm.source_clean")) do
          click_on I18n.t("cms.source_cleaner")
        end
      end
      click_button I18n.t('ss.buttons.publish_save')
    end
    wait_for_notice I18n.t("ss.notice.saved")
    expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
    wait_for_all_turbo_frames

    expect(page).to have_no_css("form#item-form")
  end

  context "source_cleaner" do
    let!(:template) do
      create(
        :cms_source_cleaner_template, site: site, state: 'public',
        target_type: 'attribute', target_value: 'style', action_type: 'remove'
      )
    end

    it do
      run_source_cleaner
      Cms::Page.first.tap do |item|
        expect(item.html).to include '<p>あいうえおカキクケコ</p>'
        expect(item.html).not_to include '<p><span><font size="+1">あいうえおカキクケコ</font></span></p>'
        expect(item.html).not_to include '<p>&nbsp;</p>'
        expect(item.html).not_to include '<p class="MsoNormal">あいうえおカキクケコ</p>'
        expect(item.html).to include '<p class="unnecessaryClass">あいうえおカキクケコ</p>'
        expect(item.html).to include '<p class="necessaryClass">あいうえおカキクケコ</p>'
      end
    end

    context 'when source_cleaner_unwrap_tag_state is disabled' do
      before do
        site.source_cleaner_unwrap_tag_state = 'disabled'
        site.save!
      end

      it do
        run_source_cleaner
        Cms::Page.first.tap do |item|
          expect(item.html).to include '<p>あいうえおカキクケコ</p>'
          expect(item.html).to include '<p><span><font size="+1">あいうえおカキクケコ</font></span></p>'
          expect(item.html).not_to include '<p>&nbsp;</p>'
          expect(item.html).not_to include '<p class="MsoNormal">あいうえおカキクケコ</p>'
          expect(item.html).to include '<p class="unnecessaryClass">あいうえおカキクケコ</p>'
          expect(item.html).to include '<p class="necessaryClass">あいうえおカキクケコ</p>'
        end
      end
    end

    context 'when source_cleaner_remove_tag_state is disabled' do
      before do
        site.source_cleaner_remove_tag_state = 'disabled'
        site.save!
      end

      it do
        run_source_cleaner
        Cms::Page.first.tap do |item|
          expect(item.html).to include '<p>あいうえおカキクケコ</p>'
          expect(item.html).not_to include '<p><span><font size="+1">あいうえおカキクケコ</font></span></p>'
          expect(item.html).to include '<p>&nbsp;</p>'
          expect(item.html).not_to include '<p class="MsoNormal">あいうえおカキクケコ</p>'
          expect(item.html).to include '<p class="unnecessaryClass">あいうえおカキクケコ</p>'
          expect(item.html).to include '<p class="necessaryClass">あいうえおカキクケコ</p>'
        end
      end
    end

    context 'when source_cleaner_remove_class_state is disabled' do
      before do
        site.source_cleaner_remove_class_state = 'disabled'
        site.save!
      end

      it do
        run_source_cleaner
        Cms::Page.first.tap do |item|
          expect(item.html).to include '<p>あいうえおカキクケコ</p>'
          expect(item.html).not_to include '<p><span><font size="+1">あいうえおカキクケコ</font></span></p>'
          expect(item.html).not_to include '<p>&nbsp;</p>'
          expect(item.html).to include '<p class="MsoNormal">あいうえおカキクケコ</p>'
          expect(item.html).to include '<p class="unnecessaryClass">あいうえおカキクケコ</p>'
          expect(item.html).to include '<p class="necessaryClass">あいうえおカキクケコ</p>'
        end
      end
    end
  end

  context "when target_type is attribute and action_type is remove and replace_source is present" do
    let!(:template) do
      create(
        :cms_source_cleaner_template, site: site, state: 'public',
        target_type: 'attribute', target_value: 'class', action_type: 'remove', replace_source: 'unnecessaryClass'
      )
    end

    it do
      run_source_cleaner
      Cms::Page.first.tap do |item|
        expect(item.html).to include '<p>あいうえおカキクケコ</p>'
        expect(item.html).not_to include '<p><span><font size="+1">あいうえおカキクケコ</font></span></p>'
        expect(item.html).not_to include '<p>&nbsp;</p>'
        expect(item.html).not_to include '<p class="MsoNormal">あいうえおカキクケコ</p>'
        expect(item.html).not_to include '<p class="unnecessaryClass">あいうえおカキクケコ</p>'
        expect(item.html).to include '<p class="necessaryClass">あいうえおカキクケコ</p>'
      end
    end
  end

  context "when target_type is attribute and action_type is replace and replace_source is present" do
    let!(:template) do
      create(
        :cms_source_cleaner_template, site: site, state: 'public',
        target_type: 'attribute', target_value: 'class',
        action_type: 'replace', replace_source: 'unnecessaryClass', replaced_value: 'replacedClass'
      )
    end

    it do
      run_source_cleaner
      Cms::Page.first.tap do |item|
        expect(item.html).to include '<p>あいうえおカキクケコ</p>'
        expect(item.html).not_to include '<p><span><font size="+1">あいうえおカキクケコ</font></span></p>'
        expect(item.html).not_to include '<p>&nbsp;</p>'
        expect(item.html).not_to include '<p class="MsoNormal">あいうえおカキクケコ</p>'
        expect(item.html).not_to include '<p class="unnecessaryClass">あいうえおカキクケコ</p>'
        expect(item.html).to include '<p class="necessaryClass">あいうえおカキクケコ</p>'
      end
    end
  end
end
