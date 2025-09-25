require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20250820000000_syntax_check.rb")

RSpec.describe SS::Migration20250820000000, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:travel_to) { now - 2.weeks }
  let!(:site) { cms_site }
  let!(:ss_file) { create :ss_file, site: site }
  let!(:page1) do
    Timecop.freeze(travel_to) do
      create :cms_page, cur_site: site, html: "<img src=\"#{ss_file.url}\" />", file_ids: [ ss_file.id ]
    end
  end

  before do
    described_class.new.change
  end

  it do
    Cms::Page.find(page1.id).tap do |after_page|
      expect(after_page.syntax_check_result_checked.in_time_zone).to be_within(30.seconds).of(Time.zone.now)
      expect(after_page.syntax_check_result_violation_count).to eq 1
      # アクセシビリティチェック結果を更新しても、ページの更新日時は変わらない
      expect(after_page.updated.in_time_zone).to eq travel_to
    end
  end
end
