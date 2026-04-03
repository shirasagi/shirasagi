require 'spec_helper'

describe Cms::SysNoticeComponent, type: :component, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let!(:site0) { cms_site }
  let!(:user0) { cms_user }
  let!(:group) { create :cms_group, name: unique_id }
  let!(:site) { create :cms_site_unique, group_ids: [ group.id ] }
  let!(:role) do
    permissions = %w()
    create :cms_role, cur_site: site, site: site, permissions: permissions
  end
  let!(:user) { create :cms_test_user, group_ids: [ group.id ], cms_role_ids: [ role.id ] }

  before do
    @save_perform_caching = described_class.perform_caching
    described_class.perform_caching = true
    Rails.cache.clear
  end

  after do
    described_class.perform_caching = @save_perform_caching
    Rails.cache.clear
  end

  context "without sys notices" do
    it do
      described_class.new(cur_site: site, cur_user: user).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        html = render_inline component
        expect(html.to_s).to be_blank
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        # ショートカットが存在しない場合、キャッシュは作成されない
        expect(component.cache_exist?).to be_falsey
      end
    end
  end

  context "with sys notices" do
    let!(:notice_high1) do
      create(
        :sys_notice, state: "public", notice_severity: "high", notice_target: %w(cms_admin),
        released: now - 4.hours, release_date: nil, close_date: nil)
    end
    let!(:notice_high2_1) do
      create(
        :sys_notice, state: "public", notice_severity: "high", notice_target: %w(cms_admin),
        released: now - 3.hours, release_date: nil, close_date: nil)
    end
    let!(:notice_high2_2) do
      create(
        :sys_notice, state: "closed", notice_severity: "high", notice_target: %w(cms_admin),
        released: now - 3.hours, release_date: nil, close_date: nil)
    end
    let!(:notice_high3) do
      create(
        :sys_notice, state: "public", notice_severity: "high", notice_target: %w(cms_admin),
        released: now - 2.hours, release_date: nil, close_date: nil)
    end

    let!(:notice_normal1) do
      create(
        :sys_notice, state: "public", notice_severity: "normal", notice_target: %w(cms_admin),
        released: now - 4.hours, release_date: nil, close_date: nil)
    end
    let!(:notice_normal2_1) do
      create(
        :sys_notice, state: "public", notice_severity: "normal", notice_target: %w(cms_admin),
        released: now - 3.hours, release_date: nil, close_date: nil)
    end
    let!(:notice_normal2_2) do
      create(
        :sys_notice, state: "closed", notice_severity: "normal", notice_target: %w(cms_admin),
        released: now - 3.hours, release_date: nil, close_date: nil)
    end
    let!(:notice_normal3) do
      create(
        :sys_notice, state: "public", notice_severity: "normal", notice_target: %w(cms_admin),
        released: now - 2.hours, release_date: nil, close_date: nil)
    end

    let!(:notice_out_of_date1) do
      create(
        :sys_notice, state: "public", notice_target: %w(cms_admin),
        released: now, release_date: nil, close_date: now - 1.day)
    end
    let!(:notice_out_of_date2) do
      create(
        :sys_notice, state: "public", notice_target: %w(cms_admin),
        released: now, release_date: now + 1.day, close_date: nil)
    end

    it do
      # テスト開始時点ではキャッシュは存在しない
      described_class.new(cur_site: site, cur_user: user).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        html = render_inline component
        html.css(".list-item").tap do |links|
          expect(links).to have(5).items
          expect(links[0].css(".title").text).to eq notice_high3.name
          expect(links[1].css(".title").text).to eq notice_high2_1.name
          expect(links[2].css(".title").text).to eq notice_high1.name
          expect(links[3].css(".title").text).to eq notice_normal3.name
          expect(links[4].css(".title").text).to eq notice_normal2_1.name
        end
        html.css(".notices-more").tap do |more_elements|
          expect(more_elements).to have(1).items
        end

        # 初回描画時でも最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        # お知らせが存在する場合、キャッシュされる
        expect(component.cache_exist?).to be_truthy
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        render_inline component

        # 最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1
      end

      # user1 が閲覧可能なお知らせを変更する
      notice_high2_1.without_record_timestamps do
        notice_high2_1.update!(state: "closed")
      end
      notice_high2_2.without_record_timestamps do
        notice_high2_2.update!(state: "public")
      end
      notice_normal2_1.without_record_timestamps do
        notice_normal2_1.update!(state: "closed")
      end
      notice_normal2_2.without_record_timestamps do
        notice_normal2_2.update!(state: "public")
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        expect(component.cache_exist?).to be_falsey
      end

      described_class.new(cur_site: site, cur_user: user).tap do |component|
        before_mongodb_count = MongoAccessCounter.succeeded_count

        html = render_inline component
        html.css(".list-item").tap do |links|
          expect(links).to have(5).items
          expect(links[0].css(".title").text).to eq notice_high3.name
          expect(links[1].css(".title").text).to eq notice_high2_2.name
          expect(links[2].css(".title").text).to eq notice_high1.name
          expect(links[3].css(".title").text).to eq notice_normal3.name
          expect(links[4].css(".title").text).to eq notice_normal2_2.name
        end
        html.css(".notices-more").tap do |more_elements|
          expect(more_elements).to have(1).items
        end

        # 初回描画時でも最小限のDBアクセスでキャッシュを利用可能なことを確認
        after_mongodb_count = MongoAccessCounter.succeeded_count
        expect(after_mongodb_count - before_mongodb_count).to eq 1
      end
    end
  end
end
