#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yajl' 
require 'redis' # gem install redis
require 'ruote'   
require 'ruote-redis' # gem install ruote-redis

storage = Ruote::Redis::Storage.new(::Redis.new(:db => 10, :thread_safe => true), {'ruby_eval_allowed' => true })
worker = Ruote::Worker.new(storage) 
worker.run
