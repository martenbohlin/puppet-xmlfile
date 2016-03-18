require 'spec_helper'


describe Puppet::Type.type(:xmlfile) do
  let(:testobject) {  Puppet::Type.type(:xmlfile) }
  
  # Test each of the inherited params and properties to ensure
  # validations are properly inherited.
  describe :path do
    it "should be fully-qualified" do
      expect {
        testobject.new(
          :name   => 'foo',
          :path   => 'my/path',
      )}.to raise_error(Puppet::Error, /paths must be fully qualified/)
    end

    it "should accept if fully-qualified" do
      xmlfile = testobject.new(
        :name   => 'foo',
        :path   => '/my/path',
      )
      expect(xmlfile[:path]).to eq('/my/path')
    end
  end 
  
  describe :ctime do
    it "should be read-only" do
      expect {
        testobject.new(
          :name   => 'foo',
          :path   => '/my/path',
          :ctime  => 'somevalue',
      )}.to raise_error(Puppet::Error, /read-only/)
    end
  end 
  
  describe :mtime do
    it "should be read-only" do
      expect {
        testobject.new(
          :name   => 'foo',
          :path   => '/my/path',
          :mtime  => 'somevalue',
      )}.to raise_error(Puppet::Error, /read-only/)
    end
  end 
  
  describe :group do
    it "should not accept empty values" do
      expect {
        testobject.new(
         :name   => 'foo',
         :path   => '/my/path',
         :group  => '',
      )}.to raise_error(Puppet::Error, /Invalid group name/)  
    end
  end
  
  describe :mode do
    it "should perform validations" do
      expect {
        testobject.new(
         :name   => 'foo',
         :path   => '/my/path',
         :mode   => 'fghl',
      )}.to raise_error(Puppet::Error, /file mode specification is invalid/)  
    end
  end
  
  describe :source do
    it "should not accept a relative URL" do
      expect {
        testobject.new(
         :name   => 'foo',
         :path   => '/my/path',
         :source => 'modules/puppet/file',
      )}.to raise_error(Puppet::Error, /Cannot use relative URLs/)  
    end

    it "should not allow a source if content set" do
      expect {
        testobject.new(
         :name    => 'foo',
         :path    => '/my/path',
         :source  => '/modules/puppet/file',
         :content => '<somexml></somexml>',
      )}.to raise_error(Puppet::Error, /Can specify either source or content but not both/)  
    end
  end

  describe "generated content" do
    context "with no :source or :content set" do
      it "should be blank" do
        catalog = Puppet::Resource::Catalog.new("host")

        xmlfile = testobject.new(
          :catalog => catalog,
          :name   => 'foo',
          :path   => '/my/path',
        )
        expect(xmlfile.should_content()).to eq('')
      end
    end

    context "with :content set" do
      it "should load in the file" do
        catalog = Puppet::Resource::Catalog.new("host")

        xmlfile = testobject.new(
          :catalog => catalog,
          :name   => 'foo',
          :path   => '/my/path',
          :content => '<xmlfile>testing</xmlfile>'
        )
        expect(xmlfile.should_content()).to eq('<xmlfile>testing</xmlfile>')
      end
    end

    context "with :source set" do
        let(:dummy_class) do
          Class.new do

            def content
              "<file>from disk</file>"
            end
          end
        end
      it "should load in the file" do
        catalog = Puppet::Resource::Catalog.new("host")
        Puppet::FileServing::Content.indirection.expects(:find).returns(dummy_class.new)


        xmlfile = testobject.new(
          :catalog => catalog,
          :name   => 'foo',
          :path   => '/my/path',
          :source => '/module/example.xml'
        )
        expect(xmlfile.should_content()).to eq('<file>from disk</file>')
      end
    end

    context "with :use_existing_file set" do
      let(:dummy_class) do
        Class.new do

          def read
            "<file>Existing file</file>"
          end
        end
      end

      context "and file exists on disk" do
        it "should load in the existing file" do
          catalog = Puppet::Resource::Catalog.new("host")
          File.expects(:exist?).returns(true)
          File.expects(:open).returns(dummy_class.new)

          xmlfile = testobject.new(
            :catalog => catalog,
            :name   => 'foo',
            :path   => '/my/path',
            :use_existing_file => true,
          )
          expect(xmlfile.should_content()).to eq('<file>Existing file</file>')
        end
      end

      context "and file does NOT exist on disk" do
        it "should default to a blank string" do
          catalog = Puppet::Resource::Catalog.new("host")
          File.expects(:exist?).returns(false)

          xmlfile = testobject.new(
            :catalog => catalog,
            :name   => 'foo',
            :path   => '/my/path',
            :use_existing_file => true,
          )
          expect(xmlfile.should_content()).to eq('')
        end
      end
    end

  end
end
