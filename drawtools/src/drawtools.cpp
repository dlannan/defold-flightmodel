


// drawtools.cpp
// Extension lib defines
#define LIB_NAME "DrawTools"
#define MODULE_NAME "drawtools"

#include <stdio.h>
#include <vector>

// include the Defold SDK
#include <dmsdk/sdk.h>

typedef struct linePoint {
    float x;
    float y;
    float z;
    linePoint(float _x, float _y, float _z):x(_x),y(_y),z(_z){}
} _linePoint;

typedef struct lineType {
    unsigned int     color;
    float            width;
    std::vector<linePoint>   line;
} _libeType;

static std::vector<lineType *>   g_lines;

static int NewLineObject(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 1);

    unsigned int col = (unsigned int)luaL_checknumber(L, 1);
    float w = (float)luaL_checknumber(L, 2);
   
    lineType  *line = new lineType();
    line->width = w;
    line->color = col;
    
    g_lines.push_back(line);
    lua_pushnumber(L, g_lines.size() -1);
    return 1;
}

static int DeleteLine(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    int lineid = (int)luaL_checknumber(L, 1);
    lineType *line = g_lines[lineid];
    if(line) delete line;
    g_lines[lineid] = nullptr;        
    return 0;
}

static int AddPoint(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 1);
    int lineid = (int)luaL_checknumber(L, 1);
    float x1 = (float)luaL_checknumber(L, 2);
    float y1 = (float)luaL_checknumber(L, 3);
    float z1 = (float)luaL_checknumber(L, 4);
    lineType *line = g_lines[lineid];
    line->line.push_back( linePoint(x1, y1, z1 ) );

    lua_pushnumber(L, line->line.size()-1);
    return 1;
}

static int SetPoint(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    int lineid = (int)luaL_checknumber(L, 1);
    int pointid = (int)luaL_checknumber(L, 2);
    float x1 = (float)luaL_checknumber(L, 3);
    float y1 = (float)luaL_checknumber(L, 4);
    float z1 = (float)luaL_checknumber(L, 5);

    lineType *line = g_lines[lineid];
    line->line[pointid] = linePoint(x1, y1, z1 );

    return 0;
}

void DrawLineInternal(int lineid)
{
    lineType *line = g_lines[lineid];

    //glLineWidth(line->width);
    glBegin(GL_LINES);
    glColor4ubv( (GLubyte *)&line->color );
    for(int i=0; i<line->line.size(); i++)
    {
        linePoint pt = line->line[i];
        glVertex3f(pt.x, pt.y, pt.z);
    }
    glEnd();
}

static int DrawLine(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 0);

    int lineid = (int)luaL_checknumber(L, 1);
    DrawLineInternal(lineid);
    return 0;
}

static int DrawAllLines(lua_State* L)
{
    // The number of expected items to be on the Lua stack
    // once this struct goes out of scope
    DM_LUA_STACK_CHECK(L, 0);
    for(int i=0; i<g_lines.size(); i++)
    {
        if(g_lines[i]) DrawLineInternal(i);
    }
    return 0;
}

// Functions exposed to Lua
static const luaL_reg Module_methods[] =
{
    {"newline",       NewLineObject},
    {"addpoint",      AddPoint},
    {"setpoint",      SetPoint},
    {"delline",       DeleteLine}, 
    {"drawline",      DrawLine},
    {"drawalllines",  DrawAllLines},
    {0, 0}
};

static void LuaInit(lua_State* L)
{
    int top = lua_gettop(L);

    // Register lua names
    luaL_register(L, MODULE_NAME, Module_methods);

    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

dmExtension::Result AppInitializeDrawTools(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result InitializeDrawTools(dmExtension::Params* params)
{
    // Init Lua
    LuaInit(params->m_L);
    printf("Registered %s Extension\n", MODULE_NAME);
    return dmExtension::RESULT_OK;
}

dmExtension::Result AppFinalizeDrawTools(dmExtension::AppParams* params)
{
    return dmExtension::RESULT_OK;
}

dmExtension::Result FinalizeDrawTools(dmExtension::Params* params)
{
    for(int i=0; i<g_lines.size(); i++)
        delete g_lines[i];
    return dmExtension::RESULT_OK;
}


// Defold SDK uses a macro for setting up extension entry points:
//
// DM_DECLARE_EXTENSION(symbol, name, app_init, app_final, init, update, on_event, final)

// DrawTools is the C++ symbol that holds all relevant extension data.
// It must match the name field in the `ext.manifest`
DM_DECLARE_EXTENSION(DrawTools, LIB_NAME, AppInitializeDrawTools, AppFinalizeDrawTools, InitializeDrawTools, 0, 0, FinalizeDrawTools)
