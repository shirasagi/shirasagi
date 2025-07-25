require 'spec_helper'
require Rails.root.join("lib/migrations/20250725000000_create_migration_file.rb")

RSpec.describe SS::Migration20250725000000, dbscope: :example do
  before do
    described_class.new.change
  end

  it do
    # put your specs here
  end
end
