# coding: utf-8
module Cms::ReleaseFilter
  extend ActiveSupport::Concern

  private
    def recognize_path(path, env = {})
      env[:method] ||= request.request_method rescue "GET"

      rec = Rails.application.routes.recognize_path(path, env) rescue {}
      return nil unless rec[:cell]

      params.merge!(rec)
      { controller: rec[:cell], action: rec[:action] }
    end
end
