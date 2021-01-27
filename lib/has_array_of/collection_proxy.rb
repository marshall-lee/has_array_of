class HasArrayOf::CollectionProxy
  extend Forwardable

  def initialize(owner, model, ids_attr, scope: model.all)
    @owner = owner
    @model = model
    @foreign_key = model.primary_key
    @ids_attr = ids_attr
    @scope = scope
    @unscoped = model.unscoped
    build_query!
  end

  def ids
    @owner[@ids_attr]
  end

  def ids=(new_ids)
    @owner[@ids_attr] = new_ids
  end

  def load
    @relation.load
    self
  end

  def records
    @relation.load
    records = @relation.instance_variable_get(:@records)
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
    build_query!
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

  def mutate_ids
    @relation.reset
    ret = yield
    self.ids = ids
    build_query!
    ret
  end

  def <<(object)
    mutate_ids do
      ids << foreign_key_for(object)
      self
    end
  end

  def []=(*index, val)
    mutate_ids do
      if val.is_a? Array
        ids[*index] = val.map { |obj| foreign_key_for(obj) }
      else
        ids[*index] = foreign_key_for(val)
      end
      val
    end
  end

  def collect!
    if block_given
      map!(Proc.new)
    else
      to_enum(:collect!)
    end
  end

  def compact!
    mutate_ids do
      ids.compact!
      self
    end
  end

  def concat(other)
    mutate_ids do
      ids.concat(other.map { |obj| foreign_key_for(obj) })
      self
    end
  end

  def delete(object)
    # TODO: optimize
    mutate_ids do
      id = ids.delete(foreign_key_for(object))
      if id
        @model.find(id)
      end
    end
  end

  def delete_at(index)
    # TODO: optimize
    mutate_ids do
      id = ids.delete_at(index)
      if id
        @model.find(id)
      end
    end
  end

  def delete_if
    if block_given?
      hash = ids_to_objects_hash
      mutate_ids do
        ids.delete_if { |id| yield hash[id] }
        self
      end
    else
      to_enum(:delete_if)
    end
  end

  def fill(*args)
    if block_given?
      mutate_ids do
        ids.fill(*args) do |index|
          foreign_key_for(yield index)
        end
      end
    else
      mutate_ids do
        obj = args.shift
        ids.fill(foreign_key_for(obj), *args)
      end
    end
    self
  end

  def insert(index, *objects)
    mutate_ids do
      ids.insert(index, *objects.map { |obj| foreign_key_for(obj) })
      self
    end
  end

  def keep_if
    if block_given?
      hash = ids_to_objects_hash
      mutate_ids do
        ids.keep_if { |id| yield hash[id] }
        self
      end
    else
      to_enum(:keep_if)
    end
  end

  def map!
    if block_given?
      data = to_a
      mutate_ids do
        data.each_with_index do |object, index|
          ids[index] = foreign_key_for(yield object)
        end
      end
    else
      to_enum :map!
    end
  end

  def pop
    # TODO: optimize
    mutate_ids do
      @model.find(ids.pop)
    end
  end

  def push(*objects)
    mutate_ids do
      ids.push(*objects.map{ |obj| foreign_key_for(obj) })
      self
    end
  end

  def reject!
    if block_given?
      hash = ids_to_objects_hash
      mutate_ids do
        if ids.reject! { |id| yield hash[id] }
          self
        end
      end
    else
      to_enum(:reject!)
    end
  end

  def replace(other_ary)
    mutate_ids do
      ids.replace other_ary.map{ |obj| foreign_key_for(obj) }
      self
    end
  end

  def reverse!
    mutate_ids do
      ids.reverse!
      self
    end
  end

  def rotate!(count=1)
    mutate_ids do
      ids.rotate! count
      self
    end
  end

  def select!
    if block_given?
      hash = ids_to_objects_hash
      mutate_ids do
        if ids.select! { |id| yield hash[id] }
          self
        end
      end
    else
      to_enum(:select!)
    end
  end

  def shift
    # TODO: optimize
    mutate_ids do
      @model.find(ids.shift)
    end
  end

  def shuffle!(args={})
    mutate_ids do
      ids.shuffle!(args)
      self
    end
  end

  def uniq!
    if block_given?
      hash = ids_to_objects_hash
      mutate_ids do
        ids.uniq! do |id|
          yield hash[id]
        end
      end
    else
      mutate_ids do
        ids.uniq!
      end
    end
    self
  end

  def unshift(*args)
    mutate_ids do
      ids.unshift(*args.map{ |obj| foreign_key_for(obj) })
    end
    self
  end

  private

  def foreign_key_for(obj)
    obj[@foreign_key] if obj
  end

  def ids_to_objects_hash
    index_by{ |obj| foreign_key_for(obj) }
  end

  def build_query!
    @relation = @scope.merge(@unscoped.where @foreign_key => ids.compact)
  end

  def_delegators :records, :each
  def_delegators :@relation, :loaded?, :to_sql
  def_delegators :ids, :size, :length
end
