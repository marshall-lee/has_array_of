module HasArrayOf
  class AssociatedArray::Relation
    def initialize(owner, options)
      @options = options
      @ids = owner.send(ids_attribute)
      @owner = owner
      build_query!
      me = self
      @relation = model.where(query).extending do
        pkey_attribute = options[:pkey_attribute]
        define_method :to_a do
          hash = super().reduce({}) do |memo, object|
            memo[object.try(pkey_attribute)] = object
            memo
          end
          me.ids.map { |id| hash[id] }
        end
      end

      if options[:extension]
        @relation = @relation.extending(options[:extension])
      end
    end

    attr_reader :ids

    def load
      relation.load
      self
    end

    def to_a
      hash = ids_to_objects_hash
      ids.map { |id| hash[id] }
    end

    def each(&block)
      to_a.each(&block)
    end

    include Enumerable

    def pluck(*column_names)
      raise NotImplementedError
    end

    def ==(other)
      to_a == other
    end

    def mutate_ids
      relation.reset
      where_values.reject! { |v| v == query }
      ret = yield
      owner.send :write_attribute, ids_attribute, ids
      build_query!
      relation.where! query
      ret
    end

    def <<(object)
      mutate_ids do
        ids << object.try(pkey_attribute)
        self
      end
    end

    def []=(*index, val)
      mutate_ids do
        if val.is_a? Array
          ids[*index] = val.map(&try_pkey_proc)
        else
          ids[*index] = val.try(pkey_attribute)
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
        ids.concat(other.map(&try_pkey_proc))
        self
      end
    end

    def delete(object)
      # TODO: optimize
      mutate_ids do
        id = ids.delete(object.try(pkey_attribute))
        if id
          model.find(id)
        end
      end
    end

    def delete_at(index)
      # TODO: optimize
      mutate_ids do
        id = ids.delete_at(index)
        if id
          model.find(id)
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
            (yield index).try(pkey_attribute)
          end
        end
      else
        mutate_ids do
          obj = args.shift
          ids.fill(obj.try(pkey_attribute), *args)
        end
      end
      self
    end

    def insert(index, *objects)
      mutate_ids do
        ids.insert(index, *objects.map(&try_pkey_proc))
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
            ids[index] = (yield object).try(pkey_attribute)
          end
        end
      else
        to_enum :map!
      end
    end

    def pop
      # TODO: optimize
      mutate_ids do
        model.find(ids.pop)
      end
    end

    def push(*objects)
      mutate_ids do
        ids.push(*objects.map(&try_pkey_proc))
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
        ids.replace other_ary.map(&try_pkey_proc)
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
        model.find(ids.shift)
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
        ids.unshift(*args.map(&try_pkey_proc))
      end
      self
    end

    private

    def ids_to_objects_hash
      relation.load.reduce({}) do |memo, object|
        memo[object.try(pkey_attribute)] = object
        memo
      end
    end

    def build_query!
      @query = model.arel_table[pkey_attribute].in(ids.compact)
    end

    def model
      @options[:model]
    end

    def ids_attribute
      @options[:ids_attribute]
    end

    def pkey_attribute
      @options[:pkey_attribute]
    end

    def try_pkey_proc
      @options[:try_pkey_proc]
    end

    attr_reader :owner
    attr_reader :query
    attr_reader :relation

    relation_methods = ::ActiveRecord::Relation.instance_methods - instance_methods - private_instance_methods
    delegate *relation_methods, :to => :relation
    delegate :size, :length, :to => :ids
  end
end
