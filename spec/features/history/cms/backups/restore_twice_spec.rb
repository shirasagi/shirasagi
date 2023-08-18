require 'spec_helper'

describe "history_cms_backups restore", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:file) { create :ss_file, user_id: cms_user.id }
  let(:page_item) do
    page_item = create(:article_page, cur_node: node)
    Timecop.travel(1.day.from_now) do
      page_item.name = "first update"
      page_item.state = "public"
      page_item.file_ids = [file.id]
      page_item.update
    end
    Timecop.travel(2.days.from_now) do
      page_item.name = "second update"
      page_item.state = "closed"
      page_item.file_ids = []
      page_item.index_name = "second index_name"
      page_item.update
    end
    page_item
  end
  let(:backup_item) { page_item.backups.find { |item| item.data["name"] == "first update" } }
  let(:page_path) { article_page_path site.id, node, page_item }
  let(:show_path) do
    source = ERB::Util.url_encode(page_path)
    history_cms_backup_path site.id, source, backup_item._id
  end
  let(:restore_path) do
    source = ERB::Util.url_encode(page_path)
    history_cms_restore_path site.id, source, backup_item._id
  end

  context "duplicated restore protection" do
    before { login_cms_user }

    context "task is already running" do
      let(:task) { SS::Task.create(site_id: site.id, name: "cms_pages:#{page_item.id}") }

      before do
        expect(task.start).to be_truthy
      end

      it do
        visit page_path
        click_link I18n.l(backup_item.created, format: :picker)

        click_link I18n.t("history.restore")
        click_button I18n.t("history.buttons.restore")

        expect(page).to have_css(".errorExplanation", text: I18n.t('errors.messages.other_task_is_running'))
      end
    end

    context "other job that user executed is on the schedule" do
      before do
        args = []
        Job::Task.create!(
          user_id: cms_user.id, name: SecureRandom.uuid, class_name: "History::Trash::RestoreJob", app_type: "cms",
          pool: "default", args: args, active_job: {
            "job_class" => "History::Trash::RestoreJob", "job_id" => SecureRandom.uuid, "provider_job_id" => nil,
            "queue_name" => "default", "priority" => nil, "arguments" => args
          }
        )
      end

      it do
        visit page_path
        click_link I18n.l(backup_item.created, format: :picker)

        click_link I18n.t("history.restore")
        click_button I18n.t("history.buttons.restore")

        expect(page).to have_css(".errorExplanation", text: I18n.t('errors.messages.other_task_is_running'))
      end
    end
  end
end
