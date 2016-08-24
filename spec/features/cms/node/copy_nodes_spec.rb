require 'spec_helper'

describe "cms_copy_nodes", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node }

  let(:index_path) { node_copy_path site.id, node.id}

  context 'without login/auth' do
    it 'without login' do
      visit index_path
      expect(current_path).to eq sns_login_path
    end

    it 'without auth' do
      login_ss_user
      visit index_path
      expect(status_code).to eq 403
    end
  end

  context 'run copy nodes' do
    let(:target_node_name) { unique_id }

    before do
      login_cms_user
    end

    it 'redirect index_path and notice text' do
      visit index_path

      fill_in 'item[target_node_name]', with: target_node_name
      click_on '実行'
      expect(current_path).to eq index_path
      expect(page).to have_css('#notice .wrap', text: '処理を開始します。ジョブ実行履歴で結果をご確認下さい')
      expect(Cms::CopyNodesTask.first.target_node_name).to eq target_node_name
      expect(enqueued_jobs.first[:job]).to eq Cms::Node::CopyNodesJob
    end

    it 'invalid without target_node_name' do
      visit index_path

      fill_in 'item[target_node_name]', with: ''
      click_on '実行'
      expect(page).to have_css('.errorExplanation', text: '複製先フォルダー名を入力してください。')
    end

    it 'invalid without existing parent node' do
      visit index_path

      fill_in 'item[target_node_name]', with: "parent/#{target_node_name}"
      click_on '実行'
      expect(page).to have_css('.errorExplanation', text: "製先フォルダー名に親フォルダー「parent」がありません。")
    end
  end
end
