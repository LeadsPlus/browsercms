require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HtmlBlock do
  it "should render it's content" do
    @html_block = create_html_block
    @html_block.render.should == @html_block.content
  end
  
  it "should be able to be connected to a page" do
    @page = create_page
    @html_block = create_html_block(:connect_to_page_id => @page.id, :connect_to_container => "test")
    @page.reload.connectors.count.should == 1
    @html_block.connected_page.should == @page
  end
  
  it "should be able to assign the connect_to values in the constructor" do
    @block = HtmlBlock.new("connect_to_container"=>"main", "connect_to_page_id"=>"516519628")
    @block.connect_to_page_id.should == "516519628"
    @block.connect_to_container.should == "main"
  end
  
  describe "versioning for blocks" do
    it "should support versioning" do
      h = HtmlBlock.new
      h.supports_versioning?.should be_true
    end

    describe "when creating a record" do
      before do
        @html_block = create_html_block
      end
      it "should create a version when creating a html_block" do
        @html_block.versions.latest.html_block.should == @html_block
      end
    end
    
    describe "when updating attributes" do
      describe "with different values" do
        before do
          @html_block = create_html_block(:name => "Original Value")
          @html_block.update_attributes(:name => "Something Different")
        end
        it "should create a version with the changed values" do
          @html_block.versions.latest.html_block.should == @html_block
          @html_block.versions.latest.name.should == "Something Different"
          @html_block.name.should == "Something Different"
        end
        it "should not affect the values in previous versions" do
          @html_block.versions.first.name.should == "Original Value"
        end
      end      
      describe "with the unchanged values" do
        before do
          @html_block = create_html_block(:name => "Original Value")
          @update_attributes = lambda { @html_block.update_attributes(:name => "Original Value") }
        end
        it "should not create a new version" do
          @update_attributes.should_not change(@html_block.versions, :count)
        end
      end
    end
    
    describe "when deleting a record" do
      before do
        @html_block = create_html_block
        @delete_html_block = lambda { @html_block.mark_as_deleted!(create_user) }
      end
      
      it "should not actually delete the row" do
        @delete_html_block.should_not change(HtmlBlock, :count)
      end
      it "should create a new version" do
        @delete_html_block.should change(@html_block.versions, :count).by(1)
      end
      it "should set the status to DELETED" do
        @delete_html_block.call
        @html_block.should be_deleted
      end
    end    
    
    describe "when reverting an existing block" do
      before do
        @html_block = new_html_block(:name => "Version One")
        @v1_created_at = Time.zone.now - 5.days
        @html_block.created_at = @v1_created_at
        @html_block.save
        v1 = @html_block.versions.latest
        v1.created_at = @v1_created_at
        v1.save
        @html_block.update_attributes(:name => "Version Two")
        @v2_created_at = @html_block.versions.latest.created_at
      end
      it "should be able to revert" do
        @html_block.name.should == "Version Two"
        @html_block.revert_to 1, create_user
        @html_block.reload.version.should == 3
        @html_block.name.should == "Version One" 
      end
      it "should keep the original created at time" do        
        @html_block.find_version(1).created_at.to_i.should == @v1_created_at.to_i
        @html_block.find_version(2).created_at.to_i.should == @v2_created_at.to_i
        @html_block.revert_to 1, create_user
        @html_block.reload
        @html_block.find_version(1).created_at.to_i.should == @v1_created_at.to_i
        @html_block.find_version(2).created_at.to_i.should == @v2_created_at.to_i
        @html_block.find_version(3).created_at.to_i.should >= @v2_created_at.to_i
        @html_block.created_at.to_i.should == @v1_created_at.to_i        
      end
      describe "without specifying a version number" do
        before do
          @action = lambda { @html_block.revert_to nil, create_user }
        end
        it "should raise 'Version parameter missing'" do
          @action.should raise_error("Version parameter missing")
        end
        it "should not create a new version" do
          lambda {
            begin
              @action.call
            rescue Exception
              nil
            end
          }.should_not change(HtmlBlock::Version, :count)
        end
      end
      describe "with an invalid version number" do
        before do
          @action = lambda { @html_block.revert_to 99, create_user }
        end
        it "should raise 'Could not find version 99'" do
          @action.should raise_error("Could not find version 99")
        end
        it "should not create a new version" do
          lambda {
            begin
              @action.call
            rescue Exception
              nil
            end
          }.should_not change(HtmlBlock::Version, :count)
        end
      end      
    end
    
    describe "when getting previous version of a block" do
      before do
        @html_block = create_html_block(:name => "V1")
        @html_block.update_attributes(:name => "V2")
        @version = @html_block.as_of_version 1
      end
      it "should return an HtmlBlock, rather than an HtmlBlock::Version" do
        @version.class.should == HtmlBlock
      end
      it "should have the name set to the name of the older version" do
        @version.name.should == "V1"
      end
      it "should have the version set to the version of the older version" do
        @version.version.should == 1
      end
      it "should have the same id" do
        @version.id.should == @html_block.id
      end
      it "should not be frozen" do
        #We can't freeze the version because we need to be able to load assocations
        @version.should_not be_frozen
      end
      it "current_version? should be false" do
        @version.current_version?.should be_false
      end
      it "current_version? should be true for the original object" do
        @html_block.current_version?.should be_true
      end
    end
  end
  
end
