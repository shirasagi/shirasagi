require 'spec_helper'

describe Gws::CompressJob, dbscope: :example do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let!(:file1) { create(:gws_share_file) }
  let(:zip) do
    zip = Gws::Compressor.new(user, items: Gws::Share::File.site(site).all)
    zip.url = Rails.application.routes.url_helpers.sns_download_job_files_url(
      host: "#{unique_id}.example.jp", user: zip.user, filename: zip.filename
    )
    zip
  end
  let(:id_path) { "#{format("%02d", user.id.to_s.slice(0, 2))}/#{user.id}" }
  let(:physical_filepath) { "#{SS::DownloadJobFile.root}/#{id_path}/#{zip.filename}" }

  before do
    ActionMailer::Base.deliveries.clear

    Gws::CompressJob.bind(site_id: site.id, user_id: user.id).perform_now(zip.serialize)

    expect(Job::Log.count).to eq 1
    Job::Log.first.tap do |log|
      expect(log.logs).to include(/INFO -- : .* Started Job/)
      expect(log.logs).to include(/INFO -- : .* Completed Job/)
    end

    # no mails are sent
    expect(ActionMailer::Base.deliveries.length).to eq 0

    ActionMailer::Base.deliveries.clear
  end

  it do
    expect(SS::Notification.all).to have(1).items
    SS::Notification.all.first.tap do |notification|
      expect(notification.member_ids).to include(user.id)
      expect(notification.subject).to eq I18n.t("gws/share.mailers.compressed.subject")
      expect(notification.format).to eq 'text'
      expect(notification.text).to include("ダウンロードの準備が完了しました。")
    end

    entry_names = ::Zip::File.open(physical_filepath) do |entries|
      entries.map { |entry| entry.name }
    end
    expect(entry_names).to include(file1.filename)
  end
end
