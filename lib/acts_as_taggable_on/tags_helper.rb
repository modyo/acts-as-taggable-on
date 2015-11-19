module ActsAsTaggableOn
  module TagsHelper
    # See the README for an example using tag_cloud.
    def tag_cloud(tags, classes)
      tags = tags.all if tags.respond_to?(:all)

      return [] if tags.empty?

      max_count = tags.sort_by(&:count).last.count.to_f

      tags.each do |tag|
        index = ((tag.count / max_count) * (classes.size - 1))
        yield tag, classes[index.nan? ? 0 : index.round]
      end
    end

    def tag_search

      tag_partial_name = params[:search]+'%'
      @tags = ActsAsTaggableOn::Tag.all(:conditions => ["name LIKE ? and account_id = ?" , tag_partial_name, @account.id])

      output = []
      @tags.each do |t|
        output << [t.name,t.name,nil,t.name]
      end

      render :layout => false, :json => output

    end

  end
end