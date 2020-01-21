require 'spec_helper'

describe Gws::Group, type: :model, dbscope: :example, tmpdir: true do
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
end
