#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
require 'ruote'   
require 'pp'

def process(parti_name,proceed=true)
	@engine.wait_for(parti_name)
	@storage_p = @engine.storage_participant
	@workitems = @storage_p.by_participant(parti_name.to_s)
	@workitem = @workitems.first

	yield @workitem if block_given?
	
	@storage_p.proceed(@workitem) if proceed

	@road << parti_name
end

def find_op(op,array,d='=>')
	str = array.find{|e| e.include?(op)}
	raise 'invalid workflow operation' if !str
	b = str.split(d)
	return b[1].strip if b[1]
end

describe 'test find_op' do
	specify do
		submit = ["上一步:项目审查 => jump to step3","下一步:法务复核"]
		op = "上一步:项目审查"
		find_op(op,submit).should == 'jump to step3'
	end

	specify do
		submit = ["上一步:法务复核 => jump to step5","下一步:业务核算岗审核","退回:发起人 =>=> rewind"]
		op = "退回:发起人"
		find_op(op,submit,'=>=>').should == 'rewind'
	end

	specify do
		submit = ["上一步:法务复核 => jump to step5","下一步:业务核算岗审核","退回:发起人 =>=> rewind"]
		op = "退回:发起人 abc"
		expect {
			find_op(op,submit,'=>=>')
		}.to raise_exception(RuntimeError,'invalid workflow operation')
	end

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
=begin
	it "@engine.storage_participant.by_participant(user.login) return a array" do
		@engine.storage_participant.by_participant('aaaa').should == [] 
	end
=end
	it "从<业务部负责人审核>返回上一步" do
		process(:business_manager)
		process(:business_dept_head) do |wi| 
		  op = '上一步:发起审签'
			array = wi.fields['params']['submit']
			command = find_op(op,array)
			wi.command = command if command 
		end
		process(:business_manager)
		@road.should == [:business_manager,:business_dept_head,:business_manager]
	end

	it "(风险部审核:项目审查岗)返回到上一步" do
		process(:business_manager)
		process(:business_dept_head)
		#		process(:risk_dept_examiner) do |wi|
		#			wi.command = 'jump to step2'
		#		end
		process(:risk_dept_examiner) do |wi|
			op = "上一步:业务部负责人审核"
			array = wi.fields['params']['submit']
			command = find_op(op,array)
			wi.command = command if command 
		end
		process(:business_dept_head,false)

		@road.should == [:business_manager,:business_dept_head,:risk_dept_examiner,:business_dept_head]
	end
	it "完美路线" do
		process(:business_manager)
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner)

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer)

		#risk_dept_head :tag => "风险部负责人审核"
		process(:risk_dept_head){|wi| wi.fields['go'] = 'next_step'} 

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
		process(:president)

		#contract_management_post :tag => "合同管理岗打印合同"
		process(:contract_management_post) 

		process(:completer)

		@road.last.should == :completer
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
			op = '退回:发起人'
			array = wi.fields['params']['submit']
			dest = find_op(op,array,'=>=>')
			wi.fields['go'] = dest if dest
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
			op = '退回:项目审查'
			array = wi.fields['params']['submit']
			dest = find_op(op,array,'=>=>')
			wi.fields['go'] = dest if dest
		end
		process(:risk_dept_examiner)
		@road.last.should == :risk_dept_examiner
	end
end
