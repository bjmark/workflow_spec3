#encoding:utf-8
#
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)
require 'bundler/setup' #if File.exists?(ENV['BUNDLE_GEMFILE'])

require 'yajl' 
require 'ruote'   
require './workflow_helper'

class Request
  attr_accessor :params
end

class CompeleterParticipant
  include Ruote::LocalParticipant

  def on_workitem(wi)
    $road << 'completer'
    $debug << wi.fields['decision']
    reply
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

describe '营销报备' do
  before(:each) do 
    storage = Ruote::HashStorage.new() 
    worker = Ruote::Worker.new(storage) 
    @engine = Ruote::Dashboard.new(worker, true) 

    @engine.register do
      participant 'completer', CompeleterParticipant
      participant 'no_op', Ruote::NoOpParticipant
      catchall Ruote::StorageParticipant
    end

    workflow_def = File.open('workflow_marketing_record.rb') {|f| f.read} 
    @wfid = @engine.launch(workflow_def)
    $road = []
    $debug = []
  end

  after(:each) do
    @engine.shutdown
  end

  specify '完美路线' do
    process(:business_manager) 
    process(:business_dept_head)

    $road.should == [
      'business_manager', 'business_dept_head',
    ]
  end
end
