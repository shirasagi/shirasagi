require 'spec_helper'

describe "gws/workflow/files", type: :request, dbscope: :example do
  let!(:admin) { gws_user }
  let!(:user) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [] }

  let!(:site1) { gws_site }
  let!(:folder1) { create :gws_share_folder, cur_site: site1, readable_setting_range: "public", user_ids: [ admin.id ] }
  let!(:category1) { create :gws_share_category, cur_site: site1, readable_setting_range: "public" }
  let!(:item1) do
    path = "#{Rails.root}/spec/fixtures/ss/logo.png"
    Fs::UploadedFile.create_from_file path, filename: "logo-#{unique_id}.png", content_type: 'image/png' do |file|
      create(
        :gws_share_file, cur_site: site1, folder: folder1, category_ids: [ category1.id ], in_file: file,
        readable_setting_range: "select", readable_group_ids: [], readable_member_ids: [ admin.id ],
        group_ids: [], user_ids: [ admin.id ]
      )
    end
  end

  let!(:site2) { create :gws_group }
  let!(:folder2) { create :gws_share_folder, cur_site: site2, readable_setting_range: "public", user_ids: [ admin.id ] }
  let!(:category2) { create :gws_share_category, cur_site: site2, readable_setting_range: "public" }
  let!(:item2) do
    path = "#{Rails.root}/spec/fixtures/ss/logo.png"
    Fs::UploadedFile.create_from_file path, filename: "logo-#{unique_id}.png", content_type: 'image/png' do |file|
      create(
        :gws_share_file, cur_site: site2, folder: folder2, category_ids: [ category2.id ], in_file: file,
        readable_setting_range: "select", readable_group_ids: [], readable_member_ids: [ admin.id ],
        group_ids: [], user_ids: [ admin.id ]
      )
    end
  end

  before do
    expect(item1.name).not_to eq item2.name

    admin.add_to_set(group_ids: site2.id )

    # get and save  auth token
    get sns_auth_token_path(format: :json)
    @auth_token = response.parsed_body["auth_token"]

    # login
    params = {
      'authenticity_token' => @auth_token,
      'item[email]' => user.email,
      'item[password]' => ss_pass
    }
    post sns_login_path(format: :json), params: params

    @headers = {}
  end

  context "when a user joined a site but has no permissions" do
    it do
      params = { ids: (0..100).to_a }
      post download_all_gws_share_files_path(site: site1, category: "-"), headers: @headers, params: params
      expect(response.status).to eq 400
    end
  end

  context "when a user joined a site and has permission 'read_private_gws_share_files' but isn't readable for a file" do
    let!(:role) do
      permissions = %w(use_gws_share read_private_gws_share_files)
      create :gws_role, cur_site: site1, permissions: permissions
    end

    before do
      user.add_to_set(gws_role_ids: role.id)
    end

    it do
      params = { ids: (0..100).to_a }
      post download_all_gws_share_files_path(site: site1, category: "-"), headers: @headers, params: params
      expect(response.status).to eq 400
    end
  end

  context "when a user can read all files" do
    let!(:role) do
      permissions = %w(use_gws_share read_private_gws_share_files read_other_gws_share_files)
      create :gws_role, cur_site: site1, permissions: permissions
    end

    before do
      user.add_to_set(gws_role_ids: role.id)
    end

    it do
      params = { ids: (0..100).to_a }
      post download_all_gws_share_files_path(site: site1, category: "-"), headers: @headers, params: params
      expect(response.status).to eq 200
      expect(response.content_type).to eq "application/zip"

      entries = []
      Zip::InputStream.open(StringIO.new(response.body)) do |zip_stream|
        entry = zip_stream.get_next_entry
        while entry
          name = NKF.nkf("-w", entry.name)
          entries.append(name)
          entry = zip_stream.get_next_entry
        end
      end

      expect(entries).to have(1).items
      expect(entries).to include(item1.name)
    end
  end

  context "when a user doesn't join a site" do
    it do
      params = { ids: (0..100).to_a }
      post download_all_gws_share_files_path(site: site2, category: "-"), headers: @headers, params: params
      expect(response.status).to eq 403
    end
  end
end
