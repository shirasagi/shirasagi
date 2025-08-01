require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20250801000000_member_file_site_id.rb")

RSpec.describe SS::Migration20250801000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:member) { cms_member(site: site) }

  let(:content_path) { "#{Rails.root}/spec/fixtures/ss/logo.png" }
  let!(:file1) do
    tmp_ss_file(Member::File, contents: content_path, model: 'member/temp_file', cur_member: member)
  end

  before do
    expect(file1.site_id).to be_blank
    expect(file1.model).to eq "member/temp_file"

    described_class.new.change
  end

  it do
    SS::File.find(file1.id).tap do |file_after_migration|
      file_after_migration = file_after_migration.becomes_with_model
      expect(file_after_migration).to be_a(Member::File)
      expect(file_after_migration.site_id).to eq site.id
      expect(file_after_migration.model).to eq "member/temp_file"
    end
  end
end
