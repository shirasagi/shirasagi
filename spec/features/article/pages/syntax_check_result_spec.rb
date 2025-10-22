require 'spec_helper'

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }

  context "with Cms::Addon::Body" do
    let(:name) { unique_id }
    let(:html) { "<p>#{unique_id}</p>" }

    it do
      login_cms_user to: article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in_ckeditor "item[html]", with: html

        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      wait_for_all_ckeditors_ready

      expect(Article::Page.all.count).to eq 1
      first_syntax_check_result_checked = nil
      Article::Page.all.first.tap do |new_page|
        expect(new_page.site_id).to eq site.id
        expect(new_page.name).to eq name
        expect(new_page.filename).to start_with(node.filename)
        expect(new_page.html).to eq html

        expect(new_page.syntax_check_result_checked&.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(new_page.syntax_check_result_violation_count).to eq 0

        first_syntax_check_result_checked = new_page.syntax_check_result_checked.in_time_zone
      end

      click_on I18n.t("ss.links.edit")
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      wait_for_all_ckeditors_ready

      expect(Article::Page.all.count).to eq 1
      Article::Page.all.first.tap do |edit_page|
        expect(edit_page.syntax_check_result_checked&.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(edit_page.syntax_check_result_checked&.in_time_zone).to be > first_syntax_check_result_checked
        expect(edit_page.syntax_check_result_violation_count).to eq 0
      end
    end
  end

  context "with Cms::Addon::Form::Page" do
    let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
    let!(:column1) do
      create(:cms_column_free, cur_site: site, cur_form: form, required: "optional")
    end
    let(:name) { unique_id }
    let(:html) { "<p>#{unique_id}</p>" }

    before do
      node.update!(st_form_ids: [ form.id ])
    end

    it do
      login_cms_user to: article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready

      within 'form#item-form' do
        wait_for_event_fired("ss:formActivated") do
          page.accept_confirm(I18n.t("cms.confirm.change_form")) do
            select form.name, from: 'in_form_id'
          end
        end
      end
      wait_for_all_ckeditors_ready

      within "form#item-form" do
        fill_in "item[name]", with: name

        within first(".column-value-cms-column-free") do
          fill_in_ckeditor "item[column_values][][in_wrap][value]", with: html
        end

        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      wait_for_all_ckeditors_ready

      expect(Article::Page.all.count).to eq 1
      first_syntax_check_result_checked = nil
      Article::Page.all.first.tap do |new_page|
        expect(new_page.site_id).to eq site.id
        expect(new_page.name).to eq name
        expect(new_page.filename).to start_with(node.filename)
        expect(new_page.column_values.first.value).to eq html

        expect(new_page.syntax_check_result_checked&.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(new_page.syntax_check_result_violation_count).to eq 0

        first_syntax_check_result_checked = new_page.syntax_check_result_checked.in_time_zone
      end

      click_on I18n.t("ss.links.edit")
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      wait_for_all_ckeditors_ready

      expect(Article::Page.all.count).to eq 1
      Article::Page.all.first.tap do |edit_page|
        expect(edit_page.syntax_check_result_checked&.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(edit_page.syntax_check_result_checked&.in_time_zone).to be > first_syntax_check_result_checked
        expect(edit_page.syntax_check_result_violation_count).to eq 0
      end
    end
  end
end
