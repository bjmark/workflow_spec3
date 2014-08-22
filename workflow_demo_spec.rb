#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yajl' 
require 'redis' # gem install redis
require 'ruote' # gem install ruote
require 'ruote-redis' # gem install ruote-redis

def process(parti_name)
	storage_p = @engine.storage_participant
	n = 1
	while n < 5
		workitems = storage_p.by_participant(parti_name.to_s)
		if workitems and !workitems.empty?
			workitem = workitems.first
      yield workitem if block_given?
			storage_p.proceed(workitem) 
			@road << parti_name
			break
		end

		sleep(1)
		n += 1
	end
end

describe 'demo' do
  before(:each) do 
    @storage = Ruote::HashStorage.new() 
    @worker = Ruote::Worker.new(@storage) 
    @engine = Ruote::Dashboard.new(@worker) 

    @engine.register do
      catchall Ruote::StorageParticipant
    end

    wf_def = File.open('workflow_demo.rb') {|f| f.read} 

    @wfid = @engine.launch(wf_def)

    @road = []
  end

  after(:each) do
    @engine.shutdown
  end

  specify do
    process('demo1') do |e|
      e.participant_name.should == 'demo1'
    end
    process('demo2')
    process('demo3')
    @road.should == ['demo1', 'demo2', 'demo3']
  end
end
