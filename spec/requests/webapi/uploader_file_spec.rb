require 'spec_helper'
require 'fileutils'

describe "webapi", dbscope: :example, type: :request do
  before do
    SS.config.replace_value_at(:env, :protect_csrf, false)
  end

  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:node) { create(:article_node_page) }
  let!(:page) { create(:article_page, cur_node: node) }
  let!(:uploader_node) { create(:uploader_node_file, filename: "img", name: "img") }

  ## paths
  let!(:login_path) { sns_login_path(format: :json) }
  let!(:logout_path) { sns_logout_path(format: :json) }
  let!(:upload_file_path) do
    "/.s#{site.id}/uploader#{uploader_node.id}/files/#{uploader_node.filename}?do=new_files&format=json"
  end
  let!(:edit_uploaded_file_path) do
    "/.s#{site.id}/uploader#{uploader_node.id}/files/#{uploader_node.filename}/logo.png?do=edit&format=json"
  end
  let!(:destroy_uploaded_file_path) do
    "/.s#{site.id}/uploader#{uploader_node.id}/files/#{uploader_node.filename}/logo.png?format=json"
  end
  let!(:invalid_uploaded_file_path) do
    "/.s#{site.id}/uploader#{uploader_node.id}/files/#{uploader_node.filename}/nothing.png?do=edit&format=json"
  end
  let!(:index_uploaded_file_path) do
    "/.s#{site.id}/uploader#{uploader_node.id}/files/#{uploader_node.filename}?format=json"
  end

  ## request params
  let!(:correct_login_params) do
    {
      :item => {
        :email => user.email,
        :password => SS::Crypt.encrypt("pass", type: "AES-256-CBC"),
        :encryption_type => "AES-256-CBC"
      }
    }
  end

  context "with login" do
    before { post login_path, correct_login_params }

    context "upload file" do
      describe "POST /.s{site}/uploader{cid}/files/{filename}?do=new_files&format=json" do
        before(:each) { Fs.rm_rf "#{uploader_node.path}/logo.png" }
        it "201" do
          correct_upload_file_params = {
            :item => {
              :files => [
                Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/webapi/logo.png", nil, true)
              ]
            }
          }
          post upload_file_path, correct_upload_file_params
          expect(response.status).to eq 201
        end

        it "400" do
          params = {}
          post upload_file_path, params
          expect(response.status).to eq 400
        end

        it "422" do
          correct_upload_file_params = {
            :item => {
              :files => [
                Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/webapi/logo.png", nil, true)
              ]
            }
          }
          multibyte_filepath = ::File.join(site.path, "ロゴ.png")
          ::FileUtils.cp("#{::Rails.root}/spec/fixtures/webapi/logo.png", multibyte_filepath)
          invalid_upload_file_params = {
            :item => {
              :files => [
                Rack::Test::UploadedFile.new(multibyte_filepath, nil, true)
              ]
            }
          }
          post upload_file_path, correct_upload_file_params
          expect(response.status).to eq 201
          post upload_file_path, correct_upload_file_params
          expect(response.status).to eq 422
          post upload_file_path, invalid_upload_file_params
          expect(response.status).to eq 422
        end
      end
    end

    context "edit uploaded file" do
      before(:each) do
        Fs.rm_rf "#{uploader_node.path}/logo.png"
        Fs.rm_rf "#{uploader_node.path}/replace.png"
      end

      it "204" do
        correct_upload_file_params = {
          :item => {
            :files => [
              Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/webapi/logo.png", nil, true)
            ]
          }
        }
        post upload_file_path, correct_upload_file_params
        expect(response.status).to eq 201

        edit_uploaded_file_params = {
          :item => {
            :filename => "img/replace.png",
            :files => [
              Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/webapi/replace.png", nil, true)
            ]
          }
        }
        put edit_uploaded_file_path, edit_uploaded_file_params
        expect(response.status).to eq 204
      end

      it "400" do
        params = {}
        post upload_file_path, params
        expect(response.status).to eq 400
      end

      it "404" do
        edit_uploaded_file_params = {
          :item => {
            :filename => "replace.png",
            :files => [
              Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/webapi/replace.png", nil, true)
            ]
          }
        }
        put invalid_uploaded_file_path, edit_uploaded_file_params
        expect(response.status).to eq 404
      end
    end

    context "delete uploaded file" do
      before(:each) do
        Fs.rm_rf "#{uploader_node.path}/logo.png"
        Fs.rm_rf "#{uploader_node.path}/replace.png"
      end

      it "204" do
        correct_upload_file_params = {
          :item => {
            :files => [
              Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/webapi/logo.png", nil, true)
            ]
          }
        }
        post upload_file_path, correct_upload_file_params
        expect(response.status).to eq 201

        delete destroy_uploaded_file_path
        expect(response.status).to eq 204
      end
    end

    context "index uploaded file" do
      before(:each) do
        Fs.rm_rf "#{uploader_node.path}/logo.png"
        Fs.rm_rf "#{uploader_node.path}/replace.png"
      end

      it "204" do
        correct_upload_file_params = {
          :item => {
            :files => [
              Rack::Test::UploadedFile.new("#{::Rails.root}/spec/fixtures/webapi/logo.png", nil, true)
            ]
          }
        }
        post upload_file_path, correct_upload_file_params
        expect(response.status).to eq 201

        get index_uploaded_file_path
        expect(response.status).to eq 200
      end
    end
  end
end
