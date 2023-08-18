require 'spec_helper'

describe Chat::Part::Bot, type: :model, dbscope: :example do
  let(:item) { create :chat_part_bot }
  it_behaves_like "cms_part#spec"
end
