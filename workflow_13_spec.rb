#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yajl' 
#require 'redis' # gem install redis
require 'ruote'   
#require 'ruote-redis' # gem install ruote-redis
require 'pp'
require './workflow_helper'
require './workflow_credit_helper'

class Request
  attr_accessor :params
end

class CompeleterParticipant
  include Ruote::LocalParticipant

  def on_workitem
    $road << 'completer'
    reply
  end
end

def build_helper(wi, req = nil, current_user = nil)
  class_name = wi.fields['blade']['helper']
  if class_name
    helper = Object.const_get(class_name).new(wi, req, current_user)
  else
    helper = WorkflowHelper.new(wi, req, current_user)  
  end
end

def process(parti_name,proceed=true)
  @engine.wait_for(parti_name)

  p = @engine.storage_participant 

  workitem = p.by_participant(parti_name.to_s).first
  yield workitem if block_given?

  p.proceed(workitem) if proceed

  $road << workitem.participant_name
end

describe '授信审批' do
  before(:each) do 
    storage = Ruote::HashStorage.new() 
    worker = Ruote::Worker.new(storage) 
    @engine = Ruote::Dashboard.new(worker, true) 

    @engine.register do
      participant 'completer', CompeleterParticipant
      participant 'last_step', Ruote::NoOpParticipant
      catchall Ruote::StorageParticipant
    end

    workflow_def = File.open('workflow_13.rb') {|f| f.read} 
    @wfid = @engine.launch(workflow_def)
    $road = []
  end

  after(:each) do
    @engine.shutdown
  end
  
  it "业务部负责人退回业务经理" do
    process(:business_manager) 		
    process(:business_dept_head) do |wi|
      wi.participant_name.should == 'business_dept_head'
      wi.wf_name.should == '授信审批'
      wi.wf_revision.should == '2.0.0'

      wi.fields['blade']['helper'].should == 'WorkflowCreditHelper'

      op_name = "上一步:业务部业务经理"

      helper = build_helper(wi)
      helper.before_proceed(op_name)
      helper.exec_submit(op_name)
    end
    process(:business_manager) 		

    $road.should == ['business_manager', 'business_dept_head', 'business_manager']
  end

  specify '完美路线' do
    process(:business_manager)
    process(:business_dept_head)

    process(:risk_dept_reviewer)
    process(:risk_dept_examiner)
    process(:risk_dept_reviewer)
    process(:risk_dept_head)

    process(:business_manager) 		
    process(:business_dept_head)

    process(:risk_dept_reviewer)
    process(:risk_dept_examiner)
    process(:risk_dept_reviewer)
    process(:risk_dept_head)

    process(:committee_secretary)
    process(:risk_dept_reviewer)
    process(:risk_dept_head)
    process(:committee_director)
    process(:president)
    process(:risk_dept_examiner)
    process(:risk_dept_head) do |wi|
      op_name = "结束"
      helper = build_helper(wi)
      helper.exec_submit(op_name)
    end
    @engine.wait_for(@wfid)

    $road.should == [
      'business_manager', 'business_dept_head', 'risk_dept_reviewer','risk_dept_examiner',
      'risk_dept_reviewer', 'risk_dept_head', 'business_manager', 'business_dept_head',
      'risk_dept_reviewer', 'risk_dept_examiner', 'risk_dept_reviewer', 'risk_dept_head',
      'committee_secretary', 'risk_dept_reviewer', 'risk_dept_head', 'committee_director',
      'president','completer', 'risk_dept_examiner', 'risk_dept_head'
    ]
  end

  specify '完美路线2' do
    process(:business_manager) 		
    process(:business_dept_head)

    #派发
    process(:risk_dept_reviewer)
    #审查
    process(:risk_dept_examiner)
    #复审
    process(:risk_dept_reviewer)
    #负责人审批
    process(:risk_dept_head)

    #尽职调查
    process(:business_manager) 		
    process(:business_dept_head)

    process(:risk_dept_reviewer)
    process(:risk_dept_examiner)
    process(:risk_dept_reviewer)
    process(:risk_dept_head)

    #评审意见汇总
    process(:committee_secretary)
    process(:risk_dept_reviewer)
    process(:risk_dept_head)
    process(:committee_director)
    process(:president)
    process(:risk_dept_examiner)
    process(:risk_dept_head)
    @engine.wait_for(@wfid)

    $road.should == [
      'business_manager', 'business_dept_head', 'risk_dept_reviewer','risk_dept_examiner',
      'risk_dept_reviewer', 'risk_dept_head', 'business_manager', 'business_dept_head',
      'risk_dept_reviewer', 'risk_dept_examiner', 'risk_dept_reviewer', 'risk_dept_head',
      'committee_secretary', 'risk_dept_reviewer', 'risk_dept_head', 'committee_director',
      'president','completer', 'risk_dept_examiner', 'risk_dept_head', 'completer'
    ]
  end

  specify 'go back1' do
    process(:business_manager) 		
    process(:business_dept_head)

    process(:risk_dept_reviewer) do |wi|
      op_name = "上一步:业务部负责人审批"
      helper = build_helper(wi)
      helper.exec_submit(op_name)
    end
    process(:business_dept_head)

    $road.last.should == 'business_dept_head'
  end

  specify '项目复核岗指定审查员' do
    process(:business_manager) 		
    process(:business_dept_head)

    process(:risk_dept_reviewer) do |wi|
      req = Request.new
      req.params = {'examiner_id' => 123}
      helper = build_helper(wi, req)
      helper.before_proceed('下一步:风险部项目审查岗审查')
    end

    process(:risk_dept_examiner) do |wi|
      wi.fields['blade']['default_examiner_id'].should == 123
      wi.fields['blade']['receiver_id'].should == 123

      req = Request.new
      req.instance_variable_set('@comments', '123')
      helper = build_helper(wi, req)
      helper.before_proceed('下一步:风险部项目复核岗复审')
      req.instance_variable_get('@comments').should == 'abc'
    end

    process(:risk_dept_reviewer) do |wi|
      wi.fields['blade']['default_examiner_id'].should == 123
      wi.fields['blade']['receiver_id'].should be_nil
      
      op_name = '上一步:风险部项目审查岗审查'
      helper = build_helper(wi)
      helper.before_proceed(op_name)
      helper.exec_submit(op_name)
    end

    process(:risk_dept_examiner) do |wi|
      wi.fields['blade']['default_examiner_id'].should == 123
      wi.fields['blade']['receiver_id'].should == 123
    end
  end

  specify 'validate_examiner' do
    process(:business_manager) 		
    process(:business_dept_head)

    process(:risk_dept_reviewer) do |wi|
      req = Request.new
      req.params = {'examiner_id' => ''} #没有指定审查人
      helper = build_helper(wi, req)
      helper.validate('下一步:风险部项目审查岗审查').size.should == 1
    end
  end

  specify 'validate_suggest' do
    process(:business_manager) 		
    process(:business_dept_head)

    process(:risk_dept_reviewer) do |wi|
      req = Request.new
      req.params = {'examiner_id' => ''} #没有指定审查人
      helper = build_helper(wi, req)
      helper.validate('下一步:风险部项目审查岗审查').size.should == 1
    end
  end

  specify 'set view to view13_2' do
    process(:business_manager) 		
    process(:business_dept_head)

    #派发
    process(:risk_dept_reviewer)
    #审查
    process(:risk_dept_examiner)
    #复审
    process(:risk_dept_reviewer)
    #负责人审批
    process(:risk_dept_head) do |wi|
      helper = build_helper(wi)
      helper.exec_submit('下一步:业务部业务经理尽职调查')
    end
    
    #尽职调查
    process(:business_manager) do |wi|
      wi.fields['blade']['view'].should == 'view13_2'
    end
  end

  specify '评审委员会秘书评审意见汇总,退回业务经理补充材料初审及补充调查' do
    process(:business_manager) 		
    process(:business_dept_head)

    #派发
    process(:risk_dept_reviewer)
    #审查
    process(:risk_dept_examiner)
    #复审
    process(:risk_dept_reviewer)
    #负责人审批
    process(:risk_dept_head)

    #尽职调查
    process(:business_manager) 		
    process(:business_dept_head)

    process(:risk_dept_reviewer)
    process(:risk_dept_examiner)
    process(:risk_dept_reviewer)
    process(:risk_dept_head)

    #评审意见汇总
    process(:committee_secretary) do |wi|
      helper = build_helper(wi)
      helper.exec_submit('退回业务经理补充材料初审及补充调查')
    end

    process(:business_manager) do |wi|
      wi.params['tag'].should == 'business_manager2'
      wi.fields['blade']['business_manager2'].should == {'评审委员会秘书评审意见汇总' => 'jump to committee_secretary'}
    end
  end

  specify '选择终审人' do
    process(:business_manager) 		
    process(:business_dept_head)

    #派发
    process(:risk_dept_reviewer)
    #审查
    process(:risk_dept_examiner)
    #复审
    process(:risk_dept_reviewer)
    #负责人审批
    process(:risk_dept_head)

    #尽职调查
    process(:business_manager) 		
    process(:business_dept_head)

    process(:risk_dept_reviewer)
    process(:risk_dept_examiner) do |wi|
      req = Request.new
      req.params = {'final_decision_maker_role' => 'president'} #选择终审人
      
      op_name = '下一步:风险部项目复核岗复审'
      helper = build_helper(wi,req)
      helper.before_proceed(op_name)
      helper.exec_submit(op_name)
    end
    
    process(:risk_dept_reviewer) do |wi|
      wi['blade.final_decision_maker_role'].should == 'president'
      wi['blade.committee_director1'].should == { 
        "同意" => 'del',
        "否决" => 'del'
      }
      wi['blade.final_decision_maker_role_history'].should == ['1']
    end
  end
end
