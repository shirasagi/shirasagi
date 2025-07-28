module Guide::Addon
  module Procedure
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :link_url, type: String
      field :html, type: String
      field :procedure_location, type: String
      field :belongings, type: SS::Extensions::Lines
      field :procedure_applicant, type: SS::Extensions::Lines
      field :remarks, type: String

      permit_params :link_url
      permit_params :html
      permit_params :procedure_location
      permit_params :belongings
      permit_params :procedure_applicant
      permit_params :remarks
      permit_params :order

      %w(yes no or).each do |cond|
        field :"cond_#{cond}_edge_values", type: Array
        embeds_ids :"cond_#{cond}_questions", class_name: 'Guide::Question'
        permit_params "cond_#{cond}_edge_values": [:question_id, :edge_value],
          "cond_#{cond}_question_ids": []
      end

      template_variable_handler(:id, :template_variable_handler_name)
      template_variable_handler(:name, :template_variable_handler_name)
      template_variable_handler(:link_url, :template_variable_handler_name)
      template_variable_handler(:link, :template_variable_handler_link)
      template_variable_handler(:html, :template_variable_handler_html)
      template_variable_handler(:procedure_location, :template_variable_handler_name)
      template_variable_handler(:belongings, :template_variable_handler_name)
      template_variable_handler(:procedure_applicant, :template_variable_handler_name)
      template_variable_handler(:remarks, :template_variable_handler_name)

      liquidize do
        export :id
        export :name
        export :link_url
        export :link do
          link_url.present? ? "<a href=\"#{link_url}\">#{self.name}</a>".html_safe : self.name
        end
        export :html
        export :procedure_location
        export :belongings
        export :procedure_applicant
        export :remarks
      end
    end

    def template_variable_handler_name(name, issuer)
      ERB::Util.html_escape self.send(name)
    end

    def template_variable_handler_html(name, issuer)
      return nil unless respond_to?(name)
      self.send(name).present? ? self.send(name).html_safe : nil
    end

    def template_variable_handler_link(name, issuer)
      link_url.present? ? "<a href=\"#{link_url}\">#{self.name}</a>".html_safe : self.name
    end

    def referenced_questions
      Guide::Question.site(@cur_site || site).node(@cur_node || node).where(
        edges: {
          "$elemMatch" => { point_ids: { "$in" => [id] } }
        }
      )
    end

    def necessary_count
      cond_yes_edge_values.to_a.size
    end

    def not_necessary_count
      cond_no_edge_values.to_a.size
    end

    def optional_necessary_count
      cond_or_edge_values.to_a.size
    end

    private

    def set_edge_values
      %w(yes no or).each do |cond|
        next if self.send(:"cond_#{cond}_edge_values").blank?

        self.send(:"cond_#{cond}_edge_values").reject! { |v| v[:question_id].blank? && v[:edge_value].blank? }
      end
    end
  end
end
