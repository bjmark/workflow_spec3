#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yajl' 
require 'redis' # gem install redis
require 'ruote' # gem install ruote
require 'ruote-redis' # gem install ruote-redis
=begin
workflow_test_spec 的执行步骤
(1) ruby test_register.rb       注册参与者
(2) ruby test_worker.rb         启动 worker
(3) ./pwm                       执行launch test process
(4) ruby cancel_test.rb         cancel the test process 
结论：
注册可以一次性执行，现在在启动blade时同时注册8次，会不会有问题？
=end
def process(parti_name)
	storage_p = @engine.storage_participant
	n = 1
	while n < 5
		workitems = storage_p.by_participant(parti_name.to_s)
		if workitems and !workitems.empty?
			workitem = workitems.first
			storage_p.proceed(workitem) 
			
			@road << parti_name
			puts "processed #{parti_name}"
			
			break
		end

		sleep(1)
		#puts "sleep #{n} seconds"
		n += 1
	end
end

describe '测试' do
	before(:each) do 
		@hash_storage = 
			Ruote::Redis::Storage.new(::Redis.new(:db => 10, :thread_safe => true), {'ruby_eval_allowed' => true })

		@engine = Ruote::Dashboard.new(@hash_storage) 

		wf_def = File.open('workflow_test.rb') {|f| f.read} 

		@wfid = @engine.launch(wf_def)

		@road = []
	end

	after(:each) do
		@engine.shutdown
	end

	specify do
    process('test1')
    process('test2')
    process('test3')
		'ok'.should == 'ok'
	end
end
