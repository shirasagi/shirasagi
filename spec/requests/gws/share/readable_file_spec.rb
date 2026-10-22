require 'spec_helper'

describe "gws/share/files", type: :request, dbscope: :example do
  let!(:admin) { gws_user }
  let!(:user) { create :gws_user, group_ids: admin.group_ids, gws_role_ids: [ role.id ] }
  let!(:role) do
    permissions = %w(use_gws_share read_private_gws_share_files read_private_gws_share_folders)
    create :gws_role, cur_site: site, permissions: permissions
  end

  let!(:site) { gws_site }
  let!(:folder) { create :gws_share_folder, cur_site: site, readable_setting_range: "public", user_ids: [ admin.id ] }
  let!(:category) { create :gws_share_category, cur_site: site, readable_setting_range: "public" }
  let!(:item) do
    path = "#{Rails.root}/spec/fixtures/ss/logo.png"
    Fs::UploadedFile.create_from_file path, filename: "logo-#{unique_id}.png", content_type: 'image/png' do |file|
      create(
        :gws_share_file, cur_site: site, folder: folder, category_ids: [ category.id ], in_file: file,
        readable_setting_range: readable_setting_range, readable_group_ids: [], readable_member_ids: readable_member_ids,
        group_ids: [], user_ids: [ admin.id ]
      )
    end
  end

  before do
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
  end

  # 閲覧設定は全公開だが、ファイルの管理者（グループ・ユーザー）には含まれないユーザー
  context "when a file is public but a user doesn't own it" do
    let(:readable_setting_range) { "public" }
    let(:readable_member_ids) { [] }

    it do
      expect(item.owned?(user)).to be_falsey
      expect(item.readable?(user, site: site)).to be_truthy

      get gws_share_files_path(site: site, category: "-")
      expect(response.status).to eq 200
      expect(response.body).to include(item.name)

      get gws_share_file_path(site: site, category: "-", id: item)
      expect(response.status).to eq 200

      get download_gws_share_file_path(site: site, category: "-", id: item)
      expect(response.status).to eq 200
      expect(response.body).to eq ::File.binread(item.path)

      get view_gws_share_file_path(site: site, category: "-", id: item)
      expect(response.status).to eq 200

      params = { ids: [ item.id ] }
      post download_all_gws_share_files_path(site: site, category: "-"), params: params
      expect(response.status).to eq 200
      expect(response.content_type).to eq "application/zip"

      entries = []
      Zip::InputStream.open(StringIO.new(response.body)) do |zip_stream|
        entry = zip_stream.get_next_entry
        while entry
          entries.append(NKF.nkf("-w", entry.name))
          entry = zip_stream.get_next_entry
        end
      end
      expect(entries).to eq [ item.name ]
    end
  end

  # 閲覧設定で対象外のファイルは、これまでどおり取得できない（IDOR 対策の確認）
  context "when a file isn't readable for a user" do
    let(:readable_setting_range) { "select" }
    let(:readable_member_ids) { [ admin.id ] }

    it do
      expect(item.readable?(user, site: site)).to be_falsey

      get gws_share_file_path(site: site, category: "-", id: item)
      expect(response.status).to eq 404

      get download_gws_share_file_path(site: site, category: "-", id: item)
      expect(response.status).to eq 404
    end
  end
end
