class HasArrayOf::CollectionProxy
  extend Forwardable

  class << self
    def subclass_for(setup)
      Class.new(self) do
        @setup = setup
      end
    end

    def __has_array_of_setup__
      @setup
    end
  end

  def initialize(owner, scope: self.class.__has_array_of_setup__.model.all)
    @owner = owner
    @scope = scope
    @setup = self.class.__has_array_of_setup__
  end

  # TODO: come up with a custom type that resets the association if value modified.
  def ids
    @owner[@setup.ids_attribute]
  end

  def ids=(ids)
    # TODO: Store @records as Hash { 123 => model }
    @records = nil

    ids_attribute = @setup.ids_attribute
    @owner[ids_attribute] = ids
    @ids = @owner[ids_attribute].dup
  end

  def load
    @records ||= begin
      ids = self.ids.dup
      ids.compact!
      records = build_relation(ids).records
      idx = records.index_by { |obj| @setup.obj_key(obj) }

      records = []
      ids.map! do |id|
        if (obj = idx[id])
          records << obj
          id
        end
      end
      ids.compact!
      @ids = ids
      records
    end
    self
  end

  def loaded?
    !@records.nil?
  end

  def records
    load_target
  end
  alias target records

  def load_target
    load
    @records
  end

  def target=(objects)
    @ids = objects.map { |obj| @setup.obj_key!(obj) }
    @owner[@setup.ids_attribute] = @ids
    @records = objects.to_ary.dup
  end

  def size
    @records.size
  end
  alias length size

  def to_sql
    build_relation.to_sql
  end

  def where(*args)
    self.class.new(@owner, scope: @scope.where(*args))
  end

  def to_ary
    records.dup
  end
  alias to_a to_ary

  def each(&block)
    records.each(&block)
  end

  include Enumerable

  def ==(other)
    other == records
  end

  def <<(object)
    records << object
    @ids << @setup.obj_key!(object)
    self
  end

  def []=(index, obj)
    raise_on_index_out_of_range!(index)
    @ids[index] = @setup.obj_key!(obj)
    records[index] = obj
  end

  def compact!
    self
  end

  def concat(objects)
    ids = objects.map { |obj| @setup.obj_key!(obj) }
    records.concat(objects)
    @ids.concat(ids)
    sync_ids!
    self
  end

  def count(...)
    records.count(...)
  end

  def delete(object)
    @setup.raise_on_type_mismatch!(object)
    if (ret = records.delete(object))
      reset_ids!
    end
    ret
  end

  def delete_at(index)
    if (ret = delete_at index)
      @ids.delete_at(index)
      sync_ids!
    end
    ret
  end

  def fill(*args)
    if block_given?
      fill_ids = []
      new_records = records.dup
      new_records.fill(*args) do |index|
        obj = yield index
        fill_ids << @setup.obj_key!(obj)
      end
      @records = new_records
      @ids.fill { |index| fill_ids[index] }
    else
      obj, *args = args
      id = @setup.obj_key!(obj)
      records.fill(obj, *args)
      @ids.fill(id, *args)
    end
    sync_ids!
    self
  end

  def insert(index, *objects)
    ids = objects.map { |obj| @setup.obj_key!(obj) }
    records.insert(index, *objects)
    @ids.insert(index, *ids)
    sync_ids!
    self
  end

  def map!
    if block_given?
      ids = @ids
      records.map!.with_index do |obj, index|
        obj = yield obj
        ids[index] = @setup.obj_key!(obj)
        obj
      end
      sync_ids!
      self
    else
      to_enum :map!
    end
  end
  alias collect! map!

  def pluck(*column_names)
    if @records
      model = @setup.model
      if (column_names.map(&:to_s) - model.attribute_names - model.attribute_aliases.keys).empty?
        return @records.pluck(*column_names)
      end
    end
    build_relation.pluck(*column_names)
  end

  def pop(...)
    ret = records.pop(...)
    @ids.pop(...)
    sync_ids!
    ret
  end

  def prepend(*objects)
    ids = objects.map! { |obj| @setup.obj_key!(obj) }
    records.prepend(*objects)
    @ids.prepend(*ids)
    sync_ids!
    self
  end
  alias unshift prepend

  def push(*objects)
    ids = objects.map! { |obj| @setup.obj_key!(obj) }
    records.push(*objects)
    @ids.push(*ids)
    sync_ids!
    self
  end
  alias append push

  def reject!
    if block_given?
      ids = []
      ret = records.reject! do |obj|
        unless (ret1 = yield obj)
          ids << @setup.obj_key(obj)
        end
        ret1
      end
      self._ids = ids
      self if ret
    else
      to_enum :reject!
    end
  end
  alias delete_if reject!

  def replace(objects)
    self.target = objects
    self
  end

  def reverse!
    records.reverse!
    @ids.reverse!
    sync_ids!
    self
  end

  def rotate!(...)
    records.rotate!(...)
    @ids.rotate!(...)
    sync_ids!
    self
  end

  def select!
    if block_given?
      ids = []
      records.select! do |obj|
        if (ret = yield obj)
          ids << @setup.obj_key(obj)
        end
        ret
      end
      self._ids = ids
      self
    else
      to_enum :select!
    end
  end
  alias keep_if reject!

  def shift(...)
    ret = records.shift(...)
    @ids.shift(...)
    ret
  end

  def shuffle!(...)
    records.shuffle!(...)
    reset_ids!
    self
  end

  def uniq!(...)
    records.uniq!(...)
    reset_ids!
    self
  end

  private

  def reset_ids!
    self._ids = records.map { |obj| @setup.obj_key(obj) }
  end

  def _ids=(ids)
    @ids = ids
    @owner[@setup.ids_attribute] = ids
  end

  def sync_ids!
    @owner[@setup.ids_attribute] = @ids
  end

  def raise_on_index_out_of_range!(index)
    raise ArgumentError, 'index must be a Fixnum' unless index.is_a?(Integer)

    if (index >= records.size) || (index.negative? && (-index) > records.size)
      raise ArgumentError, "index #{index} is out of bounds"
    end
  end

  def build_relation(ids = self.ids.compact)
    @scope.merge(@setup.model.unscoped.where(@setup.model_pkey => ids))
  end
end
