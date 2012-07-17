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
      @tags = Tag.finder_for_autocomplete(:tag_partial_name => params[:search], :site_id => @site.id)
      render :layout => false, :partial => "/common/tag_search", :locals => { :tags => @tags }
    end

  end
end