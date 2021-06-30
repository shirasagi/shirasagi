require 'spec_helper'

describe Browser do
  let(:accept_language) { "ja,en-US;q=0.9,en;q=0.8" }
  subject { Browser.new(user_agent, accept_language: accept_language) }

  context "when Safari's user agent is given" do
    let(:user_agent) do
      "Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.124 Safari/537.36"
    end

    it do
      expect(subject.bot?).to be_falsey
    end
  end

  context "when Line Spider's user agent is given" do
    let(:user_agent) { "Mozilla/5.0 (compatible; Linespider/1.1; +https://lin.ee/4dwXkTH)" }

    it do
      expect(subject.bot?).to be_truthy
    end
  end
end
