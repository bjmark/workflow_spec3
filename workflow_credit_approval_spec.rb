#encoding:utf-8
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yajl' 
#require 'redis' # gem install redis
require 'ruote'   
#require 'ruote-redis' # gem install ruote-redis
require 'pp'

class CompeleterParticipant
  include Ruote::LocalParticipant

  def on_workitem
    $road << 'completer'
    reply
  end
end

class WorkflowHelper2
  attr_reader :engine, :workitem

  def initialize(engine, workitem)
    @engine = engine
    @workitem = workitem
  end

  def prev_tag
    p = @engine.process(@workitem.wfid)
    cur_tag = @workitem.params['tag']
    
    past_tags = p.past_tags.collect{|e| e[0] }
    return nil if past_tags.empty?
    
    unless (past_tags.find{|e| e == cur_tag })
      return past_tags.last
    end
    
    s = nil
    past_tags.find do |e|
      if e == cur_tag
        true
      else
        s = e
        false
      end
    end

    s
  end

  def prev_participant
    _pre_tag = prev_tag
    return nil unless _pre_tag

    p = @engine.process(@workitem.wfid)
    r = p.past_tags.find{|e| e[0] == _pre_tag}
    prev_fei_str = r[1]
    prev_fei = Ruote::FlowExpressionId.from_id(prev_fei_str)
    expid = prev_fei.expid

    # use radial notation to get the previous participant
    exp = Ruote::Reader.to_raw_expid_radial(p.current_tree).find do |e|
      e[1] == expid
    end

    exp[2]
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

    workflow_def = File.open('workflow_credit_approval.rb') {|f| f.read} 
    @wfid = @engine.launch(workflow_def)
    $road = []
  end

  after(:each) do
    @engine.shutdown
  end
  
  specify '完美路线' do
    process(:business_manager) do |wi|
      w = WorkflowHelper2.new(@engine, wi)
      w.prev_tag.should be_nil
      w.prev_participant.should be_nil
    end
    process(:business_dept_head) do |wi|
      w = WorkflowHelper2.new(@engine, wi)
      w.prev_tag.should == 'INIT.handler'
      w.prev_participant.should == 'business_manager'
    end
    process(:risk_dept_reviewer) do |wi|
      w = WorkflowHelper2.new(@engine, wi)
      w.prev_tag.should == 'INIT.head_review'
    end
    process(:risk_dept_examiner)
    process(:risk_dept_reviewer) do |wi|
      w = WorkflowHelper2.new(@engine, wi)
      w.prev_tag.should == 'INIT.risk_exam'
    end
    process(:risk_dept_head)

    p =@engine.process(@wfid)
    p.past_tags.each do |e|
      puts e.inspect

      prev_fei_str = e[1]
      prev_fei = Ruote::FlowExpressionId.from_id(prev_fei_str)
      expid = prev_fei.expid

      # use radial notation to get the previous participant
      exp = Ruote::Reader.to_raw_expid_radial(p.current_tree).find do |e|
        e[1] == expid
      end

      puts exp[2]
    end
    
    $road.should == [
      'business_manager', 'business_dept_head',
      'risk_dept_reviewer','risk_dept_examiner',
      'risk_dept_reviewer', 'risk_dept_head',
=begin      
       'business_manager', 'business_dept_head',
      'risk_dept_reviewer', 'risk_dept_examiner', 'risk_dept_reviewer', 'risk_dept_head',
      'committee_secretary', 'risk_dept_reviewer', 'risk_dept_head', 'committee_director',
      'president','completer', 'risk_dept_examiner', 'risk_dept_head'
=end
    ]
  end
 end
