require 'spec_helper'
require Rails.root.join("lib/migrations/ss/20211116000000_set_file_name.rb")

RSpec.describe SS::Migration20211116000000, dbscope: :example do
  let!(:file1) { SS::File.create!(model: "ss/file", filename: "#{unique_id}.txt") }
  let!(:file2) { Member::PhotoFile.create!(model: "member/photo", filename: "#{unique_id}.png") }

  before do
    file1.unset(:name)
    file1.reload
    expect(file1.name).to be_blank

    file2.unset(:name)
    file2.reload
    expect(file2.name).to be_blank

    described_class.new.change
  end

  it do
    file1.reload
    expect(file1.name).to be_present

    file2.reload
    expect(file2.name).to be_present
  end
end
