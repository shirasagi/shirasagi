require 'spec_helper'

describe Webmail::Imap::Mail, type: :model, dbscope: :example do
  let!(:cond) { item.condition }

  context 'default scope' do
    subject(:item) { Webmail::Imap.mails }

    it do
      expect(cond[:mailbox]).to eq 'INBOX'
      expect(cond[:search]).to eq %w(UNDELETED)
      expect(cond[:sort]).to eq %w(REVERSE ARRIVAL)
      expect(cond[:page]).to eq 1
      expect(cond[:limit]).to eq 50
      expect(item.offset).to eq 0
      expect(item.imap).to eq Webmail::Imap
      expect(item.imap).to eq item.class.imap
    end
  end

  context 'custom scope' do
    subject(:item) do
      Webmail::Imap.mails.
        mailbox('INBOX.test').
        search(from: 'aaa', since: '2017-01-01').
        per(10).page(2)
    end

    it do
      expect(cond[:mailbox]).to eq 'INBOX.test'
      expect(cond[:search]).to eq %w(UNDELETED FROM aaa SINCE 1-Jan-2017)
      expect(cond[:page]).to eq 2
      expect(cond[:limit]).to eq 10
      expect(item.offset).to eq 10
    end
  end
end
