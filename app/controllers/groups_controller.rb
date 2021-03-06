class GroupsController < ReaderActionController
  helper :reader
  
  before_filter :require_reader
  before_filter :get_group_or_groups
  before_filter :require_group_visibility, :only => [:show]

  def index
  end

  def show
    @readers = @group.readers.uniq
    respond_to do |format|
      format.html
      format.csv {
        send_data Reader.csv_for(@readers), :type => 'text/csv; charset=utf-8; header=present', :filename => "#{@group.filename}.csv"
      }
      format.vcard {
        send_data Reader.vcards_for(@readers), :filename => "everyone.vcf"
      }
    end
  end
    
private
  
  def get_group_or_groups
    @groups = current_reader.groups
    @group = Group.find(params[:id]) if params[:id]
  end

  def require_group_visibility
     if @group && !@group.visible_to?(current_reader)    # nb. @groups is a smaller set
       raise ReaderError::AccessDenied, "That group is not public and you are not in it."
     end
  end
  
end
