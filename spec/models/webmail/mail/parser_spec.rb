require 'spec_helper'

describe Webmail::Mail::Parser, type: :model, dbscope: :example do
  context "text mail" do
    subject(:item) { webmail_load_mail('text.yml') }

    it do
      expect(item.seen?).to be_truthy
      expect(item.unseen?).to be_falsey
      expect(item.star?).to be_truthy
      expect(item.draft?).to be_truthy
      expect(item.from).to eq ['"サイト管理者" <admin@example.jp>']
      expect(item.from).to eq item.to
      expect(item.from).to eq item.cc
      expect(item.from).to eq item.bcc
      expect(item.from).to eq item.reply_to
      expect(item.in_reply_to).to eq 'in_reply_to@localhost'
      expect(item.references).to eq ['reference@localhost']
      expect(item.display_size).to eq '1KB'
      expect(item.display_subject).to eq '件名'
      expect(item.display_sender.name).to eq 'サイト管理者'
      expect(item.display_sender.email).to eq 'admin@example.jp'
      expect(item.display_to.length).to eq 1
      expect(item.display_to.first.name).to eq 'サイト管理者'
      expect(item.display_to.first.email).to eq 'admin@example.jp'
      expect(item.display_to).to eq item.display_cc
      expect(item.display_to).to eq item.display_bcc
      expect(item.format).to eq 'text'
      expect(item.html?).to be_falsey
      expect(item.text.present?).to be_truthy
      expect(item.html.present?).to be_falsey
      expect(item.attachments?).to be_falsey
      expect(item.attachments.size).to eq 0
      expect(item.rfc822).to eq 'RFC822'
    end
  end

  context "html mail" do
    subject(:item) { webmail_load_mail('html.yml') }

    it do
      expect(item.seen?).to be_falsey
      expect(item.unseen?).to be_truthy
      expect(item.star?).to be_falsey
      expect(item.draft?).to be_falsey
      expect(item.from).to eq ['admin@example.jp']
      expect(item.from).to eq item.to
      expect(item.from).to eq item.cc
      expect(item.from).to eq item.bcc
      expect(item.display_subject).to eq '件名'
      expect(item.display_sender.name).to eq 'admin@example.jp'
      expect(item.display_sender.email).to eq 'admin@example.jp'
      expect(item.display_to.length).to eq 1
      expect(item.display_to.first.name).to eq 'admin@example.jp'
      expect(item.display_to.first.email).to eq 'admin@example.jp'
      expect(item.display_to).to eq item.display_cc
      expect(item.display_to).to eq item.display_bcc
      expect(item.format).to eq 'html'
      expect(item.html?).to be_truthy
      expect(item.text.present?).to be_truthy
      expect(item.html.present?).to be_truthy
      expect(item.sanitize_html.present?).to be_truthy
      expect(item.sanitize_html.size).to be < item.html.size
    end
  end

  context "attachment mail" do
    subject(:item) { webmail_load_mail('attach.yml') }

    it do
      expect(item.format).to eq 'text'
      expect(item.html?).to be_falsey
      expect(item.text.present?).to be_truthy
      expect(item.html.present?).to be_falsey
      expect(item.attachments?).to be_truthy
      expect(item.attachments.size).to eq 1
    end
  end

  context "attachment part" do
    subject(:item) { webmail_load_mail('attach.yml').attachments[0] }

    it do
      expect(item.content_type).to eq 'image/png'
      expect(item.attachment?).to be_truthy
      expect(item.image?).to be_truthy
      expect(item.link_target).to eq '_blank'
      expect(item.filename).to eq '1px.png'
      expect(item.read.size).to be > 0
      expect(item.decoded.size).to be > 0
      expect(item.decoded.size).to be < item.read.size
    end
  end

  describe "#parse_address_field" do
    around do |example|
      Webmail.activate_cp50221 do
        example.run
      end
    end

    context "with only address" do
      let(:address) { "aaa@example.jp" }
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it { is_expected.to eq %w(aaa@example.jp) }
    end

    context "when address with display name is given" do
      let(:address) { "display name <aaa@example.jp>" }
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it { is_expected.to eq ["display name <aaa@example.jp>"] }
    end

    context "with multiple address sperated by comma" do
      let(:address) { "aaa@example.jp, <bbb> bbb@example.jp, ccc@example.jp" }
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it { is_expected.to eq ["aaa@example.jp, <bbb> bbb@example.jp, ccc@example.jp"] }
    end

    context "with UTF-8 + Base64 encoded address" do
      let(:address) { "=?UTF-8?B?5ZCN5a2XIOWQjeWJjQ==?= <aaa@example.jp>" }
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it { is_expected.to eq ["\"名字 名前\" <aaa@example.jp>"] }
    end

    context "with UTF-8 + Quoted-Printable encoded address" do
      let(:address) { "=?UTF-8?Q?=E5=90=8D=E5=AD=97 =E5=90=8D=E5=89=8D=?= <aaa@example.jp>" }
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it { is_expected.to eq ["\"名字 名前\" <aaa@example.jp>"] }
    end

    context "with Basic ISO-2022-JP + Base64 encoded address" do
      let(:address) { "=?ISO-2022-JP?B?GyRCTD47ehsoQiAbJEJMPkEwGyhC?= <aaa@example.jp>" }
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it { is_expected.to eq ["\"名字 名前\" <aaa@example.jp>"] }
    end

    context "with Basic ISO-2022-JP + Quoted-Printable encoded address" do
      let(:address) { "=?ISO-2022-JP?Q?=1B$BL>;z=1B(B =1B$BL>A0=1B(B=?= <aaa@example.jp>" }
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it { is_expected.to eq ["名字 名前 <aaa@example.jp>"] }
    end

    context "with Extended ISO-2022-JP + Base64 encoded address" do
      let(:address) { "=?ISO-2022-JP?B?GyRCfGJ5dRsoQiAbJEItIS0iLSMbKEI=?= <aaa@example.jp>" }
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it { is_expected.to eq ["\"髙﨑 ①②③\" <aaa@example.jp>"] }
    end

    context "with invalid address: encoding is broken" do
      let(:address) { "=?ISO-2022-JP?B?GyRCQzRFdiEnOzOUMxsoQg==?= <aaa@example.jp>" }
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it { is_expected.to eq ["\"担当：山��\" <aaa@example.jp>"] }
    end

    context "with invalid address: local part contains multi-byte chars and spaces" do
      let(:address) { "=?ISO-2022-JP?B?GyRCJCIbKEIgGyRCJCQbKEIg?=@example.jp" }
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it { is_expected.to eq ["あ い @example.jp"] }
    end

    context "with invalid address: multiple invalid address at one field" do
      let(:address) do
        %w[
          =?ISO-2022-JP?B?GyRCJCIbKEIgGyRCJCQbKEIg?=@example.jp
          =?ISO-2022-JP?B?GyRCfGJ5dRsoQiAbJEItIS0iLSMbKEI=?=@example.jp
          =?ISO-2022-JP?B?GyRCQzRFdiEnOzOUMxsoQg==?=@example.jp
        ].join(", ") + ","
      end
      let(:field) { ::Mail::Field.parse("To: #{address}") }
      subject { Webmail::Mail.new.parse_address_field(field) }

      it do
        is_expected.to have(3).items
        expect(subject[0]).to eq "あ い @example.jp"
        expect(subject[1]).to eq "髙﨑 ①②③@example.jp"
        expect(subject[2]).to eq "担当：山��@example.jp"
      end
    end
  end

  describe "#parse_references" do
    context "with nil" do
      subject { Webmail::Mail.new.parse_references(nil) }
      it { is_expected.to eq [] }
    end

    context "with scalar" do
      subject { Webmail::Mail.new.parse_references("abc") }
      it { is_expected.to eq %w(abc) }
    end

    context "with blank array" do
      subject { Webmail::Mail.new.parse_references([]) }
      it { is_expected.to eq [] }
    end

    context "with array of scalar" do
      subject { Webmail::Mail.new.parse_references(%w(abc)) }
      it { is_expected.to eq %w(abc) }
    end
  end

  describe "#parse_subject" do
    around do |example|
      Webmail.activate_cp50221 do
        example.run
      end
    end

    context "with UTF-8 + Base64" do
      let(:header) do
        [
          "Subject: =?UTF-8?B?44K/44Kk44OI44OrIOmhjOWQjQ==?="
        ].join("\r\n") + "\r\n"
      end
      let(:mail) { ::Mail.read_from_string(header) }
      subject { Webmail::Mail.new.parse_subject(mail) }

      it { is_expected.to eq "タイトル 題名" }
    end

    context "with UTF-8 + Quoted-Printable" do
      let(:header) do
        [
          "Subject: =?UTF-8?Q?=E3=82=BF=E3=82=A4=E3=83=88=E3=83=AB =E9=A1=8C=E5=90=8D=?="
        ].join("\r\n") + "\r\n"
      end
      let(:mail) { ::Mail.read_from_string(header) }
      subject { Webmail::Mail.new.parse_subject(mail) }

      it { is_expected.to eq "タイトル 題名" }
    end

    context "with Basic ISO-2022-JP + Base64" do
      let(:header) do
        [
          "Subject: =?ISO-2022-JP?B?GyRCJT8lJCVIJWsbKEIgGyRCQmpMPhsoQg==?="
        ].join("\r\n") + "\r\n"
      end
      let(:mail) { ::Mail.read_from_string(header) }
      subject { Webmail::Mail.new.parse_subject(mail) }

      it { is_expected.to eq "タイトル 題名" }
    end

    # context "with Basic ISO-2022-JP + Quoted-Printable" do
    #   let(:header) do
    #     [
    #       "Subject: =?ISO-2022-JP?Q?=1B$B%?%$%H%k=1B(B =1B$BBjL>=1B(B=?="
    #     ].join("\r\n") + "\r\n"
    #   end
    #   let(:mail) { ::Mail.read_from_string(header) }
    #   subject { Webmail::Mail.new.parse_subject(mail) }
    #
    #   it { is_expected.to eq "タイトル 題名" }
    # end

    context "with Extended ISO-2022-JP + Base64 encoded address" do
      let(:header) do
        [
          "Subject: =?ISO-2022-JP?B?GyRCfGJ5dRsoQiAbJEItIS0iLSMbKEI=?="
        ].join("\r\n") + "\r\n"
      end
      let(:mail) { ::Mail.read_from_string(header) }
      subject { Webmail::Mail.new.parse_subject(mail) }

      it { is_expected.to eq "髙﨑 ①②③" }
    end

    context "with broken encoding" do
      let(:header) do
        [
          "Subject: =?ISO-2022-JP?B?GyRCQzRFdiEnOzOUMxsoQg==?="
        ].join("\r\n") + "\r\n"
      end
      let(:mail) { ::Mail.read_from_string(header) }
      subject { Webmail::Mail.new.parse_subject(mail) }

      it { is_expected.to eq "担当：山��" }
    end
  end
end
