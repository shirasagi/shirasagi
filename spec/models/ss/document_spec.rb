require 'spec_helper'

class Klass
  include SS::Document
end

RSpec.describe Klass, type: :model, dbscope: :example do
  it do
    Timecop.scale(1_000_000_000)
    object = Klass.new
    expect(object.created == object.updated).to be_truthy
    Timecop.return
  end
end
