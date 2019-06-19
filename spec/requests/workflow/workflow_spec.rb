require 'spec_helper'

describe Workflow::PagesController, type: :request, dbscope: :example do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }
  let!(:user) { cms_user }
  let!(:user1) { cms_user }
  let!(:user2) { create(:workflow_user, group: cms_group, role: cms_role) }
  let!(:html) { "<div>HTML</div>\r\n" }
  let!(:item) { create(:article_page, cur_site: site, cur_user: user, layout_id: layout.id, html: html, state: "closed") }
  let!(:node) { create(:article_node_page, cur_site: site, cur_user: user, layout_id: layout.id) }
  let!(:show_path) { article_page_path site.id, node, item }
  let!(:login_path) { sns_login_path(format: :json) }
  let!(:correct_login_params) do
    {
      item: {
        email: user.email,
        password: SS::Crypt.encrypt("pass", type: "AES-256-CBC"),
        encryption_type: "AES-256-CBC"
      }
    }
  end

  before do
    Workflow::PagesController.allow_forgery_protection = false
    post login_path, params: correct_login_params
    SS.config.replace_value_at(:env, :json_datetime_format, "%Y/%m/%d %H:%M:%S")
  end

  after do
    Workflow::PagesController.allow_forgery_protection = true
  end

  context "When POST request without email" do
    before do
      workflow_approvers = Workflow::Extensions::WorkflowApprovers.new
      workflow_approvers.push("1,#{user2._id},,pending,")
      workflow_required_counts = Workflow::Extensions::Route::RequiredCounts.new([false])

      params = {
        workflow_comment: "WorkflowComment#{unique_id}",
        workflow_approvers: workflow_approvers,
        workflow_required_counts: workflow_required_counts,
        url: item.url + show_path,
        forced_update_option: "false"
      }
      post request_update_workflow_page_path( site: site.id, cid: node.id, id: item.id), params: params
      @json = JSON.parse(response.body)
      @item = assigns[:item]
    end

    it { expect(response.status).to eq 200 }
    it { expect(@json["workflow_state"]).to be_nil }
    it { expect(@json["workflow_alert"]).not_to be_nil }
    it { expect(@item.state).to eq "closed" }
  end

  context "When POST request forced without email" do
    before do
      workflow_approvers = Workflow::Extensions::WorkflowApprovers.new
      workflow_approvers.push("1,#{user2._id},,pending,")
      workflow_required_counts = Workflow::Extensions::Route::RequiredCounts.new([false])

      params = {
        workflow_comment: "WorkflowComment#{unique_id}",
        workflow_approvers: workflow_approvers,
        workflow_required_counts: workflow_required_counts,
        url: item.url + show_path,
        forced_update_option: "true"
      }
      post request_update_workflow_page_path( site: site.id, cid: node.id, id: item.id), params: params
      @json = JSON.parse(response.body)
      @item = assigns[:item]
    end

    it { expect(@json["workflow_state"]).to eq "request" }
    it { expect(@json["workflow_alert"]).to be_nil }
    it { expect(@item.state).to eq "closed" }
    it { expect(@item.workflow_user_id).to eq user._id }
    it { expect(@item.workflow_state).to eq "request" }
  end

  context "When POST approve after request" do
    before do
      workflow_approvers = Workflow::Extensions::WorkflowApprovers.new
      workflow_approvers.push("1,#{user1._id},,pending,")
      workflow_required_counts = Workflow::Extensions::Route::RequiredCounts.new([false])

      params = {
        workflow_comment: "WorkflowComment#{unique_id}",
        workflow_approvers: workflow_approvers,
        workflow_required_counts: workflow_required_counts,
        url: item.url + show_path,
        forced_update_option: "false"
      }
      post request_update_workflow_page_path( site: site.id, cid: node.id, id: item.id), params: params


      params = {
        remand_comment: "RemandComment#{unique_id}",
        url: item.url + show_path,
        forced_update_option: "false"
      }
      post approve_update_workflow_page_path( site: site.id, cid: node.id, id: item.id), params: params
      @json = JSON.parse(response.body)
      @item = assigns[:item]
    end

    it { expect(response.status).to eq 200 }
    it { expect(@json["workflow_state"]).to eq "approve" }
    it { expect(@json["workflow_alert"]).to be_nil }
    it { expect(@item.state).to eq "public" }
    it { expect(@item.workflow_user_id).to eq user._id }
    it { expect(@item.workflow_state).to eq "approve" }
    it { expect(@item.workflow_approvers[0][:state]).to eq "approve" }
  end

  context "When POST remand after request" do
    before do
      workflow_approvers = Workflow::Extensions::WorkflowApprovers.new
      workflow_approvers.push("1,#{user1._id},,pending,")
      workflow_required_counts = Workflow::Extensions::Route::RequiredCounts.new([false])

      params = {
        workflow_comment: "WorkflowComment#{unique_id}",
        workflow_approvers: workflow_approvers,
        workflow_required_counts: workflow_required_counts,
        url: item.url + show_path,
        forced_update_option: "false"
      }
      post request_update_workflow_page_path( site: site.id, cid: node.id, id: item.id), params: params

      params = {
        remand_comment: "RemandComment#{unique_id}",
        url: item.url + show_path,
        forced_update_option: "false"
      }
      post remand_update_workflow_page_path( site: site.id, cid: node.id, id: item.id), params: params
      @json = JSON.parse(response.body)
      @item = assigns[:item]
    end

    it { expect(response.status).to eq 200 }
    it { expect(@json["workflow_state"]).to eq "remand" }
    it { expect(@json["workflow_alert"]).to be_nil }
    it { expect(@item.state).to eq "closed" }
    it { expect(@item.workflow_user_id).to eq user._id }
    it { expect(@item.workflow_state).to eq "remand" }
    it { expect(@item.workflow_approvers[0][:state]).to eq "remand" }
  end

  context "When POST branch_create" do
    before do
      post branch_create_workflow_page_path( site: site.id, cid: node.id, id: item.id)
      @branch = assigns[:items][0]
    end

    it { expect(response.status).to eq 200 }
    it { expect(response.body).not_to be_nil }
    it { expect(@branch.master_id).to eq item._id }
  end
end
