module SS::Task::BaseFilter
  extend ActiveSupport::Concern

  private
    def task
      @task ||= params[:task]
    end

    def render(*args)
      super if args.size > 0
    end
end
