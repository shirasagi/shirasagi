require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20220705000000_purge_monitor_zip.rb")

RSpec.describe SS::Migration20220705000000, dbscope: :example do
  let(:root_path) { Gws::Monitor::Topic.new.download_root_path }
  let(:file_path1) { "#{root_path}/1/4/9/_/149" }

  before do
    ::FileUtils.mkdir_p ::File.dirname(file_path1)
    ::File.open(file_path1, "wb") do |f|
      f.write unique_id
    end
    expect(::File.size(file_path1)).to be > 0

    described_class.new.change
  end

  it do
    expect(::File.exist?(file_path1)).to be_falsey
  end
end
