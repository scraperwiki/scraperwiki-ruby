# Builds schemas automatically from a hash, for SQLite databases
# 
# Ported from ScraperWiki Classic - scraperwiki/services/datastore/datalib.py
# This will make the code quite unRubyish - it is Julian Todd's Python, ported.

require 'set'
require 'sqlite3'

module SQLiteMagic
  @db = SQLite3::Database.new("scraperwiki.sqlite")
  @sqlitesaveinfo = {}

  def SQLiteMagic._do_save_sqlite(unique_keys, data, swdatatblname)
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

=begin
      if nrecords == 0 && unique_keys.length > 0
        idxname, idxkeys = ssinfo.findclosestindex(unique_keys)
        puts "findclosestindex returned name, keys:", idxname, idxkeys
        if !idxname || idxkeys != unique_keys.to_set
          lres = ssinfo.makenewindex(idxname, unique_keys)
          if lres.include?('error')
            return lres
          end
          res.merge!(lres)
        end
      end
=end

      lres = ssinfo.insertdata(ldata)
      if lres.include?('error')
        return lres
      end
      nrecords += 1
    end

    @db.commit()
    # log(nrecords + " inserted or replaced")
    return res
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
      tblinfo = @db.get_first_value("select count(*) from main.sqlite_master where name=?", @swdatatblname)
      if tblinfo == 0
        return false
      end

      tblinfo = @db.execute("PRAGMA main.table_info(`%s`)" % @swdatatblname)
      puts "tblinfo="+ tblinfo.to_s
        # there's a bug:  PRAGMA main.table_info(swdata) returns the schema for otherdatabase.swdata 
        # following an attach otherdatabase where otherdatabase has a swdata and main does not
      
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
          # used to just add date_scraped in, but without it can't create an empty table
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
      puts "newcols=" + newcols.to_s
      return newcols
    end

    def addnewcolumn(k, vt)
      @db.execute(format("alter table main.`%s` add column `%s` %s", @swdatatblname, k, vt))
    end

=begin
    def findclosestindex(unique_keys)
      idxlist = @db.execute(format("PRAGMA main.index_list(`%s`)", @swdatatblname))  # [seq,name,unique]
      puts "findclosestindex: idxlist is", idxlist
      if idxlist.include?('error')
        return [None, None]
      end
        
      uniqueindexes = [ ]
      for idxel in idxlist["data"]
        if idxel[2]
          idxname = idxel[1]
          idxinfo = @db.execute(format("PRAGMA main.index_info(`%s`)", idxname)) # [seqno,cid,name]
          idxset = idxinfo["data"].map { |a| a[2] }.to_set
          idxoverlap = idxset.intersection(unique_keys).length
          uniqueindexes.push((idxoverlap, idxname, idxset))
        end
      end
      
      if !uniqueindexes
        return [None, None]
      end
      uniqueindexes.sort()
      return [uniqueindexes[-1][1], uniqueindexes[-1][2]]
    end

    # increment to next index number every time there is a change, and add the new index before dropping the old one.
    def makenewindex(idxname, unique_keys)
      istart = 0
      if idxname
        mnum = re.search("(\d+)$", idxname)
        if mnum
          istart = int(mnum.group(1))
        end
      end
      for i in range(10000)
        newidxname = "%s_index%d" % (@swdatatblname, istart+i)
        if not @sqliteexecute("select name from main.sqlite_master where name=?", (newidxname,))['data']
          break
        end
      end
        
      res = { "newindex" => newidxname }
      lres = @db.execute(format("create unique index `%s` on `%s` (%s)", newidxname, @swdatatblname, unique_keys.map { |k| format("`%s`", k) }.join(",")))
      if 'error' in lres  
        return lres
      end
      if idxname
        lres = @db.execute(format("drop index main.`%s`", idxname))
        if 'error' in lres  
          if lres['error'] != 'sqlite3.Error: index associated with UNIQUE or PRIMARY KEY constraint cannot be dropped'
            return lres
          end
        end
        res["droppedindex"] = idxname
      end
      return res
    end
=end

    def insertdata(data)
      values = @swdatakeys.map { |k| data[k] } # this was data.get(k) in Python
      return @db.query(@sqdatatemplate, values)
    end
  end

end


