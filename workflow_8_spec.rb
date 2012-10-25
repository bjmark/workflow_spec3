#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'ruote'   
require 'pp'
require './workflow_share'

describe '租后检查' do
	before(:each) do 
		@hash_storage = Ruote::HashStorage.new() 
		@worker = Ruote::Worker.new(@hash_storage) 
		@engine = Ruote::Engine.new(@worker) 

		@engine.register do
			catchall Ruote::StorageParticipant
		end

		workflow_t = File.open('workflow_8.rb') {|f| f.read} 
		@wfid = @engine.launch(workflow_t)

		@road = []
	end

	after(:each) do
		@engine.shutdown
	end

	it "完美路线" do
		process(:business_manager)
		process(:business_dept_head) 
		process(:risk_dept_asset_manager)
		process(:risk_dept_head) do |wi|
			op_name = '签收租后检查报告'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '1'
		end
	end

	it '取消流程' do
		process(:business_manager) do |wi|
			op_name = '取消流程'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '2'
		end
	end

	it "退回业务部门" do
		process(:business_manager)
		process(:business_dept_head) 
		process(:risk_dept_asset_manager)
		process(:risk_dept_head) do |wi|
			op_name = '退回业务部门'
			exec_submit(wi,op_name)
		end

		process(:business_manager) 
		@road.last.should == :business_manager
	end
end
