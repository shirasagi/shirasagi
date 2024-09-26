require 'spec_helper'

describe "history_cms_backups", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:form) { create(:cms_form, cur_site: site, state: 'public', sub_type: 'entry') }
  let!(:col1) do
    create(:cms_column_text_field, cur_site: site, cur_form: form, input_type: 'text', required: 'optional', order: 5)
  end
  let!(:node) { create :article_node_page, site: site, st_form_ids: [ form.id ], st_form_default: form }

  before { login_cms_user }

  context "case 1: in private" do
    let(:name) { unique_id }

    it do
      #
      # step1: only fill name and save in private
      #
      visit article_pages_path(site: site, cid: node)
      click_on I18n.t("ss.links.new")
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_turbo_frame "#workflow-branch-frame"
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      #
      # step2: add text column and save in private
      #
      visit article_pages_path(site: site, cid: node)
      click_on name
      click_on I18n.t("ss.links.edit")
      wait_for_all_ckeditors_ready
      within "form#item-form" do
        within ".column-value-palette" do
          wait_for_event_fired("ss:columnAdded") do
            click_on col1.name
          end
        end

        within ".column-value-cms-column-textfield" do
          fill_in "item[column_values][][in_wrap][value]", with: unique_id
        end

        click_on I18n.t("ss.buttons.draft_save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      wait_for_turbo_frame "#workflow-branch-frame"
      expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

      expect(Article::Page.all.count).to eq 1
      item = Article::Page.all.first
      expect(item.name).to eq name
      expect(item.column_values.count).to eq 1
      expect(item.state).to eq "closed"
      backups = item.backups.to_a
      expect(backups).to have(2).items

      #
      # step3: restore previous one
      #
      visit article_pages_path(site: site, cid: node)
      click_on name
      within "#addon-history-agents-addons-backup" do
        within "[data-id='#{backups.last.id}']" do
          click_on I18n.t("ss.links.show")
        end
      end

      within ".nav-menu" do
        click_on I18n.t('history.restore')
      end

      within "form" do
        click_on I18n.t('history.buttons.restore')
      end
      wait_for_notice I18n.t("history.notice.restored")

      expect(Job::Log.count).to eq 1
      Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.class_name).to eq "History::Backup::RestoreJob"
        expect(log.args.first).to eq backups.last.id.to_s
      end

      item = Article::Page.all.first
      expect(item.name).to eq name
      expect(item.column_values.count).to eq 0
      expect(item.state).to eq "closed"
    end
  end
end
