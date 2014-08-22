#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yajl' 
require 'redis' # gem install redis
require 'ruote'   
require 'ruote-redis' # gem install ruote-redis
require 'pp'
require './workflow_share'

class Project
	include WorkflowRight 
	@@hhash = {}

	def self.find(id)
		Project.new
	end

	def hhash
		@@hhash
	end
end

class User
	def roles
		[
			Role.new('risk_dept_legal_examiner'),
			Role.new('accounting_dept_accounting_post'),
		]
	end
end

# final_right colud be 
# step11,
# step12,
# step13

def set_final_right(workitem,final_right)
	workitem.fields.delete(workitem.fields['final_right'])
	workitem.fields['final_right'] = final_right

	workitem.fields[final_right] = {
		"终审通过" => {'command' => 'jump to finish','ok' => '1'},
		"终审否决" => {'command' => 'jump to finish','ok' => '0'}
	}

	case final_right
	when 'step11'
		workitem.fields[final_right]["下一步:分管副总裁"] = 'del'
	end
end

def workflow1_step5_edit(workitem,final_right)
	workflow1_step5_update(workitem,final_right)
end

def workflow1_step6_edit(workitem,final_right=nil)
	workflow1_step6_update(workitem,final_right)
end

def workflow1_step5_update(workitem,final_right)
	set_final_right(workitem,final_right)
	return workitem
end

def workflow1_step6_update(workitem,final_right)
	set_final_right(workitem,final_right)
	return workitem
end


describe '合同审签' do
	before(:each) do 
		@storage = Ruote::HashStorage.new() 
		@worker = Ruote::Worker.new(@storage) 
		@engine = Ruote::Dashboard.new(@worker) 

		@engine.register do
			participant 'no_op', Ruote::NoOpParticipant
			participant 'right_setter', Workflow1RightSetterParticipant
			catchall Ruote::StorageParticipant
		end

		workflow_t = File.open('workflow_1.rb') {|f| f.read} 
		@wfid = @engine.launch(workflow_t,
			'target' => {'type' => 'project','id' => 1}
		)

		@road = []
	end

	after(:each) do
		@engine.shutdown
	end
=begin
	it "从<业务部负责人审核>返回上一步" do
		process(:business_manager)
		process(:business_dept_head) do |wi| 
			op_name = '上一步:发起审签'
			exec_submit(wi,op_name)
		end

		process(:business_manager) do |wi|
			op_name = '终审通过'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '1'
		end

		#@road.should == [:business_manager,:business_dept_head,:business_manager]
	end
=end
	it "(风险部审核:项目审查岗)返回到上一步" do
		process(:business_manager)
		process(:business_dept_head)
		process(:risk_dept_examiner) do |wi|
			op_name = "上一步:业务部负责人"
			exec_submit(wi,op_name)
			wi.target.instance_of?(Project).should == true
		end
		process(:business_dept_head,false)

		@road.should == [:business_manager,:business_dept_head,
			:risk_dept_examiner,:business_dept_head]
	end
	
  it "完美路线-终审通过" do
		process(:business_manager) do |wi|
			op_name = '下一步:业务部负责人'
			exec_submit(wi,op_name)
		end
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner) do |wi|
			p = Project.find(1)
			u = User.new
			op = 'edit_overdue_day_rate'

			p.has_right?(op,u).should be_true

			on_leave = wi.fields['params']['on_leave']
			on_leave.each do |fun,var|
				case fun
				when 'del_right'
					p.del_right(var)
				end
			end
			p.has_right?(op,u).should == false
		end

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer) do |wi|
			action = wi.fields['params']['action']
			action.should == 'workflow1_step5'
			send("#{action}_edit",wi,'step_president') 
		end

		#risk_dept_head :tag => "风险部负责人审核"
		process(:risk_dept_head) do |wi|
			op_name = "下一步:业务核算岗"
			exec_submit(wi,op_name)
		end

		#accounting_dept_accounting_post :tag => "业务核算岗审核"
		process(:accounting_dept_accounting_post) do |wi|
			u = User.new
			wi.target.has_right?('edit_rate_adjustment_type',u).should be_true

			on_leave = wi.fields['params']['on_leave']
			on_leave.each do |fun,var|
				case fun
				when 'del_right'
					wi.target.del_right(var)
				end
			end
			wi.target.has_right?('edit_rate_adjustment_type',u).should == false
		end

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
			merge_submit(wi).should == {
				"上一步:分管副总裁" => "jump to step_vp",
				"终审通过" => {'command' => 'jump to finish','ok' => '1'},
				"终审否决" => {'command' => 'jump to finish','ok' => '0'}
			}

			op_name = '终审通过'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '1'
		end

		#contract_management_post :tag => "合同管理岗打印合同"
		#process(:contract_management_post) 

		@road.last.should == :completer
	end

	it "完美路线-终审否决" do
		process(:business_manager) do |wi|
			op_name = '下一步:业务部负责人'
			exec_submit(wi,op_name)
		end
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner)

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer) do |wi|
			action = wi.fields['params']['action']
			action.should == 'workflow1_step5'
			send("#{action}_edit",wi,'step_president') 
		end

		#risk_dept_head :tag => "风险部负责人审核"
		process(:risk_dept_head) do |wi|
			op_name = "下一步:业务核算岗"
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
			merge_submit(wi).should == {
				"上一步:分管副总裁" => "jump to step_vp",
				"终审通过" => {'command' => 'jump to finish','ok' => '1'},
				"终审否决" => {'command' => 'jump to finish','ok' => '0'}
			}

			op_name = '终审否决'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '0'
		end

		@engine.wait_for(@wfid)
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
			op_name = '退回:发起人'
			exec_submit(wi,op_name)
		end

		process(:business_manager)
		@road.last.should == :business_manager
	end

	it "<计财部负责人审核>跳到<发务审核>" do 
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
			op_name = '退回:法务审核岗'
			exec_submit(wi,op_name)
		end
		process(:risk_dept_legal_examiner)
		@road.last.should == :risk_dept_legal_examiner
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
			op_name = '上一步:分管副总裁'
			exec_submit(wi,op_name)
		end

		process(:vp)
		@workitem.fields['params']['tag'].should == 'step_vp'
		@road.last.should == :vp
	end

	it "风险部负责人终审通过" do
		process(:business_manager)
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner) 

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer) do |wi|
			action = wi.fields['params']['action']
			action.should == 'workflow1_step5'
			send("#{action}_edit",wi,'step_vp') 
		end

		#risk_dept_head :tag => "风险部负责人审核"
		process(:risk_dept_head) do |wi|
			wi.fields['final_right'].should == 'step_vp'
			wi.fields['step_vp'].should == {
				"终审通过" => {'command' => 'jump to finish','ok' => '1'},
				"终审否决" => {'command' => 'jump to finish','ok' => '0'}
			}

			action = wi.fields['params']['action']
			action.should == 'workflow1_step6'
			send("#{action}_edit",wi,'step11')
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
		process(:risk_dept_head) do |wi|
			merge_submit(wi).should == { 
				"上一步:业务部负责人检查会办结果" => "jump to step10",
				"终审通过" => {'command' => 'jump to finish','ok' => '1'},
				"终审否决" => {'command' => 'jump to finish', 'ok' => '0'}
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
		process(:risk_dept_legal_examiner) 

		#risk_dept_legal_reviewer :tag => "法务复核"
		process(:risk_dept_legal_reviewer) do |wi|
			action = wi.fields['params']['action']
			action.should == 'workflow1_step5'
			send("#{action}_edit",wi,'step_vp') 
		end

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
				"下一步:分管副总裁" => nil}

				op_name = "下一步:分管副总裁"
				exec_submit(wi,op_name)
		end

		process(:vp) do |wi|
			op_name = '下一步:总裁'
			exec_submit(wi,op_name)
		end

		process(:president) do |wi|
			op_name = '终审通过'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '1'
		end
	end

	it '业务经理取消流程' do
		process(:business_manager) do |wi|
			op_name = '取消流程'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '2'
		end

		@engine.wait_for(@wfid)
	end

	it '业务经理取消流程2' do
		process(:business_manager) 
		process(:business_dept_head) do |wi|
			op_name = '上一步:发起审签'
			exec_submit(wi,op_name)
		end

		process(:business_manager) do |wi|
			op_name = '取消流程'
			exec_submit(wi,op_name)
		end

		process(:completer) do |wi|
			wi.fields['ok'].should == '2'
		end
	end

	it '<法务审核>退回<发起审签>' do
		process(:business_manager)
		process(:business_dept_head)
		process(:risk_dept_examiner)

		#risk_dept_legal_examiner :tag => "法务审核"
		process(:risk_dept_legal_examiner) do |wi|
			op_name = '退回:发起审签'
			exec_submit(wi,op_name)
		end

		process(:business_manager)
		@road.last.should == :business_manager
	end
end
