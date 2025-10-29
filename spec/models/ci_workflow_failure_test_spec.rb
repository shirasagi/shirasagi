require 'spec_helper'

RSpec.describe 'CI Workflow Failure Test', type: :model, dbscope: :example do
  describe "意図的に失敗するテスト" do
    it "必ず失敗する: 等価性アサーション" do
      # このテストはCIワークフローの失敗処理をテストするために、意図的に失敗させます
      expect(1).to eq 2
    end

    it "必ず失敗する: nilアサーション" do
      value = "not nil"
      expect(value).to be_nil
    end

    it "必ず失敗する: カウントアサーション" do
      items = %w[a b c]
      expect(items.size).to eq 100
    end

    it "必ず失敗する: 真偽値アサーション" do
      value = true
      expect(value).to be_falsey
    end

    it "必ず失敗する: 文字列マッチ" do
      string = "test string"
      expect(string).to eq "completely different string"
    end
  end
end
