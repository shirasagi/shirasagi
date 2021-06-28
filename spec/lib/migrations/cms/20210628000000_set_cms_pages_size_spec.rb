require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20210628000000_set_cms_pages_size.rb")

RSpec.describe SS::Migration20210628000000, dbscope: :example do
  let(:page) { create :cms_page }
  let(:html) { unique_id }

  before do
    page.set(html: html)
    described_class.new.change
  end

  it do
    page.reload
    expect(page.size).to eq html.bytesize
  end
end
