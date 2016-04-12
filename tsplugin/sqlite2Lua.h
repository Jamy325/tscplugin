//
//  sqlite2Lua.h
//  tsplugin
//
//  Created by Jamy on 16-4-11.
//  Copyright (c) 2016年 Jamy. All rights reserved.
//

#include "json.h"
#import "sqlite3.h"

#ifndef __H_SQLITE2LUA__
#define __H_SQLITE2LUA__
class SqliteDatabase
{
public:
    SqliteDatabase();
    
    //打开数据库
    Json::Value openDB(const char* dbPaht);
    //执行sql语句
    Json::Value executeSqlCmd(const char* sql);
    //关闭数据库
    void closeDB();
    
private:
    sqlite3* _database;
};

#endif
