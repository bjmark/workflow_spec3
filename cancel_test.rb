#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yajl' 
require 'redis' # gem install redis
require 'ruote' # gem install ruote
require 'ruote-redis' # gem install ruote-redis


hash_storage = 
	Ruote::Redis::Storage.new(::Redis.new(:db => 10, :thread_safe => true), {'ruby_eval_allowed' => true })

engine = Ruote::Dashboard.new(hash_storage) 
status = engine.processes
status.each do |e|
  if e.definition_name == '测试'
		puts e.inspect
		engine.cancel_process(e.wfid)
	end
end
