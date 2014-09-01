#encoding:utf-8
require './workflow_helper'
require './workflow_credit_approval_helper'
require './workitem'


describe 'workflow_credit_approval_helper' do
  specify 'custom_fields_for_business_manager' do
    wi = Workitem.new
    wi.fields = {'more_info_from_committee_secretary' => 'yes'}
    helper = WorkflowCreditApprovalHelper.new(wi)
    helper.send('custom_fields_for_business_manager')
    helper.custom_fields.should == { '发送给评审委员会委员' => { :type => 'checkbox', :name => 'back_to_committee_secretary' } }
  end
end
