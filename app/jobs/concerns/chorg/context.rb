module Chorg::Context
  extend ActiveSupport::Concern

  included do
    cattr_accessor(:ss_mode, instance_accessor: false) { :cms }
    cattr_accessor(:substituter_class, instance_accessor: false) { Chorg::Substituter }
    cattr_accessor(:id_substituter_class, instance_accessor: false) { Chorg::Substituter::IdSubstituter }
    cattr_accessor(:group_classes, instance_accessor: false) do
      [ SS::Group, Cms::Group, Sys::Group, Gws::Group ].freeze
    end
    cattr_accessor(:group_class, instance_accessor: false) { Cms::Group }
    cattr_accessor(:user_class, instance_accessor: false) { Cms::User }
    cattr_accessor(:revision_class, instance_accessor: false) { Chorg::Revision }
    cattr_accessor(:config_p, instance_accessor: false) { ->{ SS.config.chorg } }

    attr_reader :cur_site, :cur_user, :adds_group_to_site, :item
    attr_reader :results, :substituter, :validation_substituter, :delete_group_ids
  end

  def init_context(opts = {})
    @results = { "add" => { "success" => 0, "failed" => 0 },
                 "move" => { "success" => 0, "failed" => 0 },
                 "unify" => { "success" => 0, "failed" => 0 },
                 "division" => { "success" => 0, "failed" => 0 },
                 "delete" => { "success" => 0, "failed" => 0 } }
    @substituter = self.class.substituter_class.new(opts)
    @validation_substituter = self.class.substituter_class.new(opts)
    @delete_group_ids = []

    task.init_entity_logs
  end

  def finalize_context
    task.finalize_entity_logs
  end

  def inc_counter(method, type)
    @results[method.to_s][type.to_s] += 1
  end
end
