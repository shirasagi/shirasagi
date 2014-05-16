# coding: utf-8
SS::Application.routes.draw do
  
  match "*public_path" => "cms/public#index", public_path: /[^\.].*/,
    via: [:get, :post, :put, :patch, :destroy], format: true
  match "*public_path" => "cms/public#index", public_path: /[^\.].*/,
    via: [:get, :post, :put, :patch, :destroy], format: false
  
  root "cms/public#index", defaults: { format: :html }
  
end
