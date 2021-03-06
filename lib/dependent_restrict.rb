require 'active_record'
require 'dependent_restrict/delete_restriction_error'

module DependentRestrict
  def self.included(base)
    super
    base.extend(ClassMethods)

    base.class_eval do
    end
  end

  module ClassMethods
    VALID_DEPENDENTS = [:rollback, :restrict_with_error, :restrict, :restrict_with_exception]

    # We should be aliasing configure_dependency_for_has_many but that method
    # is private so we can't. We alias has_many instead trying to be as fair
    # as we can to the original behaviour.
    def has_one(*args, &extension)
      options = args.extract_options! || {}
      if VALID_DEPENDENTS.include?(options[:dependent].try(:to_sym))
        reflection = if active_record_4?
          association_id, scope = *args
          restrict_create_reflection(:has_one, association_id, scope || {}, options, self)
        else
          association_id = args[0]
          create_reflection(:has_one, association_id, options, self)
        end
        add_dependency_callback!(reflection, options)
      end
      args << options
      super(*args, &extension)
    end

    def has_many(*args, &extension)
      options = args.extract_options! || {}
      if VALID_DEPENDENTS.include?(options[:dependent].try(:to_sym))
        reflection = if active_record_4?
          association_id, scope = *args
          restrict_create_reflection(:has_many, association_id, scope || {}, options, self)
        else
          association_id = args.first
          create_reflection(:has_many, association_id, options, self)
        end
        add_dependency_callback!(reflection, options)
      end
      args << options
      super(*args, &extension)
    end

    def has_and_belongs_to_many(*args, &extension)
      options = args.extract_options! || {}
      if VALID_DEPENDENTS.include?(options[:dependent].try(:to_sym))
        reflection = if active_record_4?
          association_id, scope = *args
          restrict_create_reflection(:has_and_belongs_to_many, association_id, scope || {}, options, self)
        else
          association_id = args.first
          create_reflection(:has_and_belongs_to_many, association_id, options, self)
        end
        add_dependency_callback!(reflection, options)
        options.delete(:dependent)
      end
      args << options
      super(*args, &extension)
    end

    private

    def add_dependency_callback!(reflection, options)
      dependent_type = active_record_4? ? options[:dependent] : reflection.options[:dependent]
      name = reflection.name
      name = name.first if name.is_a?(Array) # rails 3
      method_name = "dependent_#{dependent_type}_for_#{name}"
      case dependent_type
      when :rollback, :restrict_with_error
        options.delete(:dependent)
        define_method(method_name) do
          method = reflection.collection? ? :empty? : :nil?
          unless send(name).send(method)
            raise ActiveRecord::Rollback
          end
        end
        before_destroy method_name.to_sym
      when :restrict, :restrict_with_exception
        options.delete(:dependent)
        define_method(method_name) do
          method = reflection.collection? ? :empty? : :nil?
          unless send(name).send(method)
            raise ActiveRecord::DetailedDeleteRestrictionError.new(name, self)
          end
        end
        before_destroy method_name.to_sym
      end
    end

    def active_record_4?
      ::ActiveRecord::VERSION::MAJOR >= 4
    end

    def restrict_create_reflection(*args)
      if ActiveRecord::Reflection.respond_to? :create
        if args[0] == :has_and_belongs_to_many
          args[0] = :has_many
          args[3][:through] = [self.table_name, args[1].to_s].sort.join('_')
        end
        ActiveRecord::Reflection.create *args
      else
        create_reflection(*args)
      end
    end

  end
end

ActiveRecord::Base.send(:include, DependentRestrict)
