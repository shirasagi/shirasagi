require 'spec_helper'

describe Webmail::GroupExport::Importer, type: :model, dbscope: :example do
  let!(:user) { webmail_user }
  let!(:in_file1) { Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/webmail/group_importer/accounts_1-1.csv") }
  let!(:in_file2) { Fs::UploadedFile.create_from_file("#{Rails.root}/spec/fixtures/webmail/group_importer/accounts_1-2.csv") }

  it do
    # first import
    importer = described_class.new
    importer.cur_user = user
    importer.in_file = in_file1
    importer.import_csv

    expect(Webmail::Group.count).to eq 3

    group = Webmail::Group.find(1)
    expect(group.name).to eq "シラサギ市"
    expect(group.imap_settings.count).to eq 1
    expect(group.imap_default_index).to eq 0

    imap_setting = group.imap_settings[0]
    expect(imap_setting.name).to eq "account1"
    expect(imap_setting.from).to eq "name1"
    expect(imap_setting.imap_account).to eq "g1@example.jp"
    expect(imap_setting.decrypt_imap_password).to eq "pass"

    group = Webmail::Group.find(2)
    expect(group.name).to eq "シラサギ市/企画政策部"
    expect(group.imap_settings.count).to eq 1
    expect(group.imap_default_index).to eq 0

    imap_setting = group.imap_settings[0]
    expect(imap_setting.name).to eq "account2"
    expect(imap_setting.from).to eq "name2"
    expect(imap_setting.imap_account).to eq "g2@example.jp"
    expect(imap_setting.decrypt_imap_password).to eq "pass"

    group = Webmail::Group.find(3)
    expect(group.name).to eq "シラサギ市/企画政策部/政策課"
    expect(group.imap_settings.count).to eq 2
    expect(group.imap_default_index).to eq 1

    imap_setting = group.imap_settings[0]
    expect(imap_setting.name).to eq "account3-1"
    expect(imap_setting.from).to eq "name3-1"
    expect(imap_setting.imap_account).to eq "g3-1@example.jp"
    expect(imap_setting.decrypt_imap_password).to eq "pass"

    imap_setting = group.imap_settings[1]
    expect(imap_setting.name).to eq "account3-2"
    expect(imap_setting.from).to eq "name3-2"
    expect(imap_setting.imap_account).to eq "g3-2@example.jp"
    expect(imap_setting.decrypt_imap_password).to eq "pass"

    # second import
    importer = described_class.new
    importer.cur_user = user
    importer.in_file = in_file2
    importer.import_csv

    expect(Webmail::Group.count).to eq 3

    group = Webmail::Group.find(1)
    expect(group.name).to eq "シラサギ市"
    expect(group.imap_settings.count).to eq 1
    expect(group.imap_default_index).to eq 0

    imap_setting = group.imap_settings[0]
    expect(imap_setting.name).to eq "account1"
    expect(imap_setting.from).to eq "name1"
    expect(imap_setting.imap_account).to eq "g1@example.jp"
    expect(imap_setting.decrypt_imap_password).to eq "pass"

    group = Webmail::Group.find(2)
    expect(group.name).to eq "シラサギ市/企画政策部"
    expect(group.imap_settings.count).to eq 1
    expect(group.imap_default_index).to eq 0

    imap_setting = group.imap_settings[0]
    expect(imap_setting.name).to eq "account2"
    expect(imap_setting.from).to eq "name2"
    expect(imap_setting.imap_account).to eq "g2@example.jp"
    expect(imap_setting.decrypt_imap_password).to eq "pass"

    group = Webmail::Group.find(3)
    expect(group.name).to eq "シラサギ市/企画政策部/政策課"
    expect(group.imap_settings.count).to eq 3
    expect(group.imap_default_index).to eq 2

    imap_setting = group.imap_settings[0]
    expect(imap_setting.name).to eq "account3-1"
    expect(imap_setting.from).to eq "name3-1"
    expect(imap_setting.imap_account).to eq "g3-1@example.jp"
    expect(imap_setting.decrypt_imap_password).to eq "pass"

    imap_setting = group.imap_settings[1]
    expect(imap_setting.name).to eq "account3-2"
    expect(imap_setting.from).to eq "name3-2"
    expect(imap_setting.imap_account).to eq "g3-2@example.jp"
    expect(imap_setting.decrypt_imap_password).to eq "pass"

    imap_setting = group.imap_settings[2]
    expect(imap_setting.name).to eq "account3-3"
    expect(imap_setting.from).to eq "name3-3"
    expect(imap_setting.imap_account).to eq "g3-3@example.jp"
    expect(imap_setting.decrypt_imap_password).to eq "pass"
  end
end
