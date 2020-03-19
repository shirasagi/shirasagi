require 'spec_helper'

describe Board::Post, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :board_node_post, cur_site: site, deny_url: 'allow' }

  describe "#sanitize_text" do
    context "with dangerous html" do
      let(:text) do
        text = []
        text << "<p>"
        text << '  <link rel="stylesheet" href="http://www.example.jp/dangerous.css">'
        text << '  <a href="http://www.example.jp/">危険なサイト1</a>'
        text << '  <a href="https://www.example.jp/">危険なサイト2</a>'
        text << '  <a href="mailto:aaa@example.jp">危険なサイト3</a>'
        text << '  <a href="javascript:alert(\'危険な操作\');">危険なサイト4</a>'
        text << '  <script>alert("危険な操作");</script>'
        text << '</p>'
        text.join("\n")
      end
      subject { build :board_post, cur_site: site, cur_node: node, text: text }

      it do
        expect(subject.sanitized_text).to include("危険なサイト1")
        expect(subject.sanitized_text).to include("危険なサイト2")
        expect(subject.sanitized_text).to include("危険なサイト3")
        expect(subject.sanitized_text).to include("危険なサイト4")
        expect(subject.sanitized_text).not_to include("http://www.example.jp/dangerous.css")
        expect(subject.sanitized_text).not_to include("http://www.example.jp/")
        expect(subject.sanitized_text).not_to include("https://www.example.jp/")
        expect(subject.sanitized_text).not_to include("mailto:aaa@example.jp")
        expect(subject.sanitized_text).not_to include("script")
      end
    end

    context "with url" do
      let(:url) { "http://#{unique_id}.example.jp/" }
      subject { build :board_post, cur_site: site, cur_node: node, text: url }

      it do
        # redirect through "/.mypage/redirect"
        expect(subject.sanitized_text).to include "/.mypage/redirect?ref=#{CGI.escape(url)}"
      end
    end
  end
end
