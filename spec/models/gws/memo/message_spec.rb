require 'spec_helper'

RSpec.describe Gws::Memo::Message, type: :model do
  context 'default params' do
    let(:memo) { create(:gws_memo_message) }
    it { expect(memo.errors.size).to eq 0 }
  end

  context 'when in_path is { gws_user.id.to_s => "INBOX.Trash" }' do
    let(:user) { Gws::User.find_by(uid: 'sys') }
    let(:memo) do
      create(:gws_memo_message, in_to_members: [gws_user.id.to_s, user.id.to_s], in_path: {
        gws_user.id.to_s => 'INBOX.Trash',
        user.id.to_s => 'INBOX.Trash'
      })
    end
    it do
      expect(memo.errors.size).to eq 0

      memo.set_seen(gws_user)
      expect(memo.path(gws_user)).to eq 'INBOX.Trash'
      expect(memo.path(user)).to eq 'INBOX.Trash'
      expect(memo.seen_at(gws_user)).to be_truthy
      expect(memo.seen_at(user)).to be_falsey

      memo.move(user, 'INBOX').update
      expect(memo.path(gws_user)).to eq 'INBOX.Trash'
      expect(memo.path(user)).to eq 'INBOX'
      expect(memo.seen_at(gws_user)).to be_truthy
      expect(memo.seen_at(user)).to be_falsey

      memo.set_seen(user)
      expect(memo.path(gws_user)).to eq 'INBOX.Trash'
      expect(memo.path(user)).to eq 'INBOX'
      expect(memo.seen_at(gws_user)).to be_truthy
      expect(memo.seen_at(user)).to be_truthy

      memo.unset_seen(gws_user)
      expect(memo.path(gws_user)).to eq 'INBOX.Trash'
      expect(memo.path(user)).to eq 'INBOX'
      expect(memo.seen_at(gws_user)).to be_falsey
      expect(memo.seen_at(user)).to be_truthy

      inbox_trash = Gws::Memo::Folder.static_items(gws_user, gws_site).find { |dir| dir.folder_path == 'INBOX.Trash' }
      memo.destroy_from_folder(gws_user, inbox_trash)
      expect(memo.path(gws_user)).to be_falsey
      expect(memo.path(user)).to eq 'INBOX'
      expect(memo.seen_at(gws_user)).to be_falsey
      expect(memo.seen_at(user)).to be_truthy

      inbox = Gws::Memo::Folder.static_items(user, gws_site).find { |dir| dir.folder_path == 'INBOX' }
      memo.destroy_from_folder(user, inbox)
      expect(memo.path(gws_user)).to be_falsey
      expect(memo.path(user)).to be_falsey
      expect(memo.seen_at(gws_user)).to be_falsey
      expect(memo.seen_at(user)).to be_falsey

      inbox_sent = Gws::Memo::Folder.static_items(gws_user, gws_site).find { |dir| dir.folder_path == 'INBOX.Sent' }
      memo.destroy_from_folder(gws_user, inbox_sent)
      expect(memo.deleted['sent']).to be_truthy
    end
  end

  context 'when gws/shared_group is given' do
    let(:site) { gws_site }
    let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:shared_address_group1) { create :gws_shared_address_group, order: 10, readable_setting_range: "public" }
    let!(:shared_address1) do
      create(
        :gws_shared_address_address, address_group: shared_address_group1, member: user1, name: user1.name,
        readable_setting_range: "public"
      )
    end
    let!(:shared_address2) do
      create(
        :gws_shared_address_address, address_group: shared_address_group1, member: user2, name: user2.name,
        readable_setting_range: "public"
      )
    end
    subject! do
      create(
        :gws_memo_message, cur_site: site, cur_user: user3, in_to_members: [ "shared_group:#{shared_address_group1.id}" ]
      )
    end

    it do
      expect(subject).to be_valid

      expect(subject.site_id).to eq site.id
      expect(subject.from.id).to eq user3.id
      expect(subject.to_member_ids).to be_blank
      expect(subject.to_webmail_address_group_ids).to be_blank
      expect(subject.to_shared_address_group_ids).to eq [ shared_address_group1.id ]
      expect(subject.to_member_name).to eq shared_address_group1.name
      expect(subject.cc_member_ids).to be_blank
      expect(subject.cc_webmail_address_group_ids).to be_blank
      expect(subject.cc_shared_address_group_ids).to be_blank
      expect(subject.bcc_member_ids).to be_blank
      expect(subject.bcc_webmail_address_group_ids).to be_blank
      expect(subject.bcc_shared_address_group_ids).to be_blank
      expect(subject.request_mdn).to be_blank
      expect(subject.member_ids).to have(2).items
      expect(subject.member_ids).to include(user1.id, user2.id)
      expect(subject.path(user1)).to eq 'INBOX'
      expect(subject.seen_at(user1)).to be_falsey
      expect(subject.path(user2)).to eq 'INBOX'
      expect(subject.seen_at(user2)).to be_falsey
      expect(subject.user_settings).to have(2).items
      expect(subject.user_settings).to include("user_id" => user1.id, "path" => "INBOX")
      expect(subject.user_settings).to include("user_id" => user2.id, "path" => "INBOX")
    end
  end

  context "when webmail/address_group is given" do
    let(:site) { gws_site }
    let(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:address_group1) { create :webmail_address_group, cur_user: user1 }
    let!(:address1) do
      create :webmail_address, cur_user: user1, address_group: address_group1, member: user2, name: user2.name
    end
    let!(:address2) do
      create :webmail_address, cur_user: user1, address_group: address_group1, member: user3, name: user3.name
    end
    subject! do
      create(
        :gws_memo_message, cur_site: site, cur_user: user1, in_to_members: [ "webmail_group:#{address_group1.id}" ]
      )
    end

    it do
      expect(subject).to be_valid

      expect(subject.site_id).to eq site.id
      expect(subject.from.id).to eq user1.id
      expect(subject.to_member_ids).to be_blank
      expect(subject.to_webmail_address_group_ids).to eq [ address_group1.id ]
      expect(subject.to_shared_address_group_ids).to be_blank
      expect(subject.to_member_name).to eq address_group1.name
      expect(subject.cc_member_ids).to be_blank
      expect(subject.cc_webmail_address_group_ids).to be_blank
      expect(subject.cc_shared_address_group_ids).to be_blank
      expect(subject.bcc_member_ids).to be_blank
      expect(subject.bcc_webmail_address_group_ids).to be_blank
      expect(subject.bcc_shared_address_group_ids).to be_blank
      expect(subject.request_mdn).to be_blank
      expect(subject.member_ids).to have(2).items
      expect(subject.member_ids).to include(user2.id, user3.id)
      expect(subject.path(user2)).to eq 'INBOX'
      expect(subject.seen_at(user1)).to be_falsey
      expect(subject.path(user3)).to eq 'INBOX'
      expect(subject.seen_at(user2)).to be_falsey
      expect(subject.user_settings).to have(2).items
      expect(subject.user_settings).to include("user_id" => user2.id, "path" => "INBOX")
      expect(subject.user_settings).to include("user_id" => user3.id, "path" => "INBOX")
    end
  end

  describe ".new_reply / .new_forward" do
    let!(:site) { gws_site }
    let!(:user) { gws_user }
    let!(:user1) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:user2) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:user3) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:user4) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:user5) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:user6) { create :gws_user, cur_site: site, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
    let!(:shared_address_group1) { create :gws_shared_address_group, order: 10, readable_setting_range: "public" }
    let!(:shared_address1) do
      create(
        :gws_shared_address_address, address_group: shared_address_group1, member: user2, name: user2.name,
        readable_setting_range: "public"
      )
    end
    let!(:shared_address_group2) { create :gws_shared_address_group, order: 10, readable_setting_range: "public" }
    let!(:shared_address2) do
      create(
        :gws_shared_address_address, address_group: shared_address_group2, member: user5, name: user5.name,
        readable_setting_range: "public"
      )
    end
    let!(:address_group1) { create :webmail_address_group, cur_user: user }
    let!(:address1) do
      create :webmail_address, cur_user: user, address_group: address_group1, member: user3, name: user3.name
    end
    let!(:address_group2) { create :webmail_address_group, cur_user: user }
    let!(:address2) do
      create :webmail_address, cur_user: user, address_group: address_group2, member: user6, name: user6.name
    end
    let(:item_text) { Array.new(2) { "text-#{unique_id}" }.join("\n") }
    let(:item_html) { "<p>#{Array.new(2) { "html-#{unique_id}" }.join("<br>")}</p>" }
    let!(:item) do
      create(
        :gws_memo_message, cur_site: site, cur_user: user, format: "text", text: item_text, html: item_html,
        in_to_members: [ user1.id.to_s, "shared_group:#{shared_address_group1.id}", "webmail_group:#{address_group1.id}" ],
        in_cc_members: [ user4.id.to_s, "shared_group:#{shared_address_group2.id}", "webmail_group:#{address_group2.id}" ])
    end

    before do
      expect(item.to_member_ids).to eq [ user1.id ]
      expect(item.to_shared_address_group_ids).to eq [ shared_address_group1.id ]
      expect(item.to_webmail_address_group_ids).to eq [ address_group1.id ]
      expect(item.cc_member_ids).to eq [ user4.id ]
      expect(item.cc_shared_address_group_ids).to eq [ shared_address_group2.id ]
      expect(item.cc_webmail_address_group_ids).to eq [ address_group2.id ]
    end

    context "when user reply to 'sender'" do
      subject { described_class.new_reply(item, cur_site: site, cur_user: user1, respond_to: :sender) }

      it do
        expect(subject.subject).to eq "Re: #{item.subject}"
        expect(subject.to_member_ids).to eq [ user.id ]
        expect(subject.to_shared_address_group_ids).to be_blank
        expect(subject.to_webmail_address_group_ids).to be_blank
        expect(subject.cc_member_ids).to be_blank
        expect(subject.cc_shared_address_group_ids).to be_blank
        expect(subject.cc_webmail_address_group_ids).to be_blank
        expect(subject.format).to eq item.format
        Nokogiri::HTML.fragment(subject.html).tap do |fragment|
          expect(fragment.elements.count).to eq 1
          root_node = fragment.elements[0]
          expect(root_node.type).to eq Nokogiri::XML::Node::ELEMENT_NODE
          expect(root_node.name).to eq "figure"
          expect(root_node.elements.count).to eq 2

          caption_node = root_node.elements[0]
          expect(caption_node.name).to eq "figcaption"
          expect(caption_node.text).to include(I18n.l(item.send_date, format: :long), user.long_name)

          quote_node = root_node.elements[1]
          expect(quote_node.name).to eq "blockquote"
          # item.format が "text" なため、item.html ではなく item.text を用いて返信本文が作成されるはず。
          expected_html = Gws::Memo.text_to_html(item_text)
          expected_fragment = Nokogiri::HTML.fragment(expected_html)
          expect(quote_node.inner_html).to include(expected_fragment.to_html)
        end
        expect(subject.text).to include(I18n.l(item.send_date, format: :long), user.long_name)
        expect(subject.text).to include(*item.text.split(/\R/).map { |text| "> #{text}" })
      end
    end

    context "when user reply to 'all'" do
      subject { described_class.new_reply(item, cur_site: site, cur_user: user1, respond_to: :all) }

      it do
        expect(subject.subject).to eq "Re: #{item.subject}"
        # user1 は item の to_webmail_address_group_ids や cc_webmail_address_group_ids にセットされている
        # address_group1 や address_group2 を閲覧できないので、to_webmail_address_group_ids や cc_webmail_address_group_ids は
        # 空になる。
        expect(subject.to_member_ids).to eq [ item.user_id ]
        expect(subject.to_shared_address_group_ids).to eq [ shared_address_group1.id ]
        expect(subject.to_webmail_address_group_ids).to be_blank
        expect(subject.cc_member_ids).to eq [ user4.id ]
        expect(subject.cc_shared_address_group_ids).to eq [ shared_address_group2.id ]
        expect(subject.cc_webmail_address_group_ids).to be_blank
        expect(subject.format).to eq item.format
        Nokogiri::HTML.fragment(subject.html).tap do |fragment|
          expect(fragment.elements.count).to eq 1
          root_node = fragment.elements[0]
          expect(root_node.type).to eq Nokogiri::XML::Node::ELEMENT_NODE
          expect(root_node.name).to eq "figure"
          expect(root_node.elements.count).to eq 2

          caption_node = root_node.elements[0]
          expect(caption_node.name).to eq "figcaption"
          expect(caption_node.text).to include(I18n.l(item.send_date, format: :long), user.long_name)

          quote_node = root_node.elements[1]
          expect(quote_node.name).to eq "blockquote"
          # item.format が "text" なため、item.html ではなく item.text を用いて返信本文が作成されるはず。
          expected_html = Gws::Memo.text_to_html(item_text)
          expected_fragment = Nokogiri::HTML.fragment(expected_html)
          expect(quote_node.inner_html).to include(expected_fragment.to_html)
        end
        expect(subject.text).to include(I18n.l(item.send_date, format: :long), user.long_name)
        expect(subject.text).to include(*item.text.split(/\R/).map { |text| "> #{text}" })
      end
    end

    context "when user forward message" do
      subject { described_class.new_forward(item, cur_site: site, cur_user: user1) }

      it do
        expect(subject.subject).to eq "Fwd: #{item.subject}"
        expect(subject.to_member_ids).to be_blank
        expect(subject.to_shared_address_group_ids).to be_blank
        expect(subject.to_webmail_address_group_ids).to be_blank
        expect(subject.cc_member_ids).to be_blank
        expect(subject.cc_shared_address_group_ids).to be_blank
        expect(subject.cc_webmail_address_group_ids).to be_blank
        expect(subject.format).to eq item.format
        Nokogiri::HTML.fragment(subject.html).tap do |fragment|
          expect(fragment.children.count).to be > 4
          expect(fragment.children[0].text).to include(I18n.t("gws/memo/message.forward_message_header"))

          expect(fragment.elements.count).to eq 4
          expect(fragment.elements[0].name).to eq "br"

          table_node = fragment.elements[1]
          expect(table_node.name).to eq "figure"
          td_nodes = table_node.css("td")
          expect(td_nodes[1].text).to include(item.subject)
          expect(td_nodes[3].text).to include(I18n.l(item.send_date, format: :long))
          expect(td_nodes[5].text).to include(user.long_name)

          expect(fragment.elements[2].name).to eq "br"
          expect(fragment.elements[3].name).to eq "p"
        end
        expect(subject.text).to include(item.subject, I18n.l(item.send_date, format: :long), user.long_name)
        expect(subject.text).to include(*item.text.split(/\R/).map { |text| "> #{text}" })
      end
    end
  end
end
