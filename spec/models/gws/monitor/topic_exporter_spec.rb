require 'spec_helper'

RSpec.describe Gws::Monitor::TopicExporter, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}", order: 10) }
  let!(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}", order: 20) }
  let!(:topic1) do
    Timecop.freeze(5.hours.ago) do
      create(
        :gws_monitor_topic, user: user, attend_group_ids: [g1.id, g2.id],
        state: 'public', article_state: 'open', spec_config: 'my_group',
        answer_state_hash: { g1.id.to_s => "answered", g2.id.to_s => "answered" }
      )
    end
  end
  let!(:g1_post1) do
    Timecop.freeze(4.hours.ago) do
      create(:gws_monitor_post, user: user, user_group_id: g1.id, user_group_name: g1.name, parent_id: topic1.id)
    end
  end
  let!(:g1_post2) do
    Timecop.freeze(3.hours.ago) do
      create(:gws_monitor_post, user: user, user_group_id: g1.id, user_group_name: g1.name, parent_id: topic1.id)
    end
  end
  let!(:g2_post1) do
    Timecop.freeze(4.hours.ago) do
      create(:gws_monitor_post, user: user, user_group_id: g2.id, user_group_name: g2.name, parent_id: topic1.id)
    end
  end

  context "download comment is 'all'" do
    it do
      exporter = Gws::Monitor::TopicExporter.new(cur_site: site, cur_user: user, item: topic1)
      enumerable = exporter.enum_csv(encoding: "UTF-8", download_comment: "all")
      source = enumerable.to_a.join
      source.force_encoding(Encoding::ASCII_8BIT)
      SS::Csv.open(StringIO.new(source)) do |csv|
        table = csv.read
        expect(table.headers).to include(*I18n.t('gws/monitor.csv'))
        expect(table.length).to eq 3
        table[0].tap do |row|
          expect(row[0]).to eq topic1.id.to_s
          expect(row[1]).to eq topic1.name
          expect(row[2]).to eq I18n.t("gws/monitor.options.answer_state.answered")
          expect(row[3]).to eq g1.name
          expect(row[4]).to eq g1_post2.contributor_name
          expect(row[5]).to eq g1_post2.text
          expect(row[6]).to eq I18n.l(g1_post2.updated, format: :picker)
        end
        table[1].tap do |row|
          expect(row[0]).to be_blank
          expect(row[1]).to be_blank
          expect(row[2]).to be_blank
          expect(row[3]).to be_blank
          expect(row[4]).to eq g1_post1.contributor_name
          expect(row[5]).to eq g1_post1.text
          expect(row[6]).to eq I18n.l(g1_post1.updated, format: :picker)
        end
        table[2].tap do |row|
          expect(row[0]).to be_blank
          expect(row[1]).to be_blank
          expect(row[2]).to eq I18n.t("gws/monitor.options.answer_state.answered")
          expect(row[3]).to eq g2.name
          expect(row[4]).to eq g2_post1.contributor_name
          expect(row[5]).to eq g2_post1.text
          expect(row[6]).to eq I18n.l(g2_post1.updated, format: :picker)
        end
      end
    end
  end

  context "download comment is 'last'" do
    it do
      exporter = Gws::Monitor::TopicExporter.new(cur_site: site, cur_user: user, item: topic1)
      enumerable = exporter.enum_csv(encoding: "UTF-8", download_comment: "last")
      source = enumerable.to_a.join
      source.force_encoding(Encoding::ASCII_8BIT)
      SS::Csv.open(StringIO.new(source)) do |csv|
        table = csv.read
        expect(table.headers).to include(*I18n.t('gws/monitor.csv'))
        expect(table.length).to eq 2
        table[0].tap do |row|
          expect(row[0]).to eq topic1.id.to_s
          expect(row[1]).to eq topic1.name
          expect(row[2]).to eq I18n.t("gws/monitor.options.answer_state.answered")
          expect(row[3]).to eq g1.name
          expect(row[4]).to eq g1_post2.contributor_name
          expect(row[5]).to eq g1_post2.text
          expect(row[6]).to eq I18n.l(g1_post2.updated, format: :picker)
        end
        table[1].tap do |row|
          expect(row[0]).to be_blank
          expect(row[1]).to be_blank
          expect(row[2]).to eq I18n.t("gws/monitor.options.answer_state.answered")
          expect(row[3]).to eq g2.name
          expect(row[4]).to eq g2_post1.contributor_name
          expect(row[5]).to eq g2_post1.text
          expect(row[6]).to eq I18n.l(g2_post1.updated, format: :picker)
        end
      end
    end
  end
end
