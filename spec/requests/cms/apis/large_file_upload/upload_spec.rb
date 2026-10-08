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
    let(:file_id) { SecureRandom.uuid }
    let(:filename) { "shirasagi_#{unique_id}.pdf" }
    let(:upload_file_path) { "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf" }
    let(:file_size) { File.size(upload_file_path) }

    it do
      expect(Cms::File.all.site(site).count).to eq 0
      expect(Cms::LargeFileUploadTask.all.count).to eq 0

      initialize_params = {
        authenticity_token: @auth_token,
        item: {
          files: [{ file_id: file_id, filename: filename, size: file_size } ]
        }
      }
      post cms_apis_large_file_upload_initialize_path(site: site, format: :json), params: initialize_params
      expect(response.status).to eq 200
      files = response.parsed_body["files"]
      expect(files).to have(1).items
      expect(files).to include("file_id" => file_id, "filename" => filename)

      expect(Cms::LargeFileUploadTask.all.count).to eq 1
      task = Cms::LargeFileUploadTask.all.first
      expect(task.site_id).to eq site.id
      expect(task.user_id).to eq user.id
      expect(task.name).to eq "cms:large_file_task:#{user.id}"
      expect(task.acceptable_files).to have(1).items
      expect(task.acceptable_files).to include(
        { "_id" => be_a(BSON::ObjectId), "file_id" => file_id, "filename" => filename, "last_part_no" => 0, "expected_size" => file_size }
      )

      blob = fixture_file_upload(upload_file_path, "application/octet-stream", true)
      upload_params = {
        authenticity_token: @auth_token,
        item: { file_id: file_id, blob: blob, part_no: 0 }
      }
      post cms_apis_large_file_upload_upload_path(site: site, format: :json), params: upload_params
      expect(response.status).to eq 200

      finalize_params = {
        authenticity_token: @auth_token
      }
      put cms_apis_large_file_upload_finalize_path(site: site, format: :json), params: finalize_params
      expect(response.status).to eq 200
      expect(response.parsed_body["files"]).to be_blank

      task.reload
      expect(task.acceptable_files).to be_blank

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
    let(:file_id) { SecureRandom.uuid }
    let(:filename) { "shirasagi_#{unique_id}.pdf" }
    let(:upload_file_path) { "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf" }

    it do
      expect(Cms::File.all.site(site).count).to eq 0

      initialize_params = {
        authenticity_token: @auth_token,
        item: {
          files: [{ file_id: file_id, filename: filename, size: File.size(upload_file_path) } ]
        }
      }
      post cms_apis_large_file_upload_initialize_path(site: site, format: :json), params: initialize_params
      expect(response.status).to eq 200
      files = response.parsed_body["files"]
      expect(files).to have(1).items
      expect(files).to include("file_id" => file_id, "filename" => filename)

      data = File.binread(upload_file_path)
      index = 0
      data.each_char.each_slice(1_024) do |part|
        part = part.join

        blob = Rack::Test::UploadedFile.new(
          StringIO.new(part), "application/octet-stream", true, original_filename: "part-#{index}")
        upload_params = {
          authenticity_token: @auth_token,
          item: { file_id: file_id, blob: blob, part_no: index }
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
      expect(response.parsed_body["files"]).to be_blank

      expect(Cms::LargeFileUploadTask.all.count).to eq 1
      task = Cms::LargeFileUploadTask.all.first
      expect(task.site_id).to eq site.id
      expect(task.user_id).to eq user.id
      expect(task.name).to eq "cms:large_file_task:#{user.id}"
      expect(task.acceptable_files).to be_blank

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
    let(:file_id) { SecureRandom.uuid }
    let(:filename) { "dir-#{unique_id}/shirasagi_#{unique_id}.pdf" }
    let(:upload_file_path) { "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf" }
    let(:file_size) { File.size(upload_file_path) }

    it do
      expect(Cms::File.all.site(site).count).to eq 0
      expect(Cms::LargeFileUploadTask.all.count).to eq 0

      initialize_params = {
        authenticity_token: @auth_token,
        item: {
          files: [{ file_id: file_id, filename: filename, size: file_size } ]
        }
      }
      post cms_apis_large_file_upload_initialize_path(site: site, format: :json), params: initialize_params
      expect(response.status).to eq 200
      files = response.parsed_body["files"]
      expect(files).to have(1).items
      expect(files).to include("file_id" => file_id, "filename" => filename)

      expect(Cms::LargeFileUploadTask.all.count).to eq 1
      task = Cms::LargeFileUploadTask.all.first
      expect(task.site_id).to eq site.id
      expect(task.user_id).to eq user.id
      expect(task.name).to eq "cms:large_file_task:#{user.id}"
      expect(task.acceptable_files).to have(1).items
      expect(task.acceptable_files).to include(
        { "_id" => be_a(BSON::ObjectId), "file_id" => file_id, "filename" => filename, "last_part_no" => 0, "expected_size" => file_size }
      )

      blob = fixture_file_upload(upload_file_path, "application/octet-stream", true)
      upload_params = {
        authenticity_token: @auth_token,
        item: { file_id: file_id, blob: blob, part_no: 0 }
      }
      post cms_apis_large_file_upload_upload_path(site: site, format: :json), params: upload_params
      expect(response.status).to eq 200

      finalize_params = {
        authenticity_token: @auth_token
      }
      put cms_apis_large_file_upload_finalize_path(site: site, format: :json), params: finalize_params
      expect(response.status).to eq 200
      expect(response.parsed_body["files"]).to be_blank

      task.reload
      expect(task.acceptable_files).to be_blank

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

  context "upload same filenames" do
    # dir1/a.pdf と dir2/a.pdf を含むディレクトリをアップロードすると、このような状況となる
    let(:file_id1) { SecureRandom.uuid }
    let(:file_id2) { SecureRandom.uuid }
    let(:filename) { "shirasagi_#{unique_id}.pdf" }
    let(:upload_file_path) { "#{Rails.root}/spec/fixtures/ss/shirasagi.pdf" }
    let(:file_size) { File.size(upload_file_path) }

    it do
      expect(Cms::File.all.site(site).count).to eq 0
      expect(Cms::LargeFileUploadTask.all.count).to eq 0

      initialize_params = {
        authenticity_token: @auth_token,
        item: {
          files: [
            { file_id: file_id1, filename: filename, size: file_size },
            { file_id: file_id2, filename: filename, size: file_size }
          ]
        }
      }
      post cms_apis_large_file_upload_initialize_path(site: site, format: :json), params: initialize_params
      expect(response.status).to eq 200
      files = response.parsed_body["files"]
      expect(files).to have(2).items

      expect(Cms::LargeFileUploadTask.all.count).to eq 1
      task = Cms::LargeFileUploadTask.all.first
      expect(task.site_id).to eq site.id
      expect(task.user_id).to eq user.id
      expect(task.name).to eq "cms:large_file_task:#{user.id}"
      expect(task.acceptable_files).to have(2).items
      expect(task.acceptable_files).to include(
        { "_id" => be_a(BSON::ObjectId), "file_id" => file_id1, "filename" => filename, "last_part_no" => 0,
          "expected_size" => file_size },
        { "_id" => be_a(BSON::ObjectId), "file_id" => file_id2, "filename" => filename, "last_part_no" => 0,
          "expected_size" => file_size }
      )

      blob1 = fixture_file_upload(upload_file_path, "application/octet-stream", true)
      upload_params1 = {
        authenticity_token: @auth_token,
        item: { file_id: file_id1, blob: blob1, part_no: 0 }
      }
      post cms_apis_large_file_upload_upload_path(site: site, format: :json), params: upload_params1
      expect(response.status).to eq 200

      blob2 = fixture_file_upload(upload_file_path, "application/octet-stream", true)
      upload_params2 = {
        authenticity_token: @auth_token,
        item: { file_id: file_id2, blob: blob2, part_no: 0 }
      }
      post cms_apis_large_file_upload_upload_path(site: site, format: :json), params: upload_params2
      expect(response.status).to eq 200

      finalize_params = {
        authenticity_token: @auth_token
      }
      put cms_apis_large_file_upload_finalize_path(site: site, format: :json), params: finalize_params
      expect(response.status).to eq 200
      expect(response.parsed_body["files"]).to be_blank

      task.reload
      expect(task.acceptable_files).to be_blank

      expect(Cms::File.all.site(site).count).to eq 2
      Cms::File.all.site(site).each do |file|
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
end
