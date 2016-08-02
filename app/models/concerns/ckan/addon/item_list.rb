module Ckan::Addon::ItemList
  extend ActiveSupport::Concern
  extend SS::Addon
  include Cms::Addon::List::Model
  include SS::TemplateVariable

  included do
    template_variable_handler :id, :template_variable_handler_name
    template_variable_handler :revision_id, :template_variable_handler_name
    template_variable_handler :title, :template_variable_handler_name
    template_variable_handler :license_id, :template_variable_handler_name
    template_variable_handler :license_title, :template_variable_handler_name
    template_variable_handler :license_url, :template_variable_handler_name
    template_variable_handler :author, :template_variable_handler_name
    template_variable_handler :author_email, :template_variable_handler_name
    template_variable_handler :maintainer, :template_variable_handler_name
    template_variable_handler :maintainer_email, :template_variable_handler_name
    template_variable_handler :num_tags, :template_variable_handler_name
    template_variable_handler :num_resources, :template_variable_handler_name
    template_variable_handler :private, :template_variable_handler_name
    template_variable_handler :state, :template_variable_handler_name
    template_variable_handler :version, :template_variable_handler_name
    template_variable_handler :type, :template_variable_handler_name
    template_variable_handler :created_date, :template_variable_handler_created_date
    template_variable_handler :'created_date.iso', ->(name, value){ template_variable_handler_created_date(name, value, 'iso') }
    template_variable_handler :'created_date.long', ->(name, value){ template_variable_handler_created_date(name, value, 'long') }
    template_variable_handler :updated_date, :template_variable_handler_updated_date
    template_variable_handler :'updated_date.iso', ->(name, value){ template_variable_handler_updated_date(name, value, 'iso') }
    template_variable_handler :'updated_date.long', ->(name, value){ template_variable_handler_updated_date(name, value, 'long') }
    template_variable_handler :created_time, :template_variable_handler_created_time
    template_variable_handler :'created_time.iso', ->(name, value){ template_variable_handler_created_time(name, value, 'iso') }
    template_variable_handler :'created_time.long', ->(name, value){ template_variable_handler_created_time(name, value, 'long') }
    template_variable_handler :updated_time, :template_variable_handler_updated_time
    template_variable_handler :'updated_time.iso', ->(name, value){ template_variable_handler_updated_time(name, value, 'iso') }
    template_variable_handler :'updated_time.long', ->(name, value){ template_variable_handler_updated_time(name, value, 'long') }
    template_variable_handler :group, :template_variable_handler_group
    template_variable_handler :groups, :template_variable_handler_groups
    template_variable_handler :organization, :template_variable_handler_organization
    template_variable_handler :add_or_update, :template_variable_handler_add_or_update
    template_variable_handler :add_or_update_text, :template_variable_handler_add_or_update_text
  end

  def sort_options
    [
      [I18n.t('cms.options.sort.name'), 'name'],
      [I18n.t('cms.options.sort.filename'), 'filename'],
      [I18n.t('cms.options.sort.created'), 'created'],
      [I18n.t('cms.options.sort.updated_1'), 'updated -1'],
      [I18n.t('cms.options.sort.released_1'), 'released -1'],
      [I18n.t('cms.options.sort.order'), 'order'],
    ]
  end

  def sort_hash
    return { released: -1 } if sort.blank?
    { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
  end

  # overwrites super class methods
  def render_loop_html(item, opts = {})
    render_template(opts[:html] || loop_html, item)
  end

  private
    # overwrites super class methods
    def template_variable_handler_name(name, value)
      if name == 'url'
        template_variable_handler_url(name, value)
      elsif name == 'summary'
        template_variable_handler_summary(name, value)
      else
        value[name].to_s
      end
    end

    def template_variable_handler_url(name, value)
      "#{ckan_item_url}/#{value['name']}"
    end

    def template_variable_handler_summary(name, value)
      value['notes']
    end

    def template_variable_handler_class(name, value)
      value['name']
    end

    def template_variable_handler_new(name, value)
      in_new_days?(Time.zone.parse(value['metadata_modified']).to_date) ? "new" : nil
    end

    def template_variable_handler_created_date(name, value, format = nil)
      if format.present?
        I18n.l ActiveSupport::TimeZone["UTC"].parse(value['metadata_created']).in_time_zone.to_date, format: format.to_sym
      else
        I18n.l ActiveSupport::TimeZone["UTC"].parse(value['metadata_created']).in_time_zone.to_date
      end
    end

    def template_variable_handler_updated_date(name, value, format = nil)
      if format.present?
        I18n.l ActiveSupport::TimeZone["UTC"].parse(value['metadata_modified']).in_time_zone.to_date, format: format.to_sym
      else
        I18n.l ActiveSupport::TimeZone["UTC"].parse(value['metadata_modified']).in_time_zone.to_date
      end
    end

    # overwrites super class methods
    def template_variable_handler_date(name, value, format = nil)
      template_variable_handler_updated_date(name, value, format)
    end

    def template_variable_handler_created_time(name, value, format = nil)
      if format.present?
        I18n.l ActiveSupport::TimeZone["UTC"].parse(value['metadata_created']).in_time_zone, format: format.to_sym
      else
        I18n.l ActiveSupport::TimeZone["UTC"].parse(value['metadata_created']).in_time_zone
      end
    end

    def template_variable_handler_updated_time(name, value, format = nil)
      if format.present?
        I18n.l ActiveSupport::TimeZone["UTC"].parse(value['metadata_modified']).in_time_zone, format: format.to_sym
      else
        I18n.l ActiveSupport::TimeZone["UTC"].parse(value['metadata_modified']).in_time_zone
      end
    end

    # overwrites super class methods
    def template_variable_handler_time(name, value, format = nil)
      template_variable_handler_updated_time(name, value, format)
    end

    def template_variable_handler_group(name, value)
      group = value['groups'].first
      group ? group['display_name'] : ""
    end

    def template_variable_handler_groups(name, value)
      value['groups'].map { |g| g['display_name'] }.join(", ")
    end

    def template_variable_handler_organization(name, value)
      organization = value['organization']
      organization ? organization['title'] : ""
    end

    def template_variable_handler_add_or_update(name, value)
      modified = Time.zone.parse(value['metadata_modified']) rescue Time.zone.at(0)
      created = Time.zone.parse(value['metadata_created']) rescue Time.zone.at(0)
      if in_new_days?(created.to_date)
        "add"
      elsif in_new_days?(modified.to_date)
        "update"
      end
    end

    def template_variable_handler_add_or_update_text(name, value)
      label = template_variable_handler_add_or_update(name, value)
      if label.present?
        label = I18n.t("ckan.node.page.#{label}")
      end
      label
    end
end
