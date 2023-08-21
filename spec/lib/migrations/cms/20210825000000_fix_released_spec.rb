require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20210825000000_fix_released.rb")

RSpec.describe SS::Migration20210825000000, dbscope: :example do
  let(:now) { Time.zone.now.change(usec: 0) }
  let(:site) { cms_site }
  let(:page1_released) { now - rand(1..10).days }
  let!(:page1_fixed) { create :cms_page, cur_site: site, state: "public" }
  let!(:page2_same_as_updated) { create :article_page, cur_site: site, state: "public" }
  let!(:page3_same_as_created) { create :article_page, cur_site: site, state: "public" }
  let!(:page4_same_as_first_released) { create :article_page, cur_site: site, state: "public" }
  let(:page5_released) { now - rand(1..10).days }
  let!(:page5_rss) { create :rss_page, cur_site: site, state: "public" }

  before do
    page1_fixed.set(released_type: "fixed", released: page1_released.utc)

    page2_same_as_updated.set(released_type: "same_as_updated")
    page2_same_as_updated.unset(:released)

    page3_same_as_created.set(released_type: "same_as_created")
    page3_same_as_created.unset(:released)

    page4_same_as_first_released.set(released_type: "same_as_first_released")
    page4_same_as_first_released.unset(:released)

    page5_rss.unset(:released_type)
    page5_rss.set(released: page5_released.utc)

    described_class.new.change
  end

  it do
    page1_fixed.reload
    expect(page1_fixed.released).to eq page1_released

    page2_same_as_updated.reload
    expect(page2_same_as_updated.released).to eq page2_same_as_updated.updated

    page3_same_as_created.reload
    expect(page3_same_as_created.released).to eq page3_same_as_created.created

    page4_same_as_first_released.reload
    expect(page4_same_as_first_released.released).to eq page4_same_as_first_released.first_released

    page5_rss.reload
    expect(page5_rss.released_type).to eq "fixed"
    expect(page5_rss.released).to eq page5_released
  end
end
