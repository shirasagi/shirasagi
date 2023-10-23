require 'spec_helper'

describe Cms::GenerationReport::NodesController, type: :feature, dbscope: :example do
  let!(:site) { cms_site }

  before { login_cms_user }

  context "without task 'cms:generate_nodes'" do
    it do
      visit cms_generation_report_main_path(site: site)
      expect(page).to have_content("フォルダー書き出しが一度も実行されていません。")

      visit cms_generation_report_nodes_path(site: site)
      expect(page).to have_content("フォルダー書き出しが一度も実行されていません。")
    end
  end

  context "with task 'cms:generate_nodes'" do
    let!(:task) { Cms::Task.create!(site_id: site.id, node_id: nil, name: 'cms:generate_nodes', state: 'ready') }

    before do
      ::FileUtils.mkdir_p(::File.dirname(task.perf_log_file_path))
      ::File.open(task.perf_log_file_path, "wt") do |f|
        f.puts({}.to_json)
      end
    end

    context "without title" do
      it do
        visit cms_generation_report_main_path(site: site)
        click_on I18n.t("ss.links.new")
        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css("#notice", text: I18n.t("cms.notices.generation_report_jos_is_started"))

        expect(enqueued_jobs.length).to eq 1
        enqueued_jobs.first.tap do |enqueued_job|
          expect(enqueued_job[:job]).to eq Cms::GenerationReportCreateJob
          expect(enqueued_job[:args]).to be_blank
        end
      end
    end

    context "with title" do
      let!(:title) { create :cms_generation_report_title, cur_site: site, task: task }
      let!(:content) { create :article_node_page, cur_site: site }
      let(:history_type1) { "node" }
      let(:history1_db) { rand }
      let(:history1_view) { rand }
      let(:history1_elapsed) { rand }
      let(:history1_total_db) { history1_db + rand }
      let(:history1_total_view) { history1_view + rand }
      let(:history1_total_elapsed) { history1_elapsed + rand }
      let!(:history1) do
        Cms::GenerationReport::History[title].create!(
          cur_site: site, site: site, task: task, title: title, history_type: history_type1,
          content: content, content_name: content.name, content_filename: content.filename,
          db: history1_db, view: history1_view, elapsed: history1_elapsed,
          total_db: history1_total_db, total_view: history1_total_view, total_elapsed: history1_total_elapsed)
      end
      let(:aggregation1_db) { rand }
      let(:aggregation1_view) { rand }
      let(:aggregation1_elapsed) { rand }
      let(:aggregation1_total_db) { aggregation1_db + rand }
      let(:aggregation1_total_view) { aggregation1_view + rand }
      let(:aggregation1_total_elapsed) { aggregation1_elapsed + rand }
      let(:aggregation1_average_db) { rand }
      let(:aggregation1_average_view) { rand }
      let(:aggregation1_average_elapsed) { rand }
      let(:aggregation1_average_total_db) { aggregation1_average_db + rand }
      let(:aggregation1_average_total_view) { aggregation1_average_view + rand }
      let(:aggregation1_average_total_elapsed) { aggregation1_average_elapsed + rand }
      let!(:aggregation1) do
        Cms::GenerationReport::Aggregation[title].create!(
          cur_site: site, site: site, task: task, title: title, history_type: history_type1,
          content: content, content_name: content.name, content_filename: content.filename,
          db: aggregation1_db, view: aggregation1_view, elapsed: aggregation1_elapsed,
          total_db: aggregation1_total_db, total_view: aggregation1_total_view, total_elapsed: aggregation1_total_elapsed,
          sub_total_db: 0, sub_total_view: 0, sub_total_elapsed: 0,
          average_db: aggregation1_average_db, average_view: aggregation1_average_view,
          average_elapsed: aggregation1_average_elapsed,
          average_total_db: aggregation1_average_total_db, average_total_view: aggregation1_average_total_view,
          average_total_elapsed: aggregation1_average_total_elapsed,
          average_sub_total_db: 0, average_sub_total_view: 0, average_sub_total_elapsed: 0)
      end

      context "basic crud" do
        it do
          visit cms_generation_report_main_path(site: site)
          expect(page).to have_css(".list-item", text: title.name)

          click_on title.name
          within "[data-id='#{history1.id}']" do
            expect(page).to have_content(history1.total_db.round(3))
          end

          click_on I18n.t("mongoid.models.cms/generation_report/aggregation")
          within "[data-id='#{aggregation1.id}']" do
            expect(page).to have_content(aggregation1.db.round(3))
          end
        end
      end

      context "download" do
        it do
          visit cms_generation_report_main_path(site: site)
          click_on title.name
          click_on I18n.t("ss.links.download")

          within "form#item-form" do
            click_on I18n.t("ss.buttons.download")
          end

          csv = ::SS::ChunkReader.new(page.html).to_a.join
          csv.force_encoding("UTF-8")
          csv = csv[1..-1]
          SS::Csv.open(StringIO.new(csv)) do |csv|
            table = csv.read
            expect(table.length).to eq 1
            expect(table.headers).to include(history1.class.t(:history_type), history1.class.t(:db))
            expect(table[0][history1.class.t(:history_type)]).to eq history1.history_type
            expect(table[0][history1.class.t(:content_id)]).to eq content.id.to_s
            expect(table[0][history1.class.t(:content_name)]).to eq content.name
            expect(table[0][history1.class.t(:content_filename)]).to eq content.filename
            expect(table[0][history1.class.t(:content_type)]).to eq content.class.name
            expect(table[0][history1.class.t(:db)].to_f).to be_within(0.001).of(history1.db)
            expect(table[0][history1.class.t(:view)].to_f).to be_within(0.001).of(history1.view)
            expect(table[0][history1.class.t(:elapsed)].to_f).to be_within(0.001).of(history1.elapsed)
          end
        end
      end
    end
  end
end
