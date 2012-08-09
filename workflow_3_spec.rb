#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'ruote'   
require 'pp'
require './workflow_share'

def set_final_right(workitem,final_right)
	workitem.fields.delete(workitem.fields['final_right'])
	workitem.fields['final_right'] = final_right

	workitem.fields[final_right] = {
		"终审通过" => {'command' => 'jump to finish','ok' => '1'},
		"终审否决" => {'command' => 'jump to finish','ok' => '0'}
	}
end

def workflow3_step4(workitem,final_right)
	set_final_right(workitem,final_right)
end

describe '放款审批' do
	before(:each) do 
		@hash_storage = Ruote::HashStorage.new() 
		@worker = Ruote::Worker.new(@hash_storage) 
		@engine = Ruote::Engine.new(@worker) 

		@engine.register do
			catchall Ruote::StorageParticipant
		end

		workflow_t = File.open('workflow_3.rb') {|f| f.read} 
		@wfid = @engine.launch(workflow_t)

		@road = []
	end

	after(:each) do
		@engine.shutdown
	end

	it "付款审核退到发起审签" do
		process(:business_manager)
		process(:business_dept_head)
		
		process(:risk_dept_examiner) do |wi|
			op_name = '退到发起审签'
			exec_submit(wi,op_name)
		end

		process(:business_manager)
		@road.last.should == :business_manager 
	end

	it "从副总裁退到风险部负责人" do
		#业务部审核 
		#发起人(主办或协办)
		process(:business_manager)

		#本业务部负责人
		process(:business_dept_head)

		#风险部审核 
		#风险管理部审查岗
		process(:risk_dept_examiner)

		#风险管理部复核岗
		process(:risk_dept_reviewer)

		#风险部负责人
		process(:risk_dept_head)

		#金融市场部
		#资金管理岗
		process(:capital_manager)

		#金融市场部负责人
		process(:capital_market_dept_head)

		#计财部审核 
		#会计审核岗审核
		process(:accounting_dept_accounting_post)

		#计财部负责人审核
		process(:accounting_dept_head)

		#分管副总裁
		process(:vp) do |wi|
			op_name = '退到风险部负责人'
			exec_submit(wi,op_name)
		end

		process(:risk_dept_head)

		@road.last.should == :risk_dept_head
	end

	it "终审权给副总裁" do
		#业务部审核 
		#发起人(主办或协办)
		process(:business_manager)

		#本业务部负责人
		process(:business_dept_head)

		#风险部审核 
		#风险管理部审查岗
		process(:risk_dept_examiner)

		#风险管理部复核岗
		process(:risk_dept_reviewer) do |wi|
			action = wi.fields['params']['action']
			action.should == 'workflow3_step4'
			final_right = 'step_vp'
			send(action,wi,final_right)
		end

		#风险部负责人
		process(:risk_dept_head)

		#金融市场部
		#资金管理岗
		process(:capital_manager)

		#金融市场部负责人
		process(:capital_market_dept_head)

		#计财部审核 
		#会计审核岗审核
		process(:accounting_dept_accounting_post)

		#计财部负责人审核
		process(:accounting_dept_head)

		#分管副总裁
		process(:vp) do |wi|
			submit = merge_submit(wi)
			submit.should == {
				"上一步:会计审核岗审核" => "jump to step9",
				"下一步:总裁审核" => nil,
				'退到风险部负责人' => 'jump to step5',
				"终审通过" => {'command' => 'jump to finish','ok' => '1'},
				"终审否决" => {'command' => 'jump to finish','ok' => '0'}
			}

			op_name = '终审通过'
			exec_submit(wi,op_name)
		end

		process(:completer) do|wi|
			wi.fields['ok'].should == '1'
		end

		@road.last.should == :completer
	end

	it "完美路线" do
		#业务部审核 
		#发起人(主办或协办)
		process(:business_manager)

		#本业务部负责人
		process(:business_dept_head)

		#风险部审核 
		#风险管理部审查岗
		process(:risk_dept_examiner)

		#风险管理部复核岗
		process(:risk_dept_reviewer)

		#风险部负责人
		process(:risk_dept_head)

		#金融市场部
		#资金管理岗
		process(:capital_manager)

		#金融市场部负责人
		process(:capital_market_dept_head)

		#计财部审核 
		#会计审核岗审核
		process(:accounting_dept_accounting_post)

		#计财部负责人审核
		process(:accounting_dept_head)

		#分管副总裁
		process(:vp)

		#总裁
		process(:president)

		process(:completer) do |wi|
			@engine.storage_participant.by_wfid(@wfid).size.should == 1
		end

		@road.last.should == :completer
		
		@engine.storage_participant.by_wfid(@wfid).should == []
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
