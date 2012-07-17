module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base
    include ActsAsTaggableOn::Utils

    attr_accessible :name

    ### ASSOCIATIONS:

    has_many :taggings, :dependent => :destroy, :class_name => 'ActsAsTaggableOn::Tagging'
    belongs_to :site, :class_name => "Site", :foreign_key => "site_id"

    ### VALIDATIONS:

    validates_presence_of :name
    validates_uniqueness_of :name, :scope => 'site_id'
    validates_length_of :name, :maximum => 255

    ### SCOPES:

    def self.named(name, site)
      where(["lower(name) = ? and site_id = ?", name.downcase, site.id])
    end

    def self.named_any(list, site)
      #where("(#{list.map { |tag| sanitize_sql(['lower(name) = ?', tag.to_s.mb_chars.downcase]) }.join(' OR ')}) AND site_id = #{site.id}")
      where("site_id = #{site.id}").where(list.map { |tag| sanitize_sql(["lower(name) = ?", tag.to_s.mb_chars.downcase]) }.join(" OR "))
    end

    def self.named_like(name, site)
      where(["name #{like_operator} ? ESCAPE '!' and site_id = ?", "%#{escape_like(name)}%", site.id])
    end

    def self.named_like_any(list, site)
      where("site_id = #{site.id}").where(list.map { |tag| sanitize_sql(["name #{like_operator} ? ESCAPE '!'", "%#{escape_like(tag.to_s)}%"]) }.join(" OR "))
    end

    ### CLASS METHODS:

    def self.find_or_create_with_like_by_name(name, site)
      named_like(name, site).first || create(:name => name, :site => site)
    end

    def self.find_or_create_all_with_like_by_name(site, *list)
      list = [list].flatten

      return [] if list.empty?

      existing_tags = Tag.named_any(list, site).all
      new_tag_names = list.reject do |name|
                        name = comparable_name(name)
                        existing_tags.any? { |tag| comparable_name(tag.name) == name }
                      end
      created_tags  = new_tag_names.map { |name| Tag.create(:name => name, :site => site) }

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
