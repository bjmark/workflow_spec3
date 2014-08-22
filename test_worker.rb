#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yajl' 
require 'redis' # gem install redis
require 'ruote' # gem install ruote
require 'ruote-redis' # gem install ruote-redis
require 'logger'

class TestParticipant
	include Ruote::LocalParticipant

	def initialize
		#@log = Logger.new('./log/test.log',5,10*1024)
		@log = Logger.new(STDOUT)
	end

	def on_workitem
		ref = workitem.fields['params']['ref']
		@log.info "#{ref} at #{Time.now} #{Process.pid}"
		sleep(1)
		
		if ref == 'test3' 
			test_number = (workitem.fields['test_number'] or 0)
			test_number += 1
			test_number %= 1000
			
			@log.info test_number.to_s.center(20,'*')
			
			workitem.fields['test_number'] = test_number
			workitem.command = 'rewind'
		end
		reply
	end
end

storage = 
	Ruote::Redis::Storage.new(::Redis.new(:db => 10, :thread_safe => true), {'ruby_eval_allowed' => true })

worker = Ruote::Worker.new(storage) 
worker.run
