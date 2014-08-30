#encoding:utf-8

class Workitem
  attr_accessor :params, :fields

  def [](a)
    fields[a]
  end
end

