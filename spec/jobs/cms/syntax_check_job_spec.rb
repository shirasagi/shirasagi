require 'spec_helper'

describe Cms::SyntaxCheckJob, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:travel_to) { now - 2.weeks }
  let!(:site) { cms_site }

  context "when a page has no syntax check result" do
    let!(:ss_file) { create :ss_file, site: site }
    let!(:page1) do
      Timecop.freeze(travel_to) do
        create :cms_page, cur_site: site, html: "<img src=\"#{ss_file.url}\" />", file_ids: [ ss_file.id ]
      end
    end

    it do
      Cms::Page.find(page1.id).tap do |before_page|
        expect(before_page.syntax_check_result_checked).to be_blank
        expect(before_page.syntax_check_result_violation_count).to be_blank
        expect(before_page.updated.in_time_zone).to eq travel_to
      end

      described_class.bind(site_id: site.id).perform_now

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Page.find(page1.id).tap do |after_page|
        expect(after_page.syntax_check_result_checked.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(after_page.syntax_check_result_violation_count).to eq 1
        # アクセシビリティチェック結果を更新しても、ページの更新日時は変わらない
        expect(after_page.updated.in_time_zone).to eq travel_to
      end
    end
  end

  context "when a page has a syntax check result which is sufficient enough" do
    let!(:ss_file) { create :ss_file, site: site }
    let!(:page1) do
      Timecop.freeze(travel_to) do
        page = create(:cms_page, cur_site: site, html: "<img src=\"#{ss_file.url}\" />", file_ids: [ ss_file.id ])
        page.set(syntax_check_result_checked: travel_to - described_class::THRESHOLD, syntax_check_result_violation_count: 1)
        page
      end
    end

    it do
      Cms::Page.find(page1.id).tap do |before_page|
        expect(before_page.syntax_check_result_checked).to eq travel_to - described_class::THRESHOLD
        expect(before_page.syntax_check_result_violation_count).to eq 1
        expect(before_page.updated.in_time_zone).to eq travel_to
      end

      described_class.bind(site_id: site.id).perform_now

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Page.find(page1.id).tap do |after_page|
        expect(after_page.syntax_check_result_checked.in_time_zone).to eq travel_to - described_class::THRESHOLD
        expect(after_page.syntax_check_result_violation_count).to eq 1
        expect(after_page.updated.in_time_zone).to eq travel_to
      end
    end
  end

  context "when a page has a syntax check result which is sufficient enough, but force option is activated" do
    let!(:ss_file) { create :ss_file, site: site }
    let!(:page1) do
      Timecop.freeze(travel_to) do
        page = create(:cms_page, cur_site: site, html: "<img src=\"#{ss_file.url}\" />", file_ids: [ ss_file.id ])
        page.set(syntax_check_result_checked: travel_to - described_class::THRESHOLD, syntax_check_result_violation_count: 1)
        page
      end
    end

    it do
      Cms::Page.find(page1.id).tap do |before_page|
        expect(before_page.syntax_check_result_checked).to eq travel_to - described_class::THRESHOLD
        expect(before_page.syntax_check_result_violation_count).to eq 1
        expect(before_page.updated.in_time_zone).to eq travel_to
      end

      described_class.bind(site_id: site.id).perform_now(force: true)

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Page.find(page1.id).tap do |after_page|
        expect(after_page.syntax_check_result_checked.in_time_zone).not_to eq travel_to - described_class::THRESHOLD
        expect(after_page.syntax_check_result_checked.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(after_page.syntax_check_result_violation_count).to eq 1
        # アクセシビリティチェック結果を更新しても、ページの更新日時は変わらない
        expect(after_page.updated.in_time_zone).to eq travel_to
      end
    end
  end

  context "when a page has a syntax check result which is not sufficient" do
    let!(:ss_file) { create :ss_file, site: site }
    let!(:page1) do
      Timecop.freeze(travel_to) do
        page = create(:cms_page, cur_site: site, html: "<img src=\"#{ss_file.url}\" />", file_ids: [ ss_file.id ])
        page.set(
          syntax_check_result_checked: travel_to - described_class::THRESHOLD - 1.second,
          syntax_check_result_violation_count: 1)
        page
      end
    end

    it do
      Cms::Page.find(page1.id).tap do |before_page|
        expect(before_page.syntax_check_result_checked).to eq travel_to - described_class::THRESHOLD - 1.second
        expect(before_page.syntax_check_result_violation_count).to eq 1
        expect(before_page.updated.in_time_zone).to eq travel_to
      end

      described_class.bind(site_id: site.id).perform_now

      expect(Job::Log.count).to eq 1
      Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      Cms::Page.find(page1.id).tap do |after_page|
        expect(after_page.syntax_check_result_checked.in_time_zone).not_to eq travel_to - described_class::THRESHOLD
        expect(after_page.syntax_check_result_checked.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
        expect(after_page.syntax_check_result_violation_count).to eq 1
        expect(after_page.updated.in_time_zone).to eq travel_to
      end
    end
  end
end
