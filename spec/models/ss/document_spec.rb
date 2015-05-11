require 'spec_helper'

RSpec.describe SS::Document, type: :model, dbscope: :example do
  class Klass
    include SS::Document
  end

  it do
    Timecop.scale(1_000_000_000)
    object = Klass.new
    expect(object.created == object.updated).to be_truthy
    Timecop.return
  end
end
