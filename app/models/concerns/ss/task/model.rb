# coding: utf-8
module SS::Task::Model
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Document
  include SS::Reference::User

  included do
    store_in collection: "ss_tasks"

    field :name, type: String
    field :state, type: String
    field :started, type: DateTime
    field :closed, type: DateTime
  end

  def running?
    state == "running"
  end

  def start
    return false if running?

    self.started = Time.now
    self.state   = "running"
    save
  end

  def close
    self.closed = Time.now
    self.state  = "stop"
    save
  end

  module ClassMethods
    public
      def run(name, opts = {})
        keys   = name.split(":")
        action = keys.pop
        cont   = "#{keys[0]}/task/" + keys[1..-1].join("/")
        cont   = "#{cont.pluralize.camelize}Controller".constantize.new
        task   = self.find_or_create_by opts.merge(name: name)

        if task.start
          cont.send(action, opts)
          task.close
        end
      end
  end
end
