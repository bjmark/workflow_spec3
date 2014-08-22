#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'ruote'   
require 'pp'
require './workflow_share'

describe '合同起租' do
	before(:each) do 
		@hash_storage = Ruote::HashStorage.new() 
		@worker = Ruote::Worker.new(@hash_storage) 
		@engine = Ruote::Engine.new(@worker) 

		@engine.register do
			catchall Ruote::StorageParticipant
		end

		workflow_t = File.open('workflow_4.rb') {|f| f.read} 
		@wfid = @engine.launch(workflow_t)

		@road = []
	end

	after(:each) do
		@engine.shutdown
	end

	it "完美路线" do
		#发起人(主办或协办)
		process(:business_manager)

		#本业务部负责人
		process(:business_dept_head)

		#风险管理部审查岗
		process(:risk_dept_examiner)

		#风险部负责人 
		process(:risk_dept_head)

		#业务核算岗审核
		process(:accounting_dept_accounting_post)

		#计财部负责人审核
		process(:accounting_dept_head) do |wi|
			op_name = '终审通过'
			exec_submit(wi,op_name)
		end

		process(:completer) 

		@workitem.fields['ok'].should == '1'
		@road.last.should == :completer
	end

	it "计财部负责人退回上一步业务核算岗审核" do
		#发起人(主办或协办)
		process(:business_manager)

		#本业务部负责人
		process(:business_dept_head)

		#风险管理部审查岗
		process(:risk_dept_examiner)

		#风险部负责人 
		process(:risk_dept_head)

		#业务核算岗审核
		process(:accounting_dept_accounting_post)

		#计财部负责人审核
		process(:accounting_dept_head) do |wi|
			op_name = '上一步:风险部负责人审核'
			exec_submit(wi,op_name)
		end

		process(:accounting_dept_accounting_post)
		@road.last.should == :accounting_dept_accounting_post
	end

	it '业务经理取消流程' do
		process(:business_manager) do |wi|
			op_name = '取消流程'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '2'
		end
	end
end
