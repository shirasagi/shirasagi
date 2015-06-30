module Opendata::Addon::MyIdeaList
  extend SS::Addon
  extend ActiveSupport::Concern
  include Cms::Addon::PageList

  public
    def template_variable_get(item, name)
      if name.start_with?('idea_')
        if index = name.index('.')
          param = name[index + 1..-1]
          name = name[0..index - 1]
        end

        send("get_#{name}", item, param) rescue super
      else
        super
      end
    end

  private
    def get_idea_name(item, *_)
      ERB::Util.html_escape item.name
    end

    def get_idea_url(item, *_)
      ERB::Util.html_escape "#{self.url}#{item.id}/"
    end

    def get_idea_updated(item, *args)
      format = args.shift
      format ||= I18n.t("opendata.labels.updated")
      I18n.l item.updated, format: format
    end

    def get_idea_state(item, *_)
      ERB::Util.html_escape(item.label :state)
    end

    def get_idea_point(item, *_)
      ERB::Util.html_escape(item.point.to_i.to_s)
    end

    def get_idea_datasets(item, *_)
      if item.dataset_ids.length > 0
        ERB::Util.html_escape(item.datasets[0].name)
      else
        ERB::Util.html_escape(I18n.t("opendata.labels.not_exist"))
      end
    end

    def get_idea_apps(item, *_)
      if item.app_ids.length > 0
        ERB::Util.html_escape(item.apps[0].name)
      else
        ERB::Util.html_escape(I18n.t("opendata.labels.not_exist"))
      end
    end

    def get_idea_ideas_count(item, *_)
      ERB::Util.html_escape(item.ideas.size.to_s)
    end
end
