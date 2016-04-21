require 'spec_helper'

describe 'ss_915' do
  let(:model) do
    Class.new do
      include Mongoid::Document
      store_in collection: "anonymous_#{unique_id}"
      field :released, type: DateTime
    end
  end

  before do
    model.create(released: Time.zone.at(100))
    model.create(released: Time.zone.at(200))
  end

  it do
    Mongoid::QueryCache.clear_cache
    Mongoid::QueryCache.cache do
      expect(model.all.order_by(released: 1).first.released).to eq Time.zone.at(100)
      expect(model.all.order_by(released: -1).first.released).to eq Time.zone.at(200)
      expect(model.all.order_by(id: 1).first.id).not_to eq model.all.order_by(id: -1).first.id
    end
  end
end
