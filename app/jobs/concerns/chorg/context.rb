module Chorg::Context
  extend ActiveSupport::Concern

  attr_reader :cur_site, :cur_user, :adds_group_to_site, :item
  attr_reader :results, :substituter, :validation_substituter, :delete_group_ids

  def init_context
    @results = { "add" => { "success" => 0, "failed" => 0 },
                 "move" => { "success" => 0, "failed" => 0 },
                 "unify" => { "success" => 0, "failed" => 0 },
                 "division" => { "success" => 0, "failed" => 0 },
                 "delete" => { "success" => 0, "failed" => 0 } }
    @substituter = Chorg::Substituter.new
    @validation_substituter = Chorg::Substituter.new
    @delete_group_ids = []
  end

  def inc_counter(method, type)
    @results[method.to_s][type.to_s] += 1
  end
end
