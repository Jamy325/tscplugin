//
//  tsplugin.m
//  tsplugin
//
//  Created by Jamy on 16-4-11.
//  Copyright (c) 2016年 Jamy. All rights reserved.
//

#import "tsplugin.h"
#import "AlbumHelper.h"


@implementation tsplugin

@end



#include <stdio.h>
#include <stdlib.h>

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIDevice.h>
#import <sqlite3.h>
#include "sqlite2Lua.h"
extern "C" {
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"


/*  库 open 函数的前置声明   */
int luaopen_mt(lua_State *L);
/* Function mt_get_device_name
 * @return string device name
 */
static int mt_get_device_name(lua_State *L)
{
    NSString *name = [[UIDevice currentDevice] name];
    const char * name_str = [name UTF8String];
    lua_pushstring(L, name_str);
    return 1;
}

static int tsp_newDB(lua_State* L)
{
    SqliteDatabase* p = new SqliteDatabase();
    lua_pushlightuserdata(L, p);
    return 1;
}

static int tsp_freeDB(lua_State* L)
{
    if (!lua_islightuserdata(L, 1))
    {
        lua_pushinteger(L, 1);
        return 1;
    }
    
    SqliteDatabase* p = (SqliteDatabase*)lua_touserdata(L, 1);
    delete p;
    lua_pushinteger(L, 0);
    return 1;
}

static int tsp_opendb(lua_State*L)
{
    const char* str = "{\"success\":false,\"msg\":\"invalid arg\"}";
    if (!lua_islightuserdata(L, 1) || !lua_isstring(L, 2))
    {
        lua_pushstring(L, str);
        return 1;
    }
    
    SqliteDatabase* p = (SqliteDatabase*)lua_touserdata(L, 1);
    const char* dbPath = lua_tostring(L, 2);
    if (!p || strcmp(dbPath, "") == 0)
    {
        lua_pushstring(L, str);
        return 1;
    }
    
    Json::Value result = p->openDB(dbPath);
    Json::FastWriter w;
    lua_pushstring(L, w.write(result).c_str());
    return 1;
}

static int tsp_executeSql(lua_State*L)
{
    const char* str = "{\"success\":false,\"msg\":\"invalid arg\"}";
    if (!lua_islightuserdata(L, 1) || !lua_isstring(L, 2))
    {
        lua_pushstring(L, str);
        return 1;
    }
    
    SqliteDatabase* p = (SqliteDatabase*)lua_touserdata(L, 1);
    const char* sql = lua_tostring(L, 2);
    if (!p || strcmp(sql, "") == 0)
    {
        lua_pushstring(L, str);
        return 1;
    }
    
    Json::Value result = p->executeSqlCmd(sql);
    Json::FastWriter w;
    lua_pushstring(L, w.write(result).c_str());
    return 1;
}


static int tsp_closeDB(lua_State*L)
{
    if (!lua_islightuserdata(L, 1) )
    {
        return 0;
    }
    
    SqliteDatabase* p = (SqliteDatabase*)lua_touserdata(L, 1);
    if (!p)
    {
        return 0;
    }
    
    p->closeDB();
    return 0;
}
    
    
static int tsp_createAlbum(lua_State* L)
{
    const char* str = "{\"success\":false, \"msg\":\"invalid arg\"}";
    if (!lua_isstring(L, 1))
    {
        lua_pushstring(L, str);
        return 1;
    }
    
    const char* strAlbume = lua_tostring(L, 1);
    
    NSString* albume = [NSString stringWithUTF8String:strAlbume];
    [AlbumHelper createAlbum:albume];

    lua_pushstring(L, "{\"success\":true}");
    return 1;
}
    
    
static int tsp_saveImageToCustomeAlbume(lua_State* L)
{
    const char* str = "{\"success\":false,\"msg\":\"invalid arg\"}";
    if (!lua_isstring(L, 1) || !lua_isstring(L, 2))
    {
        lua_pushstring(L, str);
        return 1;
    }
    
    const char* strImgPath = lua_tostring(L, 1);
    const char* strAblume = lua_tostring(L, 2);
    
    [AlbumHelper saveImageToCustomeAlbume:[NSString stringWithUTF8String:strImgPath] albume:[NSString stringWithUTF8String:strAblume]];
    
    lua_pushstring(L, "{\"success\":true}");
    return 1;
}
    
    
    
static int tsp_removeAllImageInAblume(lua_State* L)
{
    const char* str = "{\"success\":false, \"msg\":\"invalid arg\"}";
    if (!lua_isstring(L, 1))
    {
        lua_pushstring(L, str);
        return 1;
    }
    
    const char* strAlbume = lua_tostring(L, 1);
    NSString* albume = [NSString stringWithUTF8String:strAlbume];
    [AlbumHelper removeAllImageInAblume:albume];
    
    lua_pushstring(L, "{\"success\":true}");
    return 1;
}
    

//注册函数库
static const luaL_Reg mt_lib[] = {
    {"device_name", mt_get_device_name},    //获取设备名称
    {"newDB", tsp_newDB},    //获取设备名称
    {"freeDB", tsp_freeDB},    //获取设备名称
    {"openDB",  tsp_opendb},    //获取设备名称
    {"executeSql",  tsp_executeSql},    //获取设备名称
    {"closeDB",  tsp_closeDB},    //获取设备名称
    {"createAlbum", tsp_createAlbum},//创建自定义相册
    {"saveImageToCustomeAlbume", tsp_saveImageToCustomeAlbume},//保存图片到相册里
    {"removeAllImageInAblume", tsp_removeAllImageInAblume},//清空相册
    {NULL, NULL}
};


int luaopen_tsplugin(lua_State *L)//注意, mt为扩展库的文件名
{
    luaL_newlib(L, mt_lib);//暴露给lua脚本的接口
    return 1;
}

}
