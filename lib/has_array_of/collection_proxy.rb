class HasArrayOf::CollectionProxy
  extend Forwardable

  def initialize(owner, model, ids_attr, scope: model.all)
    @owner = owner
    @model = model
    @foreign_key = model.primary_key
    @ids_attr = ids_attr
    @scope = scope
    @unscoped = model.unscoped
  end

  def ids
    @owner[@ids_attr]
  end

  def ids=(new_ids)
    @owner[@ids_attr] = new_ids
  end

  def load
    _relation.load
    self
  end

  def records
    _relation.load
    records = _relation.instance_variable_get(:@records)
    unless @records.equal? records
      @records = records.index_by { |obj| foreign_key_for(obj) }.values_at(*ids)
      @records.compact!
    end
    @records
  end

  def where(*args)
    self.class.new(@owner, @model, @ids_attr, scope: @scope.where(*args))
  end

  def where!(*args)
    @scope.where!(*args)
    @relation = nil
    self
  end

  def to_ary
    records.dup
  end
  alias to_a to_ary

  def each(&block)
    records.each(&block)
  end

  include Enumerable

  def pluck(*column_names)
    raise NotImplementedError
  end

  def ==(other)
    to_a == other
  end

  def touch_ids
    @relation = nil
  end

  def <<(object)
    ids << foreign_key_for(object)
    touch_ids
    self
  end

  def []=(*index, val)
    if val.is_a? Array
      ids[*index] = val.map { |obj| foreign_key_for(obj) }
    else
      ids[*index] = foreign_key_for(val)
    end
    touch_ids
    val
  end

  def collect!
    if block_given
      map!(Proc.new)
    else
      to_enum(:collect!)
    end
  end

  def compact!
    ids.compact!
    touch_ids
    self
  end

  def concat(other)
    ids.concat(other.map { |obj| foreign_key_for(obj) })
    touch_ids
    self
  end

  def delete(object)
    # TODO: optimize
    id = ids.delete(foreign_key_for(object))
    touch_ids
    if id
      @model.find(id)
    end
  end

  def delete_at(index)
    # TODO: optimize
    id = ids.delete_at(index)
    touch_ids
    if id
      @model.find(id)
    end
  end

  def delete_if
    if block_given?
      hash = ids_to_objects_hash
      ids.delete_if { |id| yield hash[id] }
      touch_ids
      self
    else
      to_enum(:delete_if)
    end
  end

  def fill(*args)
    if block_given?
      ids.fill(*args) do |index|
        foreign_key_for(yield index)
      end
    else
      obj = args.shift
      ids.fill(foreign_key_for(obj), *args)
    end
    touch_ids
    self
  end

  def insert(index, *objects)
    ids.insert(index, *objects.map { |obj| foreign_key_for(obj) })
    touch_ids
    self
  end

  def keep_if
    if block_given?
      hash = ids_to_objects_hash
      ids.keep_if { |id| yield hash[id] }
      touch_ids
      self
    else
      to_enum(:keep_if)
    end
  end

  def map!
    if block_given?
      to_a.each_with_index do |object, index|
        ids[index] = foreign_key_for(yield object)
      end.tap { touch_ids }
    else
      to_enum :map!
    end
  end

  def pop
    # TODO: optimize
    @model.find(ids.pop).tap { touch_ids }
  end

  def push(*objects)
    ids.push(*objects.map{ |obj| foreign_key_for(obj) })
    touch_ids
    self
  end

  def reject!
    if block_given?
      hash = ids_to_objects_hash
      if ids.reject! { |id| yield hash[id] }
        self
      end.tap { touch_ids }
    else
      to_enum(:reject!)
    end
  end

  def replace(other_ary)
    ids.replace other_ary.map{ |obj| foreign_key_for(obj) }
    touch_ids
    self
  end

  def reverse!
    ids.reverse!
    touch_ids
    self
  end

  def rotate!(count=1)
    ids.rotate! count
    touch_ids
    self
  end

  def select!
    if block_given?
      hash = ids_to_objects_hash
      if ids.select! { |id| yield hash[id] }
        self
      end.tap { touch_ids }
    else
      to_enum(:select!)
    end
  end

  def shift
    # TODO: optimize
    @model.find(ids.shift).tap { touch_ids }
  end

  def shuffle!(args={})
    ids.shuffle!(args)
    touch_ids
    self
  end

  def uniq!
    if block_given?
      hash = ids_to_objects_hash
      ids.uniq! do |id|
        yield hash[id]
      end
    else
      ids.uniq!
    end
    touch_ids
    self
  end

  def unshift(*args)
    ids.unshift(*args.map{ |obj| foreign_key_for(obj) })
    touch_ids
    self
  end

  private

  def foreign_key_for(obj)
    obj[@foreign_key] if obj
  end

  def ids_to_objects_hash
    index_by{ |obj| foreign_key_for(obj) }
  end

  def _relation
    @relation ||= @scope.merge(@unscoped.where @foreign_key => ids.compact)
  end

  def_delegators :records, :each
  def_delegators :_relation, :loaded?, :to_sql
  def_delegators :ids, :size, :length
end
