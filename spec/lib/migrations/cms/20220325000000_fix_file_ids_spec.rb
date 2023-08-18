require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20220325000000_fix_file_ids.rb")

RSpec.describe SS::Migration20220325000000, dbscope: :example do
  let!(:site1) { create :cms_site_unique }
  let!(:site2) { create :cms_site_unique }
  let!(:site3) { create :cms_site_unique }

  it do
    expectation = expect { described_class.new.change }
    expectation.to output(include(site1.name)).to_stdout
    expectation.to output(include(site2.name)).to_stdout
    expectation.to output(include(site3.name)).to_stdout
  end
end
