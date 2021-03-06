module GroupTags
  include Radiant::Taggable
  include ReaderHelper
  
  class TagError < StandardError; end
  desc %{
    The root 'group' tag is not meant to be called directly. 
    All it does is summon a group object so that its fields can be displayed with eg.
    
    <pre><code><r:group:name /></code></pre>
  
    To show a particular group, supply an id or name attribute. There is no access control
    involved here: if you choose to show a group on an unrestricted page, it will appear.
    
    Note that because of limitations in radius this has to be done in a containing root tag:
    
    <pre><code><r:group id="1"><r:group:url /></r;group></code></pre>
  }
  tag 'group' do |tag|
    tag.locals.group = if tag.attr['id']
      Group.find_by_id(tag.attr['id'])
    elsif tag.attr['name']
      Group.find_by_name(tag.attr['name'])
    elsif @mailer_vars
      @mailer_vars[:@group]
    else
      tag.locals.page.homegroup
    end
    tag.expand if tag.locals.group
  end

  [:name, :description, :url].each do |field|
    desc %{
      Displays the #{field} field of the currently relevant group. Works in email messages too.
    
      <pre><code><r:group:#{field} /></code></pre>
    }
    tag "group:#{field}" do |tag|
      tag.locals.group.send(field)
    end
  end

  desc %{
    Expands if this group has messages.
  
    <pre><code><r:group:if_messages>...</r:group:if_messages /></code></pre>
  }
  tag "group:if_messages" do |tag|
    tag.expand if tag.locals.group.messages.ordinary.published.any?
  end

  desc %{
    Expands if this group does not have messages.
  
    <pre><code><r:group:unless_messages>...</r:group:unless_messages /></code></pre>
  }
  tag "group:unless_messages" do |tag|
    tag.expand unless tag.locals.group.messages.ordinary.published.any?
  end

  desc %{
    Loops through the non-functional messages (ie not welcomes and reminders) that belong to this group 
    and that have been sent, though not necessarily to the present reader (which is the point, really).
  
    <pre><code><r:group:messages:each>...</r:group:messages:each /></code></pre>
  }
  tag "group:messages" do |tag|
    tag.locals.messages = tag.locals.group.messages.ordinary.published
    tag.expand
  end
  tag "group:messages:each" do |tag|
    result = []
    tag.locals.messages.each do |message|
      tag.locals.message = message
      result << tag.expand
    end
    result
  end
end
