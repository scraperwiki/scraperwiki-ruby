# Builds schemas automatically from a hash, for SQLite databases
# 
# Ported from ScraperWiki Classic - scraperwiki/services/datastore/datalib.py
# This will make the code quite unRubyish - it is Julian Todd's Python, ported.


# TODO:
# Sort out 'error' bits

require 'set'
require 'sqlite3'

module SQLiteMagic
  @db = nil
  @sqlitesaveinfo = {}

  def SQLiteMagic._open_db_if_necessary()
    if @db.nil?
      @db = SQLite3::Database.new("scraperwiki.sqlite")
    end
  end

  def SQLiteMagic._do_save_sqlite(unique_keys, data, swdatatblname)
    SQLiteMagic._open_db_if_necessary

    res = { }
    if data.class == Hash
      data = [data]
    end

    if !@sqlitesaveinfo.include?(swdatatblname)
      ssinfo = SqliteSaveInfo.new(swdatatblname, @db)
      @sqlitesaveinfo[swdatatblname] = ssinfo
      if not ssinfo.rebuildinfo() and data.length > 0
        ssinfo.buildinitialtable(data[0])
        ssinfo.rebuildinfo()
        res["tablecreated"] = swdatatblname
      end
    else
      ssinfo = @sqlitesaveinfo[swdatatblname]
    end

    @db.transaction()

    nrecords = 0
    data.each do |ldata|
      newcols = ssinfo.newcolumns(ldata)
      if newcols.length > 0
        newcols.each_with_index do |kv, i|
          ssinfo.addnewcolumn(kv[0], kv[1])
          res["newcolumn %d" % i] = "%s %s" % kv
        end
        ssinfo.rebuildinfo()
      end

      if nrecords == 0 && unique_keys.length > 0
        idxname, idxkeys = ssinfo.findclosestindex(unique_keys)
        # puts "findclosestindex returned name:"+ idxname.to_s + " keys:" + idxkeys.to_s
        if !idxname || idxkeys != unique_keys.to_set
          lres = ssinfo.makenewindex(idxname, unique_keys)
          if lres.include?('error')
            return lres
          end
          res.merge!(lres)
        end
      end

      lres = ssinfo.insertdata(ldata)
      nrecords += 1
    end

    @db.commit()
    # log(nrecords + " inserted or replaced")
    return res
  end

  def SQLiteMagic.sqliteexecute(query,data=nil, verbose=2)
    SQLiteMagic._open_db_if_necessary
    cols,*rows = (data.nil?)? @db.execute2(query) : @db.execute2(query,data)
    return {"keys"=>cols, "data"=>rows} unless cols.nil? or rows.nil?
  end

  def SQLiteMagic.close()
    @db.close
    @db = nil
    @sqlitesaveinfo = {}
  end


  class SqliteSaveInfo
    def initialize(swdatatblname, db)
      @swdatatblname = swdatatblname
      @swdatakeys = [ ]
      @swdatatypes = [  ]
      @sqdatatemplate = "" 
      @db = db
    end

    def rebuildinfo()
      does_exist = @db.get_first_value("select count(*) from main.sqlite_master where name=?", @swdatatblname)
      if does_exist == 0
        return false
      end

      tblinfo = @db.execute("PRAGMA main.table_info(`%s`)" % @swdatatblname)
      # puts "tblinfo="+ tblinfo.to_s
      
      @swdatakeys = tblinfo.map { |a| a[1] }
      @swdatatypes = tblinfo.map { |a| a[2] }
      @sqdatatemplate = format("insert or replace into main.`%s` values (%s)", @swdatatblname, (["?"]*@swdatakeys.length).join(","))
      return true
    end
    
        
    def buildinitialtable(data)
      raise "buildinitialtable: no swdatakeys" unless @swdatakeys.length == 0
      coldef = self.newcolumns(data)
      raise "buildinitialtable: no coldef" unless coldef.length > 0
      # coldef = coldef[:1]  # just put one column in; the rest could be altered -- to prove it's good
      scoldef = coldef.map { |col| format("`%s` %s", col[0], col[1]) }.join(",")
      @db.execute(format("create table main.`%s` (%s)", @swdatatblname, scoldef))
    end
    
    def newcolumns(data)
      newcols = [ ]
      for k, v in data
        if !@swdatakeys.include?(k)
          if v != nil
            #if k[-5:] == "_blob"
            #  vt = "blob"  # coerced into affinity none
            if v.class == Fixnum
              vt = "integer"
            elsif v.class == Float
              vt = "real"
            else
              vt = "text"
            end
            newcols.push([k, vt])
          end
        end
      end
      # puts "newcols=" + newcols.to_s
      return newcols
    end

    def addnewcolumn(k, vt)
      @db.execute(format("alter table main.`%s` add column `%s` %s", @swdatatblname, k, vt))
    end

    def findclosestindex(unique_keys)
      idxlist = @db.execute(format("PRAGMA main.index_list(`%s`)", @swdatatblname))  # [seq,name,unique]
      # puts "findclosestindex: idxlist is "+ idxlist.to_s
      if idxlist.include?('error')
        return [nil, nil]
      end
        
      uniqueindexes = [ ]
      for idxel in idxlist
        if idxel[2]
          idxname = idxel[1]
          idxinfo = @db.execute(format("PRAGMA main.index_info(`%s`)", idxname)) # [seqno,cid,name]
          idxset = idxinfo.map { |a| a[2] }.to_set
          idxoverlap = idxset.intersection(unique_keys).length
          uniqueindexes.push([idxoverlap, idxname, idxset])
        end
      end
      
      if uniqueindexes.length == 0
        return [nil, nil]
      end
      uniqueindexes.sort()
      # puts "uniqueindexes=" + uniqueindexes.to_s
      return [uniqueindexes[-1][1], uniqueindexes[-1][2]]
    end

    # increment to next index number every time there is a change, and add the new index before dropping the old one.
    def makenewindex(idxname, unique_keys)
      istart = 0
      if idxname
        #mnum = re.search("(\d+)$", idxname)
        #if mnum
        #  istart = int(mnum.group(1))
        #end
        istart = idxname.match("(\d+)$").first.to_i rescue 0
      end
      for i in 0..10000
        newidxname = format("%s_index%d", @swdatatblname, istart+i)
        does_exist = @db.get_first_value("select count(*) from main.sqlite_master where name=?", newidxname)
        if does_exist == 0
          break
        end
      end
        
      res = { "newindex" => newidxname }
      lres = @db.execute(format("create unique index `%s` on `%s` (%s)", newidxname, @swdatatblname, unique_keys.map { |k| format("`%s`", k) }.join(",")))
      if lres.include?('error')
        return lres
      end
      if idxname
        lres = @db.execute(format("drop index main.`%s`", idxname))
        if lres.include?('error')
          if lres['error'] != 'sqlite3.Error: index associated with UNIQUE or PRIMARY KEY constraint cannot be dropped'
            return lres
          end
        end
        res["droppedindex"] = idxname
      end
      return res
    end

    def insertdata(data)
      values = @swdatakeys.map { |k| data[k] } 
      res = @db.query(@sqdatatemplate, values)
      res.close
    end
  end

end


