require 'scraperwiki'
require 'spec_helper'
require 'debugger'

describe ScraperWiki do
  before do
    @dummy_sqlite_magic_connection = double('sqlite_magic_connection')
    SqliteMagic::Connection.stub(:new).and_return(@dummy_sqlite_magic_connection)
  end

  after do
    # reset cached value
    ScraperWiki.instance_variable_set(:@sqlite_magic_connection, nil)
    ScraperWiki.instance_variable_set(:@config, nil)
  end

  describe "#config=" do
    it "should set config instance variable" do
      ScraperWiki.config = :some_config
      ScraperWiki.instance_variable_get(:@config).should == :some_config
    end

  end

  describe 'sqlite_magic_connection' do
    it 'should execute select query and bind variables to connection' do
      sql_snippet = 'foo from bar WHERE "baz"=42'
      @dummy_sqlite_magic_connection.should_receive(:execute).with("SELECT #{sql_snippet}", ['foo', 'bar'])
      ScraperWiki.select(sql_snippet, ['foo', 'bar'])
    end

    context 'and no config set' do
      it 'should get an SqliteMagic::Connection with default db name and no path' do
        SqliteMagic::Connection.should_receive(:new).with('scraperwiki.sqlite').and_return(@dummy_sqlite_magic_connection)
        ScraperWiki.sqlite_magic_connection
      end
    end

    context 'and config set' do
      before do
        ScraperWiki.config = {:db => '/some/location/of/sqlite_file.db'}
      end

      it 'should get an SqliteMagic::Connection with db set in config' do
        SqliteMagic::Connection.should_receive(:new).with('/some/location/of/sqlite_file.db').and_return(@dummy_sqlite_magic_connection)
        ScraperWiki.sqlite_magic_connection
      end
    end

    it 'should cache connection' do
      SqliteMagic::Connection.should_receive(:new).and_return(@dummy_sqlite_magic_connection) # just once
      ScraperWiki.sqlite_magic_connection
      ScraperWiki.sqlite_magic_connection
    end

  end

  describe '#select' do
    it 'should execute select query with bind variables on connection' do
      sql_snippet = 'foo from bar WHERE "baz"=42'
      @dummy_sqlite_magic_connection.should_receive(:execute).with("SELECT #{sql_snippet}", ['foo', 'bar'])
      ScraperWiki.select(sql_snippet, ['foo', 'bar'])
    end

    it "should return array of hashes returned by connection" do
      sqlite_magic_response = [{"animal"=>"fox"}, {"animal"=>"cat"}]
      @dummy_sqlite_magic_connection.stub(:execute).and_return(sqlite_magic_response)
      ScraperWiki.select('foo', ['foo', 'bar']).should == sqlite_magic_response
    end

    context 'and no second argument passed' do
      it 'should pass nil to connection as second argument' do
        sql_snippet = 'foo from bar WHERE "baz"=42'
        @dummy_sqlite_magic_connection.should_receive(:execute).with("SELECT #{sql_snippet}", nil)
        ScraperWiki.select(sql_snippet)
      end
    end
  end

  describe '#save_sqlite' do
    before do
      # don't do anything with raw_data by default
      ScraperWiki.stub(:convert_data) { |raw_data| raw_data }
    end

    it 'should save data using :name as unique key' do
      @dummy_sqlite_magic_connection.should_receive(:save_data).with(:unique_keys, anything, anything)
      ScraperWiki.save_sqlite(:unique_keys, :some_data)
    end

    it 'should save convert data before saving' do
      ScraperWiki.should_receive(:convert_data).with(:some_data).and_return(:converted_data)
      @dummy_sqlite_magic_connection.should_receive(:save_data).with(anything, :converted_data, anything)
      ScraperWiki.save_sqlite(:unique_keys, :some_data)
    end

    it 'should save data in swdata by default' do
      @dummy_sqlite_magic_connection.should_receive(:save_data).with(anything, anything, 'swdata')
      ScraperWiki.save_sqlite(:unique_keys, :some_data)
    end

    it 'should save data in given table' do
      @dummy_sqlite_magic_connection.should_receive(:save_data).with(anything, anything, 'another_table')
      ScraperWiki.save_sqlite(:unique_keys, :some_data, 'another_table')
    end

    it 'should return response from connection' do
      @dummy_sqlite_magic_connection.stub(:save_data).and_return(:save_response)
      ScraperWiki.save_sqlite(:unique_keys, :some_data).should == :save_response
    end

    it 'should return response from connection' do
      @dummy_sqlite_magic_connection.stub(:save_data).and_return(:save_response)
      ScraperWiki.save_sqlite(:unique_keys, :some_data).should == :save_response
    end
  end

  describe '#execute' do
    it 'execute query on sqlite_magic_connection' do
      @dummy_sqlite_magic_connection.should_receive(:execute).with(:some_query, :some_data)
      ScraperWiki.sqliteexecute(:some_query, :some_data)
    end

    it 'should return result of execute query' do
      @dummy_sqlite_magic_connection.stub(:execute).and_return(:query_result)
      ScraperWiki.sqliteexecute(:some_query, :some_data).should == :query_result
    end
  end

  describe '#save_var' do
    it 'should save data using :name as unique key' do
      @dummy_sqlite_magic_connection.should_receive(:save_data).with([:name], anything, anything)
      ScraperWiki.save_var(:foo, 'bar')
    end

    it 'should save data as string with data class as :type' do
      @dummy_sqlite_magic_connection.should_receive(:save_data).with(anything, {:name => 'foo', :value_blob => 'bar', :type => 'String'}, anything)
      @dummy_sqlite_magic_connection.should_receive(:save_data).with(anything, {:name => 'meaning_of_life', :value_blob => '42', :type => 'Fixnum'}, anything)
      ScraperWiki.save_var(:foo, 'bar')
      ScraperWiki.save_var(:meaning_of_life, 42)
    end

    it 'should save data in "swvariables"' do
      @dummy_sqlite_magic_connection.should_receive(:save_data).with(anything, anything, "swvariables")
      ScraperWiki.save_var(:foo, 'bar')
    end
  end

  describe '#get_var' do
    it 'should select data using given key' do
      @dummy_sqlite_magic_connection.should_receive(:execute).
                                     with("select value_blob, type from swvariables where name=?", [:foo]).
                                     and_return([{'value_blob' => 'bar', 'type' => 'String'}])
      ScraperWiki.get_var(:foo)
    end

    it 'should return data returned by sqlite_magic_connection' do
      @dummy_sqlite_magic_connection.stub(:execute).
                                     and_return([{'value_blob' => 'bar', 'type' => 'String'}])
      ScraperWiki.get_var(:foo).should == 'bar'
    end

    it 'should cast Fixnum data to integer' do
      @dummy_sqlite_magic_connection.stub(:execute).
                                     and_return([{'value_blob' => '42', 'type' => 'Fixnum'}])
      ScraperWiki.get_var(:foo).should == 42
    end

    it 'should cast Float data to float' do
      @dummy_sqlite_magic_connection.stub(:execute).
                                     and_return([{'value_blob' => '0.234', 'type' => 'Float'}])
      ScraperWiki.get_var(:foo).should == '0.234'.to_f
    end

    it 'should cast Nil data to nil' do
      @dummy_sqlite_magic_connection.stub(:execute).
                                     and_return([{'value_blob' => 'nil', 'type' => 'NilClass'}])
      ScraperWiki.get_var(:foo).should be_nil
    end

    context 'and connection returns empty array' do
      before do
        @dummy_sqlite_magic_connection.stub(:execute).
                                       and_return([])
      end

      it "should return nil" do
        ScraperWiki.get_var(:foo).should be_nil
      end

      it "should return default if default given" do
        ScraperWiki.get_var(:foo, 'bar').should == 'bar'
      end
    end

    context 'and SqliteMagic::NoSuchTable raised' do
      before do
        @dummy_sqlite_magic_connection.stub(:execute).
                                       and_raise(SqliteMagic::NoSuchTable)
      end

      it "should return nil" do
        ScraperWiki.get_var(:foo).should be_nil
      end

      it "should return default if default given" do
        ScraperWiki.get_var(:foo, 'bar').should == 'bar'
      end
    end

    context 'and other error raised' do
      before do
        @dummy_sqlite_magic_connection.stub(:execute).
                                       and_raise
      end

      it "should raise error" do
        lambda { ScraperWiki.get_var(:foo)}.should raise_error
      end
    end
  end

  describe '#close_sqlite' do
    it 'should execute query on sqlite_magic_connection' do
      @dummy_sqlite_magic_connection.should_receive(:close)
      ScraperWiki.close_sqlite
    end

    it 'should lose cached connection' do
      @dummy_sqlite_magic_connection.stub(:close)
      ScraperWiki.close_sqlite
      ScraperWiki.instance_variable_get(:@sqlite_magic_connection).should be_nil
    end
  end

  describe "#save" do
    it "should delegate to #save_sqlite" do
      ScraperWiki.should_receive(:save_sqlite).with(:foo, :bar).and_return(:result)
      ScraperWiki.save(:foo, :bar).should == :result
    end
  end

  describe "#convert_data" do
    it "should return nil if passed nil" do
      ScraperWiki.convert_data(nil).should == nil
    end

    it "should return empty array if passed empty array" do
      ScraperWiki.convert_data([]).should == []
    end

    context 'and passed a hash' do
      it "should return array containing hash if passed hash" do
        ScraperWiki.convert_data({:foo => 'bar'}).should == [{:foo => 'bar'}]
      end

      it "should convert date, time and datetime to iso8601" do
        date = Date.today
        time = Time.now
        datetime = (Time.now - 100).to_datetime
        values_hash = {:foo => 'bar', :date_val => date, :time_val => time, :datetime_val => datetime}
        expected_result = [{:foo => 'bar', :date_val => date.iso8601, :time_val => time.utc.iso8601.sub(/([+-]00:00|Z)$/, ''), :datetime_val => datetime.to_s}]
        ScraperWiki.convert_data(values_hash).should == expected_result
      end
    end

    context 'and passed an array of hashes' do
      it "should return array containing hash if passed hash" do
        ScraperWiki.convert_data([{:foo => 'bar'}, {:bar => 'baz'}]).should == [{:foo => 'bar'}, {:bar => 'baz'}]
      end

      it "should convert date, time and datetime to iso8601" do
        date = Date.today
        time = Time.now
        datetime = (Time.now - 100).to_datetime
        values_array = [{:foo => 'bar', :date_val => date}, {:time_val => time, :datetime_val => datetime}]
        expected_result = [{:foo => 'bar', :date_val => date.iso8601}, {:time_val => time.utc.iso8601.sub(/([+-]00:00|Z)$/,''), :datetime_val => datetime.to_s}]
        ScraperWiki.convert_data(values_array).should == expected_result
      end
    end
  end

end


