require 'spec_helper'

describe "gws_monitor_management_admins", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user0) { gws_user }
  let!(:g0) { user0.gws_default_group }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}", order: 10) }
  let!(:g2) { create(:gws_group, name: "#{site.name}/g-#{unique_id}", order: 20) }
  let!(:user1) { create(:gws_user, group_ids: [ g1.id ], gws_role_ids: user0.gws_role_ids) }
  let!(:user2) { create(:gws_user, group_ids: [ g2.id ], gws_role_ids: user0.gws_role_ids) }

  let(:topic1) do
    file_path = "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
    file = tmp_ss_file(contents: file_path, basename: "shirasagi-user0-file1.pdf", site: site, user: user0)
    create(
      :gws_monitor_topic, user: user0, attend_group_ids: [ g1.id, g2.id ],
      state: 'public', article_state: 'open', spec_config: 'my_group',
      file_ids: [ file.id ]
    )
  end
  let!(:user1_file1) do
    file_path = "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
    tmp_ss_file(contents: file_path, basename: "shirasagi-user1-file1.pdf", site: site, user: user1)
  end
  let!(:user1_file2) do
    file_path = "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf"
    tmp_ss_file(contents: file_path, basename: "shirasagi-user1-file2.pdf", site: site, user: user1)
  end

  before do
    clear_downloads
  end

  after do
    clear_downloads
  end

  it do
    # create cached file at
    login_user user0
    visit gws_monitor_management_admin_path(site: site, id: topic1)
    click_on I18n.t("gws/monitor.links.file_download")

    wait_for_download

    exported = []
    Zip::File.open(downloads.first) do |zip_file|
      zip_file.each do |entry|
        exported << NKF.nkf("-w", entry.name)
      end
    end

    expect(exported).to have(1).items
    expect(exported).to include("own_#{g0.order}_#{g0.trailing_name}_shirasagi-user0-file1.pdf")
    "#{Gws::Monitor::Topic.download_root_path}/#{topic1.id}/_/#{topic1.id}".tap do |zip_path|
      expect(::File.size(zip_path)).to be > 0
    end
    clear_downloads

    #
    # 回答する
    #
    login_user user1
    visit gws_monitor_topic_path(site: site, id: topic1)
    page.accept_confirm(I18n.t("gws/monitor.confirm.public")) do
      click_on I18n.t("gws/monitor.links.public")
    end
    wait_for_notice I18n.t("ss.notice.saved")

    click_on I18n.t("gws/monitor.links.comment")
    within "form#item-form" do
      fill_in "item[text]", with: unique_id
      wait_cbox_open do
        click_on I18n.t("ss.buttons.upload")
      end
    end
    wait_for_cbox do
      wait_cbox_close do
        click_on "shirasagi-user1-file1.pdf"
      end
    end
    within "form#item-form" do
      expect(page).to have_css(".file-view", text: "shirasagi-user1-file1.pdf")
      page.accept_confirm(I18n.t("gws/monitor.confirm.comment_answer")) do
        click_on I18n.t("gws/monitor.links.comment")
      end
    end
    wait_for_notice I18n.t("ss.notice.saved")

    #
    # 回答で追加されたファイルがダウンロードできるか（キャッシュが更新されるか）確認
    #
    login_user user0
    visit gws_monitor_management_admin_path(site: site, id: topic1)
    click_on I18n.t("gws/monitor.links.file_download")

    wait_for_download

    exported = []
    Zip::File.open(downloads.first) do |zip_file|
      zip_file.each do |entry|
        exported << NKF.nkf("-w", entry.name)
      end
    end

    expect(exported).to have(2).items
    expect(exported).to include("own_#{g0.order}_#{g0.trailing_name}_shirasagi-user0-file1.pdf")
    expect(exported).to include("#{g1.order}_#{g1.trailing_name}_shirasagi-user1-file1.pdf")
    "#{Gws::Monitor::Topic.download_root_path}/#{topic1.id}/_/#{topic1.id}".tap do |zip_path|
      expect(::File.size(zip_path)).to be > 0
    end
    clear_downloads

    #
    # 回答を編集する
    #
    login_user user1
    visit gws_monitor_answer_path(site: site, id: topic1)
    click_on I18n.t("ss.links.edit")
    within "form#item-form" do
      wait_cbox_open do
        click_on I18n.t("ss.buttons.upload")
      end
    end
    wait_for_cbox do
      wait_cbox_close do
        click_on "shirasagi-user1-file2.pdf"
      end
    end
    within "form#item-form" do
      expect(page).to have_css(".file-view", text: "shirasagi-user1-file2.pdf")
      click_on I18n.t("ss.buttons.save")
    end
    wait_for_notice I18n.t("ss.notice.saved")

    #
    # 回答の編集で追加されたファイルがダウンロードできるか（キャッシュが更新されるか）確認
    #
    login_user user0
    visit gws_monitor_management_admin_path(site: site, id: topic1)
    click_on I18n.t("gws/monitor.links.file_download")

    wait_for_download

    exported = []
    Zip::File.open(downloads.first) do |zip_file|
      zip_file.each do |entry|
        exported << NKF.nkf("-w", entry.name)
      end
    end

    expect(exported).to have(3).items
    expect(exported).to include("own_#{g0.order}_#{g0.trailing_name}_shirasagi-user0-file1.pdf")
    expect(exported).to include("#{g1.order}_#{g1.trailing_name}_shirasagi-user1-file1.pdf")
    expect(exported).to include("#{g1.order}_#{g1.trailing_name}_shirasagi-user1-file2.pdf")
    "#{Gws::Monitor::Topic.download_root_path}/#{topic1.id}/_/#{topic1.id}".tap do |zip_path|
      expect(::File.size(zip_path)).to be > 0
    end
    clear_downloads
  end
end
