module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    include ActsAsTaggableOn::Utils

    attr_accessible :name, :account


    ### ASSOCIATIONS:

    has_many :taggings, :dependent => :destroy, :class_name => 'ActsAsTaggableOn::Tagging'
    belongs_to :account, :class_name => 'Account', :foreign_key => 'account_id'

    ### VALIDATIONS:

    validates_presence_of :name
    validates_uniqueness_of :name, :scope => 'account_id'
    validates_length_of :name, :maximum => 255

    ### SCOPES:

    def self.named(name, account)
      where('lower(name) = ? and account_id = ?', name.downcase, account.id)
    end

    def self.named_any(list, account)
      where("account_id = #{account.id}").where(list.map { |tag| sanitize_sql(['lower(name) = ?', tag.to_s.mb_chars.downcase]) }.join(' OR '))
    end

    def self.named_like(name, account)
      where(["name #{like_operator} ? ESCAPE '!' and account_id = ?", "%#{escape_like(name)}%", account.id])
    end

    def self.named_like_any(list, account)
      where("account_id = #{account.id}").where(list.map { |tag| sanitize_sql(["name #{like_operator} ? ESCAPE '!'", "%#{escape_like(tag.to_s)}%"]) }.join(" OR "))
    end

    ### CLASS METHODS:

    def self.find_or_create_with_like_by_name(name, account)
      named_like(name, account).first || create(:name => name, :account => account)
    end

    def self.find_or_create_all_with_like_by_name(account, *list)
      list = [list].flatten

      return [] if list.empty?

      existing_tags = Tag.named_any(list, account).all
      new_tag_names = list.reject do |name|
        name = comparable_name(name)
        existing_tags.any? { |tag| comparable_name(tag.name) == name }
      end
      created_tags  = new_tag_names.map { |name| Tag.create(:name => name, :account => account) }

      existing_tags + created_tags
    end

    ### INSTANCE METHODS:

    def ==(object)
      super || (object.is_a?(Tag) && name == object.name)
    end

    def to_s
      name
    end

    def count
      read_attribute(:count).to_i
    end

    class << self
      private
      def comparable_name(str)
        str.mb_chars.downcase.to_s
      end
    end
  end
end
