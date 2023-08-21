require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20221214000000_aggregation_groups.rb")

RSpec.describe SS::Migration20221214000000, dbscope: :example do
  it do
    create_affair_users
    expect(Gws::Aggregation::Group.count).to eq 0

    require 'rake'
    Rails.application.load_tasks
    described_class.new.change

    expect(Gws::Aggregation::Group.count).to eq 10
  end
end
