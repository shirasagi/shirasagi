require 'spec_helper'

# for shirasagi desktop
describe "login_ad", type: :request, dbscope: :example do
  context "ad_links are existed" do
    let(:ss_file1) do
      tmp_ss_file(
        basename: "logo-#{unique_id}.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
    end
    let(:ss_file2) do
      tmp_ss_file(
        basename: "keyvisual-#{unique_id}.jpg", contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg")
    end
    let(:url1) { unique_url }
    let(:url2) { unique_url }

    before do
      setting = Sys::Setting.new
      setting.ad_links.build(url: url1, file_id: ss_file1.id, state: "show")
      setting.ad_links.build(url: url2, file_id: ss_file2.id, state: "show")
      setting.save!
    end

    it do
      get sns_login_image_path(format: :json)
      expect(response.status).to eq 200

      source = response.parsed_body
      expect(source["file_ids"]).to have(2).items
      expect(source["file_ids"]).to include(ss_file1.id, ss_file2.id)
      expect(source["files"]).to have(2).items
      expect(source["files"]).to include(
        include(link_url: url1, name: ss_file1.name, full_url: end_with(ss_file1.url)),
        include(link_url: url2, name: ss_file2.name, full_url: end_with(ss_file2.url))
      )
    end
  end

  context "when ad_links are not existed" do
    before do
      setting = Sys::Setting.new
      setting.save!
    end

    it do
      get sns_login_image_path(format: :json)
      expect(response.status).to eq 200

      source = response.parsed_body
      expect(source["file_ids"]).to be_blank
      expect(source["files"]).to be_blank
    end
  end

  context "when there are no showable ad_links" do
    let(:ss_file1) do
      tmp_ss_file(
        basename: "logo-#{unique_id}.png", contents: "#{Rails.root}/spec/fixtures/ss/logo.png")
    end
    let(:ss_file2) do
      tmp_ss_file(
        basename: "keyvisual-#{unique_id}.jpg", contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg")
    end

    before do
      setting = Sys::Setting.new
      setting.ad_links.build(url: unique_url, file_id: ss_file1.id, state: nil)
      setting.ad_links.build(url: unique_url, file_id: ss_file2.id, state: "hide")
      setting.save!
    end

    it do
      get sns_login_image_path(format: :json)
      expect(response.status).to eq 200

      source = response.parsed_body
      expect(source["file_ids"]).to be_blank
      expect(source["files"]).to be_blank
    end
  end
end
