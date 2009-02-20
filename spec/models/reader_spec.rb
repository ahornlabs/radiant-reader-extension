require File.dirname(__FILE__) + '/../spec_helper'
ActionMailer::Base.delivery_method = :test  
ActionMailer::Base.perform_deliveries = true  
ActionMailer::Base.deliveries = []
Radiant::Config['readers.default_mail_from_address'] = "test@example.com"
Radiant::Config['readers.default_mail_from_name'] = "test"
Radiant::Config['site.title'] = 'Test Site'
Radiant::Config['site.url'] = 'www.example.com'
Radiant::Config['readers.layout'] = 'Main'

describe Reader do
  dataset :readers
  dataset :reader_layouts
  dataset :reader_sites
  
  before do  # we need associations
    @site = Page.current_site = sites(:test)
    @existing_reader = readers(:normal)
  end
  
  describe "on validation" do
    before do
      @reader = Reader.new :name => "Test Reader", :email => 'test@spanner.org', :login => 'test', :password => 'password', :password_confirmation => 'password'
      @reader.confirm_password = false
    end
    
    it "should require a name" do
      @reader.name = nil
      @reader.should_not be_valid
      @reader.errors.on(:name).should_not be_empty
    end
  
    it "should require a valid email address" do
      @reader.email = nil
      @reader.should_not be_valid
      @reader.errors.on(:email).should_not be_empty
      @reader.email = 'nodomain'
      @reader.should_not be_valid
      @reader.email = 'bad@punctuation'
      @reader.should_not be_valid
    end
  
    it "should require a unique login" do
      @reader.login = @existing_reader.login
      @reader.should_not be_valid
      @reader.errors.on(:login).should_not be_empty
    end
    
    it 'should confirm the password by default' do
      @reader = Reader.new
      @reader.confirm_password?.should == true
    end
  end
  
  describe "on creation" do
    before do
      @reader = Reader.create :name => "Test Reader", :email => 'test@spanner.org', :login => 'test', :password => 'password', :password_confirmation => 'password'
    end
  
    it "should belong to the current site" do
      @reader.site.should_not be_nil
      @reader.site.should == Reader.current_site
      @reader.site.name.should == @site.name
    end

    it 'should save password encrypted' do
      @reader.confirm_password = true
      @reader.password_confirmation = @reader.password = 'test_password'
      @reader.save!
      @reader.password.should == @reader.sha1('test_password')
    end
    
    it "should create a salt when encrypting the password" do
      @reader.salt.should_not be_nil
    end
    
    it 'should await activation' do
      @reader.activation_code.should_not be_nil
      @reader.activated_at.should be_nil
      @reader.activated?.should be_false
    end

    it 'should send out an activation email' do
      message = ActionMailer::Base.deliveries.last
      message.should_not be_nil
      message.subject.should =~ /activate/
      message.body.should =~ /#{@reader.name}/
      message.body.should =~ /#{@reader.login}/
      message.body.should =~ /#{@reader.current_password}/
    end
    
    it 'should default to trusted status' do
      @reader.trusted.should == true
    end
  end
  
  describe "on update" do
    before do
      @reader = Reader.create :name => "Test Reader", :email => 'test@spanner.org', :login => 'test', :password => 'password', :password_confirmation => 'password'
    end

    it 'should keep existing password if an empty password is supplied' do
      @reader.password_confirmation = @reader.password = ''
      @reader.save!
      @reader.password.should == @reader.sha1('password')
    end
  
    it 'should save new password if different' do
      @reader.password_confirmation = @reader.password = 'cool beans'
      @reader.save!
      @reader.password.should == @reader.sha1('cool beans')
    end
    
    it 'should be puttable in the doghouse' do
      @reader.password_confirmation = @reader.password = ''
      @reader.trusted = false
      @reader.save!
      @reader.trusted.should == false
    end
  end
  
  describe "on activation" do
    before do
      @reader = Reader.create :name => "Test Reader", :email => 'test@spanner.org', :login => 'another login', :password => 'password', :password_confirmation => 'password', :trusted => 1
      @reader.confirm_password = false
    end

    it 'should not activate itself without confirmation' do
      @reader.activate!('nonsense').should be_false
    end

    it 'should activate itself with confirmation' do
      @reader.activate!( @reader.activation_code ).should be_true
      @reader.activated?.should be_true
      @reader.activated_at.should_not be_nil
    end
  end
  
  describe "on login" do
    before do
      @reader = Reader.create :name => "Test Reader", :email => 'test@spanner.org', :login => 'test', :password => 'password', :password_confirmation => 'password'
      @reader.confirm_password = false
      @reader.activate!(@reader.activation_code).should be_true
    end
    
    it 'should authenticate' do
      reader = Reader.authenticate('test', 'password')
      reader.should == @reader
    end
  
    it 'should not authenticate with bad password' do
      Reader.authenticate('test', 'wrong password').should be_nil
    end
  
    it 'should not authenticate if it does not exist' do
      Reader.authenticate('loch ness monster', 'password').should be_nil
    end
  end
  
  describe "whenm a new password is requested" do
    before do
      @reader = Reader.create :name => "Test Reader", :email => 'test@spanner.org', :login => 'test', :password => 'password', :password_confirmation => 'password'
      @reader.confirm_password = false
      @reader.activate!(@reader.activation_code)
      @reader.activation_code.should be_nil
      @reader.repassword
    end
  
    it 'should set an activation code' do
      @reader.provisional_password.should_not be_nil
      @reader.activation_code.should_not be_nil
    end
  
    it 'should send out a confirmation email' do
      message = ActionMailer::Base.deliveries.last
      message.should_not be_nil
      message.subject.should == "Reset your password"
      message.body.should =~ /#{@reader.name}/
      message.body.should =~ /#{@reader.login}/
      message.body.should =~ /#{@reader.provisional_password}/
    end
  
    it 'should not change the password without correct confirmation' do
      @reader.confirm_password('').should be_false
      @reader.confirm_password('nonsense').should be_false
      @reader.password.should == @reader.sha1('password')
    end
  
    it 'should change the password with correct confirmation' do
      pw = @reader.provisional_password
      @reader.confirm_password(@reader.activation_code).should be_true
      @reader.password.should == @reader.sha1(pw)
    end
  end      
end
