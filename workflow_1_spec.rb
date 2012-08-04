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

describe '合同审签/变更' do
	before(:each) do 
		@hash_storage = Ruote::HashStorage.new() 
		@worker = Ruote::Worker.new(@hash_storage) 
		@engine = Ruote::Engine.new(@worker) 

		@engine.register do
			catchall Ruote::StorageParticipant
		end

		workflow_t = File.open('workflow_1.rb') {|f| f.read} 
		@wfid = @engine.launch(workflow_t)

		@road = []
	end

	after(:each) do
		@engine.shutdown
	end

	it "从<业务部负责人审核>返回上一步" do
		process(:business_manager)
		process(:business_dept_head) do |wi| 
			op_name = '上一步:发起审签'
			exec_submit(wi,op_name)
		end
		process(:business_manager)
		@road.should == [:business_manager,:business_dept_head,:business_manager]
	end

	it "(风险部审核:项目审查岗)返回到上一步" do
		process(:business_manager)
		process(:business_dept_head)
		process(:risk_dept_examiner) do |wi|
			op_name = "上一步:业务部负责人审核"
			exec_submit(wi,op_name)
		end
		process(:business_dept_head,false)

		@road.should == [:business_manager,:business_dept_head,:risk_dept_examiner,:business_dept_head]
	end

	it "完美路线" do
		process(:business_manager) do |wi|
			merge_submit(wi).keys.should == ['下一步:业务部负责人审核']
			op_name = '下一步:业务部负责人审核'
			exec_submit(wi,op_name)
		end
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner)

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer)

		#risk_dept_head :tag => "风险部负责人审核"
		process(:risk_dept_head) do |wi|
			op_name = "下一步:业务核算岗审核"
			exec_submit(wi,op_name)
		end

		#accounting_dept_accounting_post :tag => "业务核算岗审核"
		process(:accounting_dept_accounting_post)

		#accounting_dept_head "计财部负责人审核"
		process(:accounting_dept_head)

		#business_manager :tag => "业务经理检查会办结果"
		process(:business_manager)

		#business_dept_head  :tag => "业务部负责人检查会办结果"
		process(:business_dept_head)

		#风险管理部负责人检查会办结果
		process(:risk_dept_head) 

		#vp :tag => "分管副总裁审批"
		process(:vp)

		#president :tag => "总裁审批"
		process(:president) do |wi|
			op_name = '终审否决'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '0'
		end

		#contract_management_post :tag => "合同管理岗打印合同"
		process(:contract_management_post) 

		@road.last.should == :contract_management_post
	end

	it "风险部负责人审核返回到头" do
		process(:business_manager)
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner)

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer)

		#risk_dept_head :tag => "风险部负责人审核"
		process(:risk_dept_head) do |wi|
			op_name = '退回:发起人'
			exec_submit(wi,op_name)
		end

		process(:business_manager)
		@road.last.should == :business_manager
	end

	it "<计财部负责人审核>跳到<项目审查>" do 
		process(:business_manager)
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner)

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer)

		#risk_dept_head :tag => "风险部负责人审核"
		process(:risk_dept_head) 
		process(:accounting_dept_accounting_post)

		#accounting_dept_head "计财部负责人审核"
		process(:accounting_dept_head) do |wi|
			op_name = '退回:项目审查'
			exec_submit(wi,op_name)
		end
		process(:risk_dept_examiner)
		@road.last.should == :risk_dept_examiner
	end

	it '总裁退回给副总裁' do
		process(:business_manager)
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner)

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer)

		#risk_dept_head :tag => "风险部负责人审核"
		process(:risk_dept_head)

		#accounting_dept_accounting_post :tag => "业务核算岗审核"
		process(:accounting_dept_accounting_post)

		#accounting_dept_head "计财部负责人审核"
		process(:accounting_dept_head)

		#business_manager :tag => "业务经理检查会办结果"
		process(:business_manager)

		#business_dept_head  :tag => "业务部负责人检查会办结果"
		process(:business_dept_head)

		#风险管理部负责人检查会办结果
		process(:risk_dept_head) 

		#vp :tag => "分管副总裁审批"
		process(:vp)

		#president :tag => "总裁审批"
		process(:president) do |wi|
			op_name = '上一步:分管副总裁审批'
			exec_submit(wi,op_name)
		end

		process(:vp)
		@workitem.fields['params']['tag'].should == 'step12'
		@road.last.should == :vp
	end

	it "风险部负责人终审通过" do
		process(:business_manager)
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner) do |wi|
			op_name = "下一步:法务复核(风险部负责人终审)" 
			exec_submit(wi,op_name)
		end

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer)

		#risk_dept_head :tag => "风险部负责人审核"
		process(:risk_dept_head)

		#accounting_dept_accounting_post :tag => "业务核算岗审核"
		process(:accounting_dept_accounting_post)

		#accounting_dept_head "计财部负责人审核"
		process(:accounting_dept_head)

		#business_manager :tag => "业务经理检查会办结果"
		process(:business_manager)

		#business_dept_head  :tag => "业务部负责人检查会办结果"
		process(:business_dept_head)

		#风险管理部负责人检查会办结果
		process(:risk_dept_head) do |wi|
      merge_submit(wi).should == { 
				"上一步:业务部负责人检查会办结果" => "jump to step10",
				"终审通过" => {'command' => 'jump to step14','ok' => '1'},
				"终审否决" => {'command' => 'jump to step14', 'ok' => '0'}
			}

			op_name = "终审通过"
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '1'
		end
	end

	it "总裁终审通过" do
		process(:business_manager)
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner) do |wi|
			op_name = "下一步:法务复核(总裁终审)" 
			exec_submit(wi,op_name)
		end

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer)

		#risk_dept_head :tag => "风险部负责人审核"
		process(:risk_dept_head)

		#accounting_dept_accounting_post :tag => "业务核算岗审核"
		process(:accounting_dept_accounting_post)

		#accounting_dept_head "计财部负责人审核"
		process(:accounting_dept_head)

		#business_manager :tag => "业务经理检查会办结果"
		process(:business_manager)

		#business_dept_head  :tag => "业务部负责人检查会办结果"
		process(:business_dept_head)

		#风险管理部负责人检查会办结果
		process(:risk_dept_head) do |wi|
      merge_submit(wi).should == { 
			"上一步:业务部负责人检查会办结果" => "jump to step10",
			"下一步:分管副总裁审批" => nil}

			op_name = "下一步:分管副总裁审批"
			exec_submit(wi,op_name)
		end

		process(:vp)

		process(:president) do |wi|
			op_name = '终审通过'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '1'
		end
	end

end
