module HasArrayOf
  class AssociatedArray::Relation
    def initialize(owner, associated_model, ids_attr)
      @owner = owner
      @associated_model = associated_model
      @foreign_id_attr = associated_model.primary_key
      @ids_attr = ids_attr
      build_query!
      me = self
      @relation = associated_model.where(query).extending do
        foreign_id_for_proc = me.send :foreign_id_for_proc
        define_method :load do
          super()
          @records = @records.index_by(&foreign_id_for_proc).values_at(*me.ids)
        end
      end
    end

    def ids
      owner[ids_attr]
    end

    def ids=(new_ids)
      owner[ids_attr] = new_ids
    end

    def load
      relation.load
      self
    end

    def where(*args)
      relation.where(*args).extending do
        def load
          super
          @records.compact!
        end
      end
    end

    def where!(*args)
      @relation = where(*args)
      self
    end

    def to_a
      relation.to_a
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
      self.ids = ids
      build_query!
      relation.where! query
      ret
    end

    def <<(object)
      mutate_ids do
        ids << foreign_id_for(object)
        self
      end
    end

    def []=(*index, val)
      mutate_ids do
        if val.is_a? Array
          ids[*index] = val.map(&foreign_id_for_proc)
        else
          ids[*index] = foreign_id_for(val)
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
        ids.concat(other.map(&foreign_id_for_proc))
        self
      end
    end

    def delete(object)
      # TODO: optimize
      mutate_ids do
        id = ids.delete(foreign_id_for(object))
        if id
          associated_model.find(id)
        end
      end
    end

    def delete_at(index)
      # TODO: optimize
      mutate_ids do
        id = ids.delete_at(index)
        if id
          associated_model.find(id)
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
            foreign_id_for(yield index)
          end
        end
      else
        mutate_ids do
          obj = args.shift
          ids.fill(foreign_id_for(obj), *args)
        end
      end
      self
    end

    def insert(index, *objects)
      mutate_ids do
        ids.insert(index, *objects.map(&foreign_id_for_proc))
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
            ids[index] = foreign_id_for(yield object)
          end
        end
      else
        to_enum :map!
      end
    end

    def pop
      # TODO: optimize
      mutate_ids do
        associated_model.find(ids.pop)
      end
    end

    def push(*objects)
      mutate_ids do
        ids.push(*objects.map(&foreign_id_for_proc))
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
        ids.replace other_ary.map(&foreign_id_for_proc)
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
        associated_model.find(ids.shift)
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
        ids.unshift(*args.map(&foreign_id_for_proc))
      end
      self
    end

    def size
      ids ? ids.size : 0
    end
    alias_method :length, :size

    private

    def foreign_id_for(obj)
      obj[foreign_id_attr] if obj
    end

    def foreign_id_for_proc
      @foreign_id_for_proc ||= method(:foreign_id_for)
    end

    def ids_to_objects_hash
      index_by(&foreign_id_for_proc)
    end

    def build_query!
      @query = associated_model.arel_table[foreign_id_attr].in((ids ? ids : []).compact)
    end

    attr_reader :owner, :ids_attr
    attr_reader :associated_model, :foreign_id_attr, :query
    attr_reader :relation

    relation_methods = ::ActiveRecord::Relation.instance_methods - instance_methods - private_instance_methods
    delegate *relation_methods, :to => :relation
  end
end
