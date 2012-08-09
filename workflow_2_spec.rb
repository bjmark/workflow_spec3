#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'ruote'   
require 'pp'
require './workflow_share'

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
		# "发起人(主办或协办)"
		process(:business_manager)		

		#"本业务部负责人"
		process(:business_dept_head)

		# "项目审查岗"
		process(:risk_dept_examiner)

		#"法务岗审核"
		process(:risk_dept_legal_examiner)

		#"风险部负责人"
		process(:risk_dept_head)

		#"资金管理岗"
		process(:capital_manager)

		#"金融市场部负责人"
		process(:capital_market_dept_head) do |wi|
			op_name = '终审通过'
			exec_submit(wi,op_name)
		end

		process(:completer) 

		@workitem.fields['ok'].should == '1'
		@road.last.should == :completer
	end

	it "从项目审查退回到发起审签" do
		# "发起人(主办或协办)"
		process(:business_manager)		

		#"本业务部负责人"
		process(:business_dept_head)

		# "项目审查岗"
		process(:risk_dept_examiner) do |wi|
			op_name = '退回到发起审签'
			exec_submit(wi,op_name)
		end

		process(:business_manager)		
		@road.last.should == :business_manager
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
