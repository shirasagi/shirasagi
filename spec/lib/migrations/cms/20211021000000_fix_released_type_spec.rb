require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20211021000000_fix_released_type.rb")

RSpec.describe SS::Migration20211021000000, dbscope: :example do
  let(:site) { cms_site }
  let!(:page1) { create :cms_page, cur_site: site, state: "public" }

  before do
    page1.unset(:released_type)

    described_class.new.change
  end

  it do
    page1.reload
    expect(page1.released_type).to eq "fixed"
  end
end
