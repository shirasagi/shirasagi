require 'spec_helper'

describe Cms::Apis::LargeFileUploadController, type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:group) { cms_group }
  let!(:user) { cms_user }
  let!(:max_filesize) { create :ss_max_file_size, in_size_mb: 1 }

  before do
    # get and save  auth token
    get sns_auth_token_path(format: :json)
    expect(response.status).to eq 200
    @auth_token = response.parsed_body["auth_token"]

    # login
    params = {
      'authenticity_token' => @auth_token,
      'item[email]' => user.email,
      'item[password]' => ss_pass
    }
    post sns_login_path(format: :json), params: params
    expect(response.status).to eq 204
  end

  context "upload in once" do
    let(:filename) { "shirasagi_#{unique_id}.pdf" }

    it do
      expect(Cms::File.all.site(site).count).to eq 0

      initialize_params = {
        filenames: [ filename ]
      }
      post cms_apis_large_file_upload_initialize_path(site: site, format: :json), params: initialize_params
      expect(response.status).to eq 200
      file_id = response.parsed_body.dig("files", filename)
      expect(file_id).to be_numeric

      blob = fixture_file_upload("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf", "application/octet-stream", true)
      upload_params = {
        filename: filename, blob: blob
      }
      post cms_apis_large_file_upload_upload_path(site: site, format: :json), params: upload_params
      expect(response.status).to eq 200

      finalize_params = {
        files: { filename => file_id }.to_json
      }
      put cms_apis_large_file_upload_finalize_path(site: site, format: :json), params: finalize_params
      expect(response.status).to eq 200

      expect(Cms::File.all.site(site).count).to eq 1
      file = Cms::File.all.site(site).first
      expect(file.site_id).to eq site.id
      expect(file.name).to eq filename
      expect(file.filename).to eq filename
      expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf")
      expect(file.content_type).to eq "application/pdf"
      expect(file.group_ids).to eq user.group_ids
    end
  end

  context "upload in parts" do
    let(:filename) { "shirasagi_#{unique_id}.pdf" }

    it do
      expect(Cms::File.all.site(site).count).to eq 0

      initialize_params = {
        filenames: [ filename ]
      }
      post cms_apis_large_file_upload_initialize_path(site: site, format: :json), params: initialize_params
      expect(response.status).to eq 200
      file_id = response.parsed_body.dig("files", filename)
      expect(file_id).to be_numeric

      data = File.binread("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf")
      index = 0
      data.each_char.each_slice(1_024) do |part|
        part = part.join

        blob = Rack::Test::UploadedFile.new(
          StringIO.new(part), "application/octet-stream", true, original_filename: "part-#{index}")
        upload_params = {
          filename: filename, blob: blob
        }
        post cms_apis_large_file_upload_upload_path(site: site, format: :json), params: upload_params
        expect(response.status).to eq 200

        index += 1
      end

      finalize_params = {
        files: { filename => file_id }.to_json
      }
      put cms_apis_large_file_upload_finalize_path(site: site, format: :json), params: finalize_params
      expect(response.status).to eq 200

      expect(Cms::File.all.site(site).count).to eq 1
      file = Cms::File.all.site(site).first
      expect(file.site_id).to eq site.id
      expect(file.name).to eq filename
      expect(file.filename).to eq filename
      expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf")
      expect(file.content_type).to eq "application/pdf"
      expect(file.group_ids).to eq user.group_ids
    end
  end

  context "path traversal vulnerability" do
    let(:filename) { "shirasagi_#{unique_id}.pdf" }

    it do
      expect(Cms::File.all.site(site).count).to eq 0

      FileUtils.touch("#{Rails.root}/tmp/#{filename}")
      expect(File.exist?("#{Rails.root}/tmp/#{filename}")).to be_truthy

      initialize_params = {
        filenames: [ filename ]
      }
      post cms_apis_large_file_upload_initialize_path(site: site, format: :json), params: initialize_params
      expect(response.status).to eq 200
      file_id = response.parsed_body.dig("files", filename)
      expect(file_id).to be_numeric

      blob = fixture_file_upload("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf", "application/octet-stream", true)
      upload_params = {
        filename: filename, blob: blob
      }
      post cms_apis_large_file_upload_upload_path(site: site, format: :json), params: upload_params
      expect(response.status).to eq 200

      finalize_params = {
        # "#{Rails.root}/tmp/#{filename}" を差すように ".." の数を調整する
        files: { "../../../../#{filename}" => file_id }.to_json
      }
      put cms_apis_large_file_upload_finalize_path(site: site, format: :json), params: finalize_params
      expect(response.status).to eq 200

      expect(File.exist?("#{Rails.root}/tmp/#{filename}")).to be_truthy
      FileUtils.rm_f("#{Rails.root}/tmp/#{filename}")
    end
  end
end
