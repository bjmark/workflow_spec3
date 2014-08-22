#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yajl' 
require 'redis' # gem install redis
require 'ruote' # gem install ruote
require 'ruote-redis' # gem install ruote-redis

=begin
class TestParticipant
end
=end

storage = 
	Ruote::Redis::Storage.new(::Redis.new(:db => 10, :thread_safe => true), {'ruby_eval_allowed' => true })

engine = Ruote::Dashboard.new(storage) 

engine.register do
	#catchall Ruote::StorageParticipant
	participant /test\d+$/, 'TestParticipant'
	#test2  'TestParticipant'
	#test3  'TestParticipant'
	#catchall 'TestParticipant'
end

