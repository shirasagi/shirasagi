require 'spec_helper'

describe "sns_user_profies", dbscope: :example, type: :feature do
  let(:user) { ss_user }
  let(:group) { ss_group }
  let(:show_path) { sns_user_profile_path user.id }
  let(:cur_user_show_path) { sns_cur_user_profile_path }

  before do
    user.group_ids = [group.id]
    user.save!
  end

  it "without login" do
    visit show_path
    expect(current_path).to eq sns_login_path
  end

  context "with auth" do
    before { login_ss_user }

    it "show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).to eq show_path
    end

    it "cur_user show" do
      visit cur_user_show_path
      expect(status_code).to eq 200
      expect(current_path).to eq cur_user_show_path
    end
  end

  context "with auth and recieve json" do
    before { login_ss_user }

    it "show" do
      visit "#{show_path}.json"
      expect(status_code).to eq 200
      expect(current_path).to eq "#{show_path}.json"
      source = JSON.parse(page.source)
      expect(source.delete('_id')).to eq user.id
      expect(source.delete('name')).to eq user.name
      expect(source.delete('uid')).to eq user.uid
      expect(source.delete('email')).to eq user.email
      expect(source.delete('type')).to eq user.type
      expect(source.delete('groups')).to include(include('_id' => user.groups.first.id, 'name' => user.groups.first.name))
      expect(source.delete('created')).not_to be_nil
      expect(source.delete('updated')).not_to be_nil
    end

    it "cur_user show" do
      visit "#{cur_user_show_path}.json"
      expect(status_code).to eq 200
      expect(current_path).to eq "#{cur_user_show_path}.json"
      source = JSON.parse(page.source)
      expect(source.delete('_id')).to eq user.id
      expect(source.delete('name')).to eq user.name
      expect(source.delete('uid')).to eq user.uid
      expect(source.delete('email')).to eq user.email
      expect(source.delete('type')).to eq user.type
      expect(source.delete('groups')).to include(include('_id' => user.groups.first.id, 'name' => user.groups.first.name))
      expect(source.delete('created')).not_to be_nil
      expect(source.delete('updated')).not_to be_nil
    end
  end
end
