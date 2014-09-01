#encoding:utf-8
require './workflow_helper'
require './workitem'

class WorkflowTestHelper < WorkflowHelper
  attr_accessor :funs

  def validate1
    %w(e1 e2)
  end

  def method_missing(name, *arg)
    @funs ||= []
    @funs << name.to_s
  end
end

describe 'workflow_helper' do
  specify 'before_edit' do
    wi = Workitem.new
    wi.params = { 'before_edit' => 'fun1,fun2' }
    
    t = WorkflowTestHelper.new(wi)
    t.before_edit
    t.funs.should == %w(fun1 fun2)
  end

  specify 'fun_filter' do
    wi = Workitem.new
    t = WorkflowTestHelper.new(wi)
    t.fun_filter('fun1,fun2').should == %w(fun1 fun2)
  end
  
  specify 'fun_filter2' do
    wi = Workitem.new
    wi.fields = {'key' => 'yes'}
    wi['key'].should == 'yes'

    t = WorkflowTestHelper.new(wi)
    t.fun_filter('fun1,fun2 if key').should == %w(fun1 fun2)
    t.fun_filter('fun1,fun2 if !key').should == []
    t.fun_filter('fun1,fun2 if key == yes').should == %w(fun1 fun2)
    t.fun_filter('fun1,fun2 if key == no').should == []
  end

  specify 'before_proceed' do
    wi = Workitem.new
    wi.params = { 'before_proceed' => { 'proceed' => 'fun1,fun2' } }

    t = WorkflowTestHelper.new(wi)
    t.before_proceed('proceed')
    t.funs.should == %w(fun1 fun2)
  end

  specify 'before_proceed_2' do
    wi = Workitem.new
    wi.params = { 'before_proceed' => { 'return' => 'fun1,fun2 if more_info' } }
    wi.fields = { 'more_info' => 'yes' }
    wi['more_info'].should == 'yes'

    t = WorkflowTestHelper.new(wi)
    t.before_proceed('return')
    t.funs.should == %w(fun1 fun2)
  end

  specify 'before_proceed_3' do
    wi = Workitem.new
    wi.params = { 'before_proceed' => { 'return' => 'fun1,fun2 if !more_info' } }
    wi.fields = { 'more_info' => 'yes' }
    wi['more_info'].should == 'yes'
    
    (!wi['more_info']).should be_false
    
    t = WorkflowTestHelper.new(wi)
    t.before_proceed('return')

    t.funs.should == nil
  end

  specify 'before_proceed_4' do
    wi = Workitem.new
    wi.params = { 'before_proceed' => 
      { 
        'return' => 'fun1,fun2 if !more_info',
        'all' => 'fun3,fun4'
      } 
    }
    wi.fields = { 'more_info' => 'yes' }
    wi['more_info'].should == 'yes'
    
    (!wi['more_info']).should be_false
    
    t = WorkflowTestHelper.new(wi)
    t.before_proceed('return')

    t.funs.should == %w(fun3 fun4)
  end

  specify 'validate' do
    wi = Workitem.new
    wi.params = { 'validate' => 
      { 
        'proceed' => 'validate1 if more_info == yes',
      } 
    }
    wi.fields = { 'more_info' => 'yes' }
    wi['more_info'].should == 'yes'
    
    
    t = WorkflowTestHelper.new(wi)
    t.validate('proceed').should == %w(e1 e2)
  end
end
