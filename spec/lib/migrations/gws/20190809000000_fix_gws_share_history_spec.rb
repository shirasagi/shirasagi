require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20190809000000_fix_gws_share_history.rb")

RSpec.describe SS::Migration20190809000000, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:file1) do
    file = tmp_ss_file(contents: unique_id, user: user)
    file.set(model: "share/file")
    Gws::Share::File.find(file.id)
  end
  let!(:file1_history1) do
    Gws::Share::History.create!(
      cur_user: user, site_id: site.id, name: file1.name, model: "gws/share/file", item_id: file1.id,
      uploadfile_name: file1.name, uploadfile_filename: file1.filename, uploadfile_srcname: "history-1",
      uploadfile_size: file1.size, uploadfile_content_type: file1.content_type
    )
  end
  let!(:file1_history2) do
    Gws::Share::History.create!(
      cur_user: user, site_id: site.id, name: file1.name, model: "gws/share/file", item_id: file1.id,
      uploadfile_name: file1.name, uploadfile_filename: file1.filename, uploadfile_srcname: "history-1",
      uploadfile_size: file1.size, uploadfile_content_type: file1.content_type
    )
  end
  let!(:file2) do
    file = tmp_ss_file(contents: unique_id, user: user)
    file.set(model: "share/file")
    Gws::Share::File.find(file.id)
  end
  let!(:file2_history1) do
    Gws::Share::History.create!(
      cur_user: user, site_id: site.id, name: file2.name, model: "gws/share/file", item_id: file2.id,
      uploadfile_name: file2.name, uploadfile_filename: file2.filename, uploadfile_srcname: "history-1",
      uploadfile_size: file2.size, uploadfile_content_type: file2.content_type
    )
  end
  let!(:file2_history2) do
    Gws::Share::History.create!(
      cur_user: user, site_id: site.id, name: file2.name, model: "gws/share/file", item_id: file2.id,
      uploadfile_name: file2.name, uploadfile_filename: file2.filename, uploadfile_srcname: "history0",
      uploadfile_size: file2.size, uploadfile_content_type: file2.content_type
    )
  end

  before do
    described_class.new.change
  end

  it do
    # put your specs here
    file1_history1.reload
    expect(file1_history1.uploadfile_srcname).to eq "history0"

    file1_history2.reload
    expect(file1_history2.uploadfile_srcname).to eq "history0"

    file2_history1.reload
    expect(file2_history1.uploadfile_srcname).to eq "history-1"

    file2_history2.reload
    expect(file2_history2.uploadfile_srcname).to eq "history0"
  end
end
