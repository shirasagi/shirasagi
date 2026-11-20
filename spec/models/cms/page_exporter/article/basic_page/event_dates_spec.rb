require 'spec_helper'

describe Cms::PageExporter, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:today) { Time.zone.today }
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site }

  describe "#enum_csv" do
    context "event dates" do
      let!(:event_recurr1) do
        { kind: "date", start_at: "2022/01/12", frequency: "daily", until_on: "2022/01/19", exclude_dates: [ "2022/01/15" ] }
      end
      let!(:event_recurr2) do
        { kind: "datetime", start_at: now.change(hour: 12), end_at: now.change(hour: 13), frequency: "daily", until_on: today }
      end
      let!(:page1) do
        create(
          :article_page, cur_site: site, cur_node: node,
          event_name: "event_name-#{unique_id}", event_recurrences: [ event_recurr1, event_recurr2 ],
          event_deadline: Time.zone.parse("2021/12/15 17:30"))
      end

      it do
        exporter = described_class.new(mode: "article", site: site, criteria: Article::Page.all, form: nil)
        io = StringIO.new(exporter.enum_csv(encoding: "UTF-8").to_a.join)
        SS::Csv.open(io) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          csv_table[0].tap do |csv_row|
            expect(csv_row[Article::Page.t(:event_name)]).to eq page1.event_name
            expect(csv_row[Article::Page.t(:event_deadline)]).to eq I18n.l(page1.event_deadline, format: :csv)
            "#{Article::Page.t(:event_recurrences)}_1_開始日".tap do |header|
              expect(csv_row[header]).to eq I18n.l(page1.event_recurrences[0].start_date.to_date, format: :picker)
            end
            "#{Article::Page.t(:event_recurrences)}_1_終了日".tap do |header|
              expect(csv_row[header]).to eq I18n.l(page1.event_recurrences[0].until_on.to_date, format: :picker)
            end
            "#{Article::Page.t(:event_recurrences)}_1_開始時刻".tap do |header|
              expect(csv_table.headers).to include(header)
              expect(csv_row[header]).to be_blank
            end
            "#{Article::Page.t(:event_recurrences)}_1_終了時刻".tap do |header|
              expect(csv_table.headers).to include(header)
              expect(csv_row[header]).to be_blank
            end
            "#{Article::Page.t(:event_recurrences)}_1_曜日".tap do |header|
              expect(csv_row[header]).to eq "毎日"
            end
            "#{Article::Page.t(:event_recurrences)}_1_除外日".tap do |header|
              expect(csv_row[header]).to eq page1.event_recurrences[0].exclude_dates.first
            end
            "#{Article::Page.t(:event_recurrences)}_2_開始日".tap do |header|
              expect(csv_row[header]).to eq I18n.l(page1.event_recurrences[1].start_date.to_date, format: :picker)
            end
            "#{Article::Page.t(:event_recurrences)}_2_終了日".tap do |header|
              expect(csv_row[header]).to eq I18n.l(page1.event_recurrences[1].until_on.to_date, format: :picker)
            end
            "#{Article::Page.t(:event_recurrences)}_2_開始時刻".tap do |header|
              expect(csv_row[header]).to eq I18n.l(page1.event_recurrences[1].start_datetime, format: :hh_mm)
            end
            "#{Article::Page.t(:event_recurrences)}_2_終了時刻".tap do |header|
              expect(csv_row[header]).to eq I18n.l(page1.event_recurrences[1].end_datetime, format: :hh_mm)
            end
            "#{Article::Page.t(:event_recurrences)}_2_曜日".tap do |header|
              expect(csv_row[header]).to eq "毎日"
            end
            "#{Article::Page.t(:event_recurrences)}_2_除外日".tap do |header|
              expect(csv_table.headers).to include(header)
              expect(csv_row[header]).to be_blank
            end
          end
        end
      end
    end
  end
end
