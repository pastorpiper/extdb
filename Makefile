# this is a example of Makefile
extdb:
	g++ -march=native -shared -m32 -fPIC -pipe -O2 -o extdb.so src/main.cpp src/ext.cpp src/uniqueid.cpp src/rcon.cpp src/protocols/abstract_protocol.cpp src/protocols/misc.cpp src/protocols/db_raw.cpp -lPocoFoundation -lPocoData -lPocoDataODBC -lPocoDataSQLite -lPocoDataMySQL -lPocoNet -lPocoUtil -lPocoXML -lboost_filesystem -lboost_system -lboost_thread -ltbb
	strip ./extdb.so

test:
	g++ -g -march=native -m32 -fPIC -pipe -O2 -o extdb-test src/ext.cpp src/uniqueid.cpp src/rcon.cpp src/protocols/*.cpp -DTESTING -lPocoFoundation -lPocoData -lPocoDataSQLite -lPocoDataMySQL -lPocoDataODBC -lPocoNet -lPocoUtil -lPocoXML -lboost_filesystem -lboost_system -lboost_thread

test-rcon:
	g++ -fpermissive -Wwrite-strings -g -march=native -m32 -fPIC -pipe -o rcon-test src/rcon.cpp -DTESTING_RCON -lPocoFoundation -lPocoNet 
