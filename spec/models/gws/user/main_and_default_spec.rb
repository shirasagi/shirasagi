require 'spec_helper'

describe Gws::User, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:default_group) { gws_user.groups.first }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10_001 }
  let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10_002 }
  let!(:group3) { create :gws_group, name: "#{site.name}/#{unique_id}", order: 10_003 }
  let!(:site2) { create :gws_group, order: 20_000 }
  let!(:group4) { create :gws_group, name: "#{site2.name}/#{unique_id}", order: 20_001 }

  before do
    Gws::User.find(gws_user.id).tap do |user|
      # メンバー変数が汚染されるとテストで思わぬ結果をうむ場合がある。
      # そこで、データベースからユーザーをロードし、必要処理を実行後、インスタンスを破棄する。
      user.cur_site ||= site
      user.group_ids = user.group_ids + [ group1.id, group2.id, group4.id ]
      user.save!
    end
    gws_user.reload
  end

  describe "#gws_main_group_ids" do
    it do
      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to be_blank
        expect(user.gws_default_group_ids).to be_blank
        expect(user.gws_main_group.try(:id)).to eq default_group.id
        expect(user.gws_default_group.try(:id)).to eq user.gws_main_group.try(:id)
      end

      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        user.in_gws_main_group_id = group1.id
        user.save!
      end

      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to include(site.id.to_s => group1.id)
        expect(user.gws_default_group_ids).to be_blank
        expect(user.gws_main_group.try(:id)).to eq group1.id
        expect(user.gws_default_group.try(:id)).to eq user.gws_main_group.try(:id)
      end

      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        user.in_gws_main_group_id = group2.id
        user.save!
      end

      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to include(site.id.to_s => group2.id)
        expect(user.gws_default_group_ids).to be_blank
        expect(user.gws_main_group.try(:id)).to eq group2.id
        expect(user.gws_default_group.try(:id)).to eq user.gws_main_group.try(:id)
      end

      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        user.in_gws_main_group_id = group3.id
        expect { user.save! }.to raise_error Mongoid::Errors::Validations
        expect(user.errors[:gws_main_group_ids]).to include(I18n.t("errors.messages.invalid"))
      end

      Gws::User.find(gws_user.id).tap do |user|
        # 他サイトのグループを主として設定してみる
        user.cur_site = site
        user.in_gws_main_group_id = group4.id
        expect { user.save! }.to raise_error Mongoid::Errors::Validations
        expect(user.errors[:gws_main_group_ids]).to include(I18n.t("errors.messages.invalid"))
      end
    end
  end

  describe "#gws_default_group_ids" do
    it do
      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to be_blank
        expect(user.gws_default_group_ids).to be_blank
        expect(user.gws_main_group.try(:id)).to eq default_group.id
        expect(user.gws_default_group.try(:id)).to eq user.gws_main_group.try(:id)
      end

      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.set_gws_default_group_id(group1.id.to_s)).to be_truthy
      end

      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to be_blank
        expect(user.gws_default_group_ids).to include(site.id.to_s => group1.id)
        expect(user.gws_main_group.try(:id)).to eq default_group.id
        expect(user.gws_default_group.try(:id)).to eq group1.id
      end

      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.set_gws_default_group_id(group2.id.to_s)).to be_truthy
      end

      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.gws_main_group_ids).to be_blank
        expect(user.gws_default_group_ids).to include(site.id.to_s => group2.id)
        expect(user.gws_main_group.try(:id)).to eq default_group.id
        expect(user.gws_default_group.try(:id)).to eq group2.id
      end

      Gws::User.find(gws_user.id).tap do |user|
        user.cur_site = site
        expect(user.set_gws_default_group_id(group3.id.to_s)).to be_falsey
      end

      Gws::User.find(gws_user.id).tap do |user|
        # 他サイトのグループを既定にしてみる
        user.cur_site = site
        expect(user.set_gws_default_group_id(group4.id.to_s)).to be_falsey
      end
    end
  end
end
