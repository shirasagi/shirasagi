require 'spec_helper'

describe Article::Page::ExportJob, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }
  let!(:task) do
    task = Cms::FileGenTask.new(cur_site: site, cur_user: user)
    task.name = "article_pages_download_#{user.id}"
    task.file_basename = "article_pages"
    task.file_format = "csv"
    task.params = { "encoding" => "UTF-8", "form_id" => "-1", "truncate" => "yes" }
    task.save!
    task
  end

  describe "#perform" do
    context "order" do
      let!(:page1) { Timecop.freeze(now - 5.hours) { create :article_page, cur_site: site, cur_node: node } }
      let!(:page2) { Timecop.freeze(now - 4.hours) { create :article_page, cur_site: site, cur_node: node } }

      it do
        job = described_class.bind(site_id: site, user_id: user, node_id: node, task_id: task)
        expect { ss_perform_now(job) }.to output.to_stdout

        expect(Job::Log.count).to eq 1
        Job::Log.all.each do |log|
          expect(log.logs).to include(/INFO -- : .* Started Job/)
          expect(log.logs).to include(/INFO -- : .* Completed Job/)
        end

        task.reload
        expect(task.job_id).to be_present
        expect(File.size(task.generated_file_path)).to be > 0

        expect(SS::Notification.all.count).to eq 1
        notification = SS::Notification.all.first
        expect(notification.group_id).to be_blank
        expect(notification.member_ids).to eq [ cms_user.id ]
        expect(notification.user_id).to eq cms_user.id
        expect(notification.subject).to eq "[#{site.name}][#{node.name}] CSVダウンロード準備完了のお知らせ"
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

        SS::Csv.open(task.generated_file_path) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 2
          # updated_desc order
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:filename)]).to eq page2.basename
            expect(csv_row[Article::Page.t(:name)]).to eq page2.name
          end
          csv_table[1].tap do |csv_row|
            expect(csv_row[Article::Page.t(:filename)]).to eq page1.basename
            expect(csv_row[Article::Page.t(:name)]).to eq page1.name
          end
        end
      end
    end
  end
end
