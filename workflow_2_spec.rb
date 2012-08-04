#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'ruote'   
require 'pp'

def merge_submit(workitem)
	my_tag = workitem.fields['params']['tag']
	hash = workitem.fields[my_tag]
	submit = workitem.fields['params']['submit']

	return submit if !hash

	submit = submit.merge(hash)
	submit.delete_if{|k,v| v == 'del'}

	return submit
end

def exec_submit(workitem,op_name)
	submit = merge_submit(workitem)

	raise 'invalid workflow operation' if !submit.has_key?(op_name)
	op = submit[op_name]

	case op
	when String
		workitem.command = op
	when Hash
		op.each do |k,v|
			if k == 'command'
				workitem.command = v
			else
				workitem.fields[k] = v
			end
		end
	end
	return workitem
end

def process(parti_name,proceed=true)
	@engine.wait_for(parti_name)
	@storage_p = @engine.storage_participant
	@workitems = @storage_p.by_participant(parti_name.to_s)
	@workitem = @workitems.first

	yield @workitem if block_given?

	@storage_p.proceed(@workitem) if proceed

	@road << parti_name
end

describe '头寸报备' do
	before(:each) do 
		@hash_storage = Ruote::HashStorage.new() 
		@worker = Ruote::Worker.new(@hash_storage) 
		@engine = Ruote::Engine.new(@worker) 

		@engine.register do
			catchall Ruote::StorageParticipant
		end

		workflow_t = File.open('workflow_2.rb') {|f| f.read} 
		@wfid = @engine.launch(workflow_t)

		@road = []
	end

	after(:each) do
		@engine.shutdown
	end

	it "完美路线" do
		@road.last.should == :contract_management_post
	end
end
