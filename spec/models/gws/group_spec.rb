require 'spec_helper'

describe Gws::Group, type: :model, dbscope: :example do
  describe "#sender_address" do
    subject { gws_site }
    let(:sender_name) { unique_id }
    let(:sender_email) { "#{unique_id}@example.jp" }
    let(:sender_user) { gws_user }

    context "when all sender fields are blank" do
      before do
        subject.set(sender_name: nil, sender_email: nil, sender_user_id: nil)
      end

      its(:sender_address) { is_expected.to eq SS.config.mail.default_from }
    end

    context "when only sender_name is given" do
      before do
        subject.set(sender_name: sender_name, sender_email: nil, sender_user_id: nil)
      end

      its(:sender_address) { is_expected.to eq SS.config.mail.default_from }
    end

    context "when only sender_email is given" do
      before do
        subject.set(sender_name: nil, sender_email: sender_email, sender_user_id: nil)
      end

      its(:sender_address) { is_expected.to eq sender_email }
    end

    context "when sender_name and sender_email is given" do
      before do
        subject.set(sender_name: sender_name, sender_email: sender_email, sender_user_id: nil)
      end

      its(:sender_address) { is_expected.to eq "#{sender_name} <#{sender_email}>" }
    end

    context "when only sender_user is given" do
      before do
        sender_user.set(name: unique_id, email: "#{unique_id}@example.jp")
        subject.set(sender_name: nil, sender_email: nil, sender_user_id: sender_user.id)
      end

      its(:sender_address) { is_expected.to eq "#{sender_user.name} <#{sender_user.email}>" }
    end
  end

  describe "#logo_application_image" do
    subject { gws_site }
    let(:ss_file1) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg", user: cms_user) }
    let(:ss_file2) { tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg", user: cms_user) }

    it do
      prev_filesize = ss_file1.size
      expect(ss_file1.model).to eq "ss/temp_file"

      subject.logo_application_image_id = ss_file1.id
      subject.save!

      # logo_application_image_id に画像ファイルをセットすると、リサイズされて小さくなる。その影響でファイルサイズが減るはず
      ss_file1.reload
      expect(ss_file1.model).to eq "ss/logo_file"
      expect(ss_file1.size).to be < prev_filesize

      # 別の画像で上書きする
      subject.logo_application_image_id = ss_file2.id
      subject.save!

      # 最初にセットしたファイルは削除されるはず
      expect { ss_file1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context ".in_group / .in_groups / .organizations / .and_gws_use" do
    let!(:site) { create :gws_group, name: unique_id, gws_use: "enabled" }
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}", gws_use: "disabled" }
    let!(:group1_1) { create :gws_group, name: "#{group1.name}/#{unique_id}", gws_use: "disabled" }
    let!(:group1_2) { create :gws_group, name: "#{group1.name}/#{unique_id}", gws_use: "disabled" }
    let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}", gws_use: "disabled" }
    let!(:group2_1) { create :gws_group, name: "#{group2.name}/#{unique_id}", gws_use: "disabled" }
    let!(:group2_2) { create :gws_group, name: "#{group2.name}/#{unique_id}", gws_use: "disabled" }

    describe ".in_group" do
      it do
        expect(Gws::Group.in_group(site).count).to eq 7
        expect(Gws::Group.in_group(group1).count).to eq 3
        expect(Gws::Group.in_group(group1_1).count).to eq 1
        expect(Gws::Group.in_group(group1_2).count).to eq 1
        expect(Gws::Group.in_group(group2).count).to eq 3
        expect(Gws::Group.in_group(group2_1).count).to eq 1
        expect(Gws::Group.in_group(group2_2).count).to eq 1

        expect(Gws::Group.in_group(site).in_group(group1).pluck(:id)).to contain_exactly(group1.id, group1_1.id, group1_2.id)
        expect(Gws::Group.in_group(group1).in_group(site).pluck(:id)).to contain_exactly(group1.id, group1_1.id, group1_2.id)

        expect(Gws::Group.in_group(group1).in_group(group1).pluck(:id)).to contain_exactly(group1.id, group1_1.id, group1_2.id)
        expect(Gws::Group.in_group(group1).in_group(group2).pluck(:id)).to be_blank
        expect(Gws::Group.in_group(group2).in_group(group1).pluck(:id)).to be_blank
      end
    end

    describe ".in_groups" do
      it do
        expect(Gws::Group.in_groups([ site ]).count).to eq 7
        expect(Gws::Group.in_groups([ group1 ]).count).to eq 3
        expect(Gws::Group.in_groups([ group1_1 ]).count).to eq 1
        expect(Gws::Group.in_groups([ group1_2 ]).count).to eq 1
        expect(Gws::Group.in_groups([ group2 ]).count).to eq 3
        expect(Gws::Group.in_groups([ group2_1 ]).count).to eq 1
        expect(Gws::Group.in_groups([ group2_2 ]).count).to eq 1

        expect(Gws::Group.in_groups([ site, group1 ]).count).to eq 7
        expect(Gws::Group.in_groups([ site, group2 ]).count).to eq 7
        expect(Gws::Group.in_groups([ group1, group2 ]).count).to eq 6
        expect(Gws::Group.in_groups([ group2, group1 ]).count).to eq 6

        expect(Gws::Group.in_groups([ group1_2, group2_1 ]).count).to eq 2
        expect(Gws::Group.in_groups([ group2_2, group1_1 ]).count).to eq 2
      end
    end

    describe ".organizations" do
      it do
        expect(Gws::Group.organizations.count).to eq 1
        expect(Gws::Group.in_group(site).organizations.count).to eq 1
        expect(Gws::Group.organizations.in_group(site).count).to eq 1
        expect(Gws::Group.in_group(group1).organizations.count).to eq 0
        expect(Gws::Group.organizations.in_group(group1).count).to eq 0
        expect(Gws::Group.in_group(group2_1).organizations.count).to eq 0
        expect(Gws::Group.organizations.in_group(group2_1).count).to eq 0
      end
    end

    describe ".and_gws_use" do
      it do
        expect(Gws::Group.and_gws_use.count).to eq 1
        expect(Gws::Group.in_group(site).and_gws_use.count).to eq 1
        expect(Gws::Group.and_gws_use.in_group(site).count).to eq 1
        expect(Gws::Group.in_group(group1).and_gws_use.count).to eq 0
        expect(Gws::Group.and_gws_use.in_group(group1).count).to eq 0
      end
    end
  end
end
