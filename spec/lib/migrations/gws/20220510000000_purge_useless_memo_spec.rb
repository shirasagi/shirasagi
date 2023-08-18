require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20220510000000_purge_useless_memo.rb")

RSpec.describe SS::Migration20220510000000, dbscope: :example do
  let!(:message1) { create :gws_memo_message }
  let!(:message2) { create :gws_memo_message, user_settings: [], in_to_members: nil }
  let!(:message3) { create :gws_memo_message, user_settings: nil, in_to_members: nil }
  let!(:message4) { create :gws_memo_message, user_settings: nil, in_to_members: nil }

  before do
    Gws::Memo::Message.find(message2.id).tap do |message|
      # message2 の user_settings を強制的に空配列をセット
      message.set(user_settings: [])
    end
    Gws::Memo::Message.find(message3.id).tap do |message|
      # message3 の user_settings を強制的に nil をセット
      message.set(user_settings: nil)
    end
    Gws::Memo::Message.find(message4.id).tap do |message|
      # message3 の user_settings を強制的に削除
      message.unset(:user_settings)
    end

    Gws::Memo::Message.collection.find({ "_id" => message2.id }).tap do |view|
      expect(view.first["user_settings"]).to eq []
    end
    Gws::Memo::Message.collection.find({ "_id" => message3.id }).tap do |view|
      expect(view.first["user_settings"]).to be_nil
    end
    Gws::Memo::Message.collection.find({ "_id" => message4.id }).tap do |view|
      expect(view.first.key?("user_settings")).to be_falsey
    end

    described_class.new.change
  end

  it do
    expect { message1.reload }.not_to raise_error
    expect { message2.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    expect { message3.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    expect { message4.reload }.to raise_error Mongoid::Errors::DocumentNotFound
  end
end
