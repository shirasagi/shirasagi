require 'spec_helper'

describe "gws/workflow/files", type: :request, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user1) { gws_user }
  let!(:user2) { create :gws_user }

  let(:form) { create(:gws_workflow_form, state: "public", agent_state: "enabled") }
  let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }
  let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form) }

  let(:column1_value) { unique_id }
  let(:file1) { tmp_ss_file(contents: '0123456789', user: user1) }
  let(:file2) { tmp_ss_file(contents: '0123456789', user: user1) }

  # 標準フォーム
  let!(:item1) do
    create(
      :gws_workflow_file, cur_site: site, cur_user: user1, file_ids: [ file1.id ], state: "public",
      workflow_state: 'request', workflow_user_id: user1.id,
      workflow_approvers: [{ level: 1, user_id: user2.id, state: "request" }],
      workflow_required_counts: [ false ]
    )
  end

  # 申請書を利用したフォーム
  let!(:item2) do
    Gws::Workflow::File.create!(
      cur_site: site, cur_user: user1, name: "name-#{unique_id}", cur_form: form,
      column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ file2.id ]) ],
      state: "public", workflow_state: 'request', workflow_user_id: user1.id,
      workflow_approvers: [{ level: 1, user_id: user2.id, state: "request" }],
      workflow_required_counts: [ false ]
    )
  end

  before do
    # get and save  auth token
    get sns_auth_token_path(format: :json)
    @auth_token = JSON.parse(response.body)["auth_token"]

    # login
    params = {
      'authenticity_token' => @auth_token,
      'item[email]' => user1.email,
      'item[password]' => "pass"
    }
    post sns_login_path(format: :json), params: params

    @headers = {}
  end

  context "#index" do
    it do
      get gws_workflow_files_path(site: site, state: "all", format: "json"), headers: @headers
      expect(response.status).to eq 200

      JSON.parse(response.body).tap do |json|
        expect(json).to be_a(Array)
        expect(json.length).to eq 2

        json[0].tap do |item_json|
          expect(item_json["_id"]).to eq item2.id
          expect(item_json["workflow_state"]).to eq "request"
          expect(item_json["workflow_user_id"]).to eq user1.id
          expect(item_json["workflow_user"]).to include("name" => user1.name, "uid" => user1.uid, "email" => user1.email)
          expect(item_json["workflow_approvers"].length).to eq 1
          item_json["workflow_approvers"].first.tap do |approver_json|
            expect(approver_json).to include("level" => 1, "user_id" => user2.id, "state" => "request")
            expect(approver_json["user"]).to include("name" => user2.name, "uid" => user2.uid, "email" => user2.email)
          end
          expect(item_json["column_values"].length).to eq 2
          item_json["column_values"][0].tap do |column_value_json|
            item2.column_values[0].tap do |column_value|
              expect(column_value_json).to \
                include("name" => column_value.name, "_type" => column_value.class.name, "value" => column_value.value)
            end
          end
          item_json["column_values"][1].tap do |column_value_json|
            item2.column_values[1].tap do |column_value|
              expect(column_value_json).to \
                include("name" => column_value.name, "_type" => column_value.class.name)
              expect(column_value_json["files"].length).to eq 1
              expect(column_value_json["files"][file2.id.to_s]).to \
                include("name" => file2.name, "filename" => file2.filename, "content_type" => file2.content_type)
              expect(column_value_json["files"][file2.id.to_s]["url"]).to be_present
            end
          end
        end
        json[1].tap do |item_json|
          expect(item_json["_id"]).to eq item1.id
          expect(item_json["name"]).to eq item1.name
          expect(item_json["state"]).to eq item1.state
          expect(item_json["workflow_state"]).to eq "request"
          expect(item_json["workflow_user_id"]).to eq user1.id
          expect(item_json["workflow_user"]).to include("name" => user1.name, "uid" => user1.uid, "email" => user1.email)
          expect(item_json["workflow_approvers"].length).to eq 1
          item_json["workflow_approvers"].first.tap do |approver_json|
            expect(approver_json).to include("level" => 1, "user_id" => user2.id, "state" => "request")
            expect(approver_json["user"]).to include("name" => user2.name, "uid" => user2.uid, "email" => user2.email)
          end
          expect(item_json["files"].keys).to include(file1.id.to_s)
          expect(item_json["files"][file1.id.to_s]["name"]).to eq file1.name
          expect(item_json["files"][file1.id.to_s]["filename"]).to eq file1.filename
          expect(item_json["files"][file1.id.to_s]["content_type"]).to eq file1.content_type
          expect(item_json["files"][file1.id.to_s]["url"]).to be_present
        end
      end

      get gws_workflow_files_path(site: site, state: "all", s: { keyword: item2.name }, format: "json"), headers: @headers
      expect(response.status).to eq 200
      JSON.parse(response.body).tap do |json|
        expect(json).to be_a(Array)
        expect(json.length).to eq 1
      end
    end
  end
end
