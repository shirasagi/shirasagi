require 'spec_helper'

describe "cms_all_contents", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }

  describe "download_all" do
    let!(:layout) { create(:cms_layout, cur_site: site) }
    let!(:cate) { create(:category_node_node, cur_site: site) }
    let!(:node) do
      create(:article_node_page, cur_site: site, layout: layout, category_ids: [ cate.id ], group_ids: [ cms_group.id ])
    end
    let!(:item) do
      create(
        :article_page, cur_site: site, cur_node: node, layout: layout, category_ids: [ cate.id ],
        group_ids: [ cms_group.id ]
      )
    end

    it do
      login_user user, to: cms_all_contents_path(site: site)
      perform_enqueued_jobs do
        wait_for_cbox_opened do
          wait_for_event_fired "turbo:frame-load" do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.download")
            end
          end
        end
      end

      wait_for_download

      expect(Job::Log.all.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(Cms::FileGenTask.all.site(site).count).to eq 1
      task = Cms::FileGenTask.all.site(site).first
      expect(task.job_id).to be_present
      expect(task.file_basename).to eq "all_contents"
      expect(File.size(task.generated_file_path)).to be > 0

      expect(SS::Notification.all.count).to eq 1
      notification = SS::Notification.all.first
      expect(notification.group_id).to be_blank
      expect(notification.member_ids).to eq [ user.id ]
      expect(notification.user_id).to eq user.id
      subject = "[#{site.name}][#{I18n.t("cms.all_contents")} #{I18n.t("cms.all_content.download_tab")}] CSVダウンロード準備完了のお知らせ"
      expect(notification.subject).to eq subject
      expect(notification.text).to be_present
      path = Rails.application.routes.url_helpers.sns_apis_file_gen_task_download_path(id: task)
      expect(notification.text).to include(path)
      expect(notification.html).to be_blank
      expect(notification.format).to eq "text"
      expect(notification.user_settings).to be_blank
      expect(notification.state).to eq "public"
      expect(notification.send_date.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
      expect(notification.url).to be_blank
      expect(notification.reply_module).to be_blank
      expect(notification.reply_model).to be_blank
      expect(notification.reply_item_id).to be_blank

      SS::Csv.open(downloads.first) do |csv|
        table = csv.read

        expect(table.length).to eq 3
        expect(table.headers).to include(*%w(page_id node_id route).map { I18n.t("all_content.#{_1}") })
        table[0].tap do |row|
          expect(row[I18n.t("all_content.page_id")]).to be_present
          expect(row[I18n.t("all_content.node_id")]).to be_blank
          expect(row[I18n.t("all_content.route")]).to be_present
        end
        table[1].tap do |row|
          expect(row[I18n.t("all_content.page_id")]).to be_blank
          expect(row[I18n.t("all_content.node_id")]).to be_present
          expect(row[I18n.t("all_content.route")]).to be_present
        end
        table[2].tap do |row|
          expect(row[I18n.t("all_content.page_id")]).to be_blank
          expect(row[I18n.t("all_content.node_id")]).to be_present
          expect(row[I18n.t("all_content.route")]).to be_present
        end
      end
    end
  end
end
