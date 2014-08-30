#encoding:utf-8

class WorkflowHelper
  def initialize(workitem, req = nil, current_user = nil)
    @workitem = workitem
    @req = req
    @current_user = current_user
  end

  def form
    @workitem.params['form'] || 'form'
  end

  def view
    @workitem.params['view'] || @workitem.fields['blade']['view']
  end

  def before_edit
    return unless @workitem.params['before_edit']
    funs = @workitem.params['before_edit'].split(',').collect{|e| e.strip}
    funs.each{|m| self.send(m)}
  end

  #handle following conditions
  # 'before_proceed' => { 'proceed' => 'fun1,fun2' }
  # 'before_proceed' => { 'return' => 'fun1,fun2 if key' }
  # 'before_proceed' => { 'all' => fun1,fun2 if !key'}
  # 'before_proceed' => { 'proceed' => ['fun1,fun2 if !key', 'fun4','fun3']}
  def before_proceed(op_name)
    return unless (h = @workitem.params['before_proceed'])
    ([op_name, 'all'] & h.keys).each do |k|
      exp = [h[k]].flatten
      exp.each do |m| 
        statment, key = m.split('if')
        if key
          key = key.strip
          neg = false
          if key[0] == '!'
            neg = true
            key = key[1..-1]
          end
          if neg
            next if @workitem[key]
          else
            next if !@workitem[key]
          end
        end

        funs = statment.split(',').collect{|e| e.strip}
        funs.each{|f| self.send(f)}
      end
    end
  end


  def validate(op_name)
    error = []
    return error unless (h = @workitem.params['validate'])

    ([op_name] & h.keys).each do |k|
      exp = [h[k]].flatten
      exp.each do |m| 
        statment, key = m.split('if')
        if key
          key = key.strip
          neg = false
          if key[0] == '!'
            neg = true
            key = key[1..-1]
          end
          if neg
            next if @workitem[key]
          else
            next if !@workitem[key]
          end
        end

        funs = statment.split(',').collect{|e| e.strip}
        funs.each{|f| error << self.send(f)}
      end
    end

    error.flatten
  end


  def clear_receiver
    @workitem.fields['blade'].delete('receiver_id')
  end

  def custom_fields
    my_tag = @workitem.fields['params']['tag']
    hash = @workitem.fields['blade'][my_tag]

    wi_cf = Array(@workitem.fields['params']['custom_fields'])

    return wi_cf if !hash

    wi_cf + Array(hash['custom_fields'])
  end
end

