require 'spec_helper'
require Rails.root.join("lib/migrations/map/20200318000000_fix_latlon_order.rb")

RSpec.describe SS::Migration20200318000000, dbscope: :example do
  before do
    described_class.new.change
  end

  it do
    # put your specs here
  end
end
