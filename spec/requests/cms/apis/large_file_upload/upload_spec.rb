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
      expect(Cms::LargeFileUploadTask.all.count).to eq 0

      initialize_params = {
        authenticity_token: @auth_token,
        filenames: [ filename ]
      }
      post cms_apis_large_file_upload_initialize_path(site: site, format: :json), params: initialize_params
      expect(response.status).to eq 200
      files = response.parsed_body["files"]
      expect(files).to have(1).items
      expect(files).to include(filename)

      expect(Cms::LargeFileUploadTask.all.count).to eq 1
      task = Cms::LargeFileUploadTask.all.first
      expect(task.site_id).to eq site.id
      expect(task.user_id).to eq user.id
      expect(task.name).to eq "cms:large_file_task:#{user.id}"
      expect(task.acceptable_files).to have(1).items
      expect(task.acceptable_files).to include("_id" => be_a(BSON::ObjectId), "filename" => filename, "last_part_no" => 0)
      expect(task.excluded_files).to be_blank

      blob = fixture_file_upload("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf", "application/octet-stream", true)
      upload_params = {
        authenticity_token: @auth_token,
        filename: filename, blob: blob, part_no: 0
      }
      post cms_apis_large_file_upload_upload_path(site: site, format: :json), params: upload_params
      expect(response.status).to eq 200

      finalize_params = {
        authenticity_token: @auth_token
      }
      put cms_apis_large_file_upload_finalize_path(site: site, format: :json), params: finalize_params
      expect(response.status).to eq 200

      task.reload
      expect(task.acceptable_files).to have(1).items
      expect(task.acceptable_files).to include("_id" => be_a(BSON::ObjectId), "filename" => filename, "last_part_no" => 1)

      expect(Cms::File.all.site(site).count).to eq 1
      file = Cms::File.all.site(site).first
      expect(file.site_id).to eq site.id
      expect(file.user_id).to eq user.id
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
        authenticity_token: @auth_token,
        filenames: [ filename ]
      }
      post cms_apis_large_file_upload_initialize_path(site: site, format: :json), params: initialize_params
      expect(response.status).to eq 200
      files = response.parsed_body["files"]
      expect(files).to have(1).items
      expect(files).to include(filename)

      data = File.binread("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf")
      index = 0
      data.each_char.each_slice(1_024) do |part|
        part = part.join

        blob = Rack::Test::UploadedFile.new(
          StringIO.new(part), "application/octet-stream", true, original_filename: "part-#{index}")
        upload_params = {
          authenticity_token: @auth_token,
          filename: filename, blob: blob, part_no: index
        }
        post cms_apis_large_file_upload_upload_path(site: site, format: :json), params: upload_params
        expect(response.status).to eq 200

        index += 1
      end

      finalize_params = {
        authenticity_token: @auth_token
      }
      put cms_apis_large_file_upload_finalize_path(site: site, format: :json), params: finalize_params
      expect(response.status).to eq 200

      expect(Cms::LargeFileUploadTask.all.count).to eq 1
      task = Cms::LargeFileUploadTask.all.first
      expect(task.site_id).to eq site.id
      expect(task.user_id).to eq user.id
      expect(task.name).to eq "cms:large_file_task:#{user.id}"
      expect(task.acceptable_files).to have(1).items
      expect(task.acceptable_files).to include("_id" => be_a(BSON::ObjectId), "filename" => filename, "last_part_no" => index)
      expect(task.excluded_files).to be_blank

      expect(Cms::File.all.site(site).count).to eq 1
      file = Cms::File.all.site(site).first
      expect(file.site_id).to eq site.id
      expect(file.user_id).to eq user.id
      expect(file.name).to eq filename
      expect(file.filename).to eq filename
      expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf")
      expect(file.content_type).to eq "application/pdf"
      expect(file.group_ids).to eq user.group_ids
    end
  end

  context "filename with dirname" do
    let(:filename) { "dir-#{unique_id}/shirasagi_#{unique_id}.pdf" }

    it do
      expect(Cms::File.all.site(site).count).to eq 0
      expect(Cms::LargeFileUploadTask.all.count).to eq 0

      initialize_params = {
        authenticity_token: @auth_token,
        filenames: [ filename ]
      }
      post cms_apis_large_file_upload_initialize_path(site: site, format: :json), params: initialize_params
      expect(response.status).to eq 200
      files = response.parsed_body["files"]
      expect(files).to have(1).items
      expect(files).to include(filename)

      expect(Cms::LargeFileUploadTask.all.count).to eq 1
      task = Cms::LargeFileUploadTask.all.first
      expect(task.site_id).to eq site.id
      expect(task.user_id).to eq user.id
      expect(task.name).to eq "cms:large_file_task:#{user.id}"
      expect(task.acceptable_files).to have(1).items
      expect(task.acceptable_files).to include("_id" => be_a(BSON::ObjectId), "filename" => filename, "last_part_no" => 0)
      expect(task.excluded_files).to be_blank

      blob = fixture_file_upload("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf", "application/octet-stream", true)
      upload_params = {
        authenticity_token: @auth_token,
        filename: filename, blob: blob, part_no: 0
      }
      post cms_apis_large_file_upload_upload_path(site: site, format: :json), params: upload_params
      expect(response.status).to eq 200

      finalize_params = {
        authenticity_token: @auth_token
      }
      put cms_apis_large_file_upload_finalize_path(site: site, format: :json), params: finalize_params
      expect(response.status).to eq 200

      task.reload
      expect(task.acceptable_files).to have(1).items
      expect(task.acceptable_files).to include("_id" => be_a(BSON::ObjectId), "filename" => filename, "last_part_no" => 1)

      expect(Cms::File.all.site(site).count).to eq 1
      file = Cms::File.all.site(site).first
      expect(file.site_id).to eq site.id
      expect(file.user_id).to eq user.id
      expect(file.name).to eq File.basename(filename)
      expect(file.filename).to eq File.basename(filename)
      expect(file.size).to eq File.size("#{Rails.root}/spec/fixtures/ss/shirasagi.pdf")
      expect(file.content_type).to eq "application/pdf"
      expect(file.group_ids).to eq user.group_ids
    end
  end
end
