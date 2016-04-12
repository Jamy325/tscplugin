//
//  sqlite2Lua.cpp
//  tsplugin
//
//  Created by Jamy on 16-4-11.
//  Copyright (c) 2016年 Jamy. All rights reserved.
//
#include "sqlite2Lua.h"


static int sqliteCallback(void* arg, int argc, char** argv, char** azColName)
{
    Json::Value* p = (Json::Value*)arg;
    Json::Value data;
    for (int i = 0; i < argc; ++i)
    {
        Json::Value obj;
        data[azColName[i]] = argv[i];
    }
    
    (*p)["result"].append(data);
    
    return 0;
}


SqliteDatabase::SqliteDatabase() : _database(nullptr)
{
    closeDB();
}


/**
    打开数据库
 */
Json::Value SqliteDatabase::openDB(const char *dbPath)
{
    Json::Value ret;
    int rc = sqlite3_open(dbPath, &_database);
    if (rc)
    {
        ret["success"] = false;
        ret["msg"] = "open db fail";
        return ret;
    }
    
    ret["success"] = true;
    return ret;
}


Json::Value SqliteDatabase::executeSqlCmd(const char *sql)
{
    Json::Value ret;
    if (!_database)
    {
        ret["success"] = false;
        ret["msg"] = "database not open";
        return ret;
    }
    
    char* error = NULL;
    int rc = sqlite3_exec(_database, sql, sqliteCallback, (void*)&ret, &error);
    
    if (rc != SQLITE_OK)
    {
        ret["success"] = false;
        ret["msg"] = error;
        free(error);
        return ret;
    }
    
    return ret;
}


void SqliteDatabase::closeDB()
{
    if (_database)
    {
        sqlite3_close(_database);
        _database = NULL;
        return;
    }
}












