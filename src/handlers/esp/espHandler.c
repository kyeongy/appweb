/*
    espHandler.c -- Embedded Server Pages (ESP) handler. Fast in-process replacement for CGI.

    Copyright (c) All Rights Reserved. See copyright notice at the bottom of the file.
 */

/********************************** Includes **********************************/

#include    "appweb.h"

#if BLD_FEATURE_ESP
#include    "esp.h"
//  MOB - does esp require pcre?
#include    "pcre.h"

/************************************* Local **********************************/
/*
    Singleton ESP control structure
 */
static Esp *esp;

/************************************ Forward *********************************/
static EspLoc *allocEspLoc(HttpLoc *loc);
static bool moduleIsCurrent(HttpConn *conn, cchar *source, cchar *module);
static bool fetchCachedResponse(HttpConn *conn);
static void manageAction(EspAction *cp, int flags);
static void manageEsp(Esp *esp, int flags);
static void manageReq(EspReq *req, int flags);
static int  runAction(HttpConn *conn);
static void runView(HttpConn *conn);
static void saveCachedResponse(HttpConn *conn);

/************************************* Code ***********************************/

static void openEsp(HttpQueue *q)
{
    HttpConn    *conn;
    HttpAlias   *alias;
    HttpRx      *rx;
    EspReq      *req;
    char        *uri;

    conn = q->conn;
    rx = conn->rx;

    if ((req = mprAllocObj(EspReq, manageReq)) == 0) {
        httpMemoryError(conn);
        return;
    }
    req->loc = rx->loc;
    req->esp = esp;
    conn->data = req;
    req->autoFinalize = 1;
    if ((req->el = httpGetLocationData(rx->loc, ESP_NAME)) == 0) {
        req->el = allocEspLoc(rx->loc);
    }
    mprAssert(req->el);

    /*
        Set the scriptName to the alias prefix and remove from pathInfo
     */
    rx = conn->rx;
    uri = rx->pathInfo;
    alias = rx->alias;
    if (alias->prefixLen > 0) {
        uri = &uri[alias->prefixLen];
#if UNUSED
        if (uri > rx->pathInfo && *uri != '/' && uri[-1] == '/') {
            uri--;
        }
#endif
        if (*uri == '\0') {
            uri = "/";
        }
        rx->scriptName = alias->prefix;
        rx->pathInfo = sclone(uri);
        mprLog(5, "esp: set script name: \"%s\", pathInfo: \"%s\"", rx->scriptName, rx->pathInfo);
    }
}


static void startEsp(HttpQueue *q)
{
    HttpConn        *conn;
    EspLoc          *el;
    EspReq          *req;
    EspRoute        *route;
    char            *actionKey;
    int             next;

    conn = q->conn;
    req = conn->data;
    el = req->el;

    if (conn->error) {
        //  MOB - is this required?
        return;
    }
    for (next = 0; (route = mprGetNextItem(el->routes, &next)) != 0; ) {
        if ((actionKey = espMatchRoute(conn, route)) != 0) {
            break;
        }
    }
    if (route == 0) {
        httpError(conn, HTTP_CODE_INTERNAL_SERVER_ERROR, "No route to serve request");
        return;
    }
    req->route = route;
    req->actionKey = actionKey;
    req->action = mprLookupKey(esp->actions, actionKey);
    mprLog(4, "Using route: %s for %s, actionKey %s", route->name, conn->rx->pathInfo, actionKey);

    httpAddFormVars(conn);
#if FUTURE
    espSetConn(conn);
        mprSetThreadData(el->tls, conn);
        //  MOB - better to use
#endif
    if (route->controllerName && !runAction(conn)) {
        return;
    }
    if (!conn->tx->responded && req->autoFinalize) {
        runView(conn);
    }
    if (req->autoFinalize && !req->finalized) {
        espFinalize(conn);
    }
    if (req->cacheBuffer) {
        saveCachedResponse(conn);
    }
}


static char *makeCacheKey(HttpConn *conn, cchar *actionKey, cchar *uri)
{
    EspReq      *req;
    HttpQueue   *q;
    char        *path, *form, *key;

    req = conn->data;
    q = conn->readq;

    path = mprJoinPath(req->el->controllersDir, actionKey);
    if (uri) {
        form = httpGetFormData(conn);
        key = sfmt("content-%s:%s?%s", req->el->controllersDir, uri, form);
        
    } else {
        key = sfmt("content-%s", mprJoinPath(req->el->controllersDir, actionKey));
    }
    return key;
}


static bool fetchCachedResponse(HttpConn *conn)
{
    EspReq  *req;
    char    *content, *extraUri, *key;

    req = conn->data;
    if (req->action && req->action->lifespan) {
        extraUri = req->action ? req->action->uri : 0;
        if (extraUri && scmp(extraUri, "*") == 0) {
            extraUri = conn->rx->pathInfo;
        }
        key = makeCacheKey(conn, req->actionKey, extraUri);
        if ((content = mprReadCache(esp->cache, key, 0)) != 0) {
#if 0
            if (!extraUri) {
    struct tm tm;
    MprTime when;
    int     status;
            /*
                Observe headers
                If-None-Match: "ec18d-54-4d706a63"
                If-Modified-Since: Fri, 04 Mar 2011 04:28:19 GMT
             */
            status = HTTP_CODE_OK;;
            if ((value = httpGetHeader(conn, "If-None-Match")) != 0 && scmp(value, item.tag) == 0) {
                /* 
                    RFC2616 requires returning PrecondFailed, but chrome doesn't send an If-Modified-Since header 
                    and so returning PrecondFailed caused Chrome to fail.

                    status = HTTP_CODE_PRECOND_FAILED;
                 */
                status = HTTP_CODE_NOT_MODIFIED;
            }
            if ((value = httpGetHeader(conn, "If-Modified-Since")) != 0) {
                mprParseTime(&when, value, 0, 0);
                if (item.modified <= when) {
                    status = HTTP_CODE_NOT_MODIFIED;
                }
            }
            mprDecodeUniversalTime(&tm, item.modified);
            httpSetHeader(conn, "Last-Modified, mprFormatTime(MPR_HTTP_DATE, &tm));
            httpSetHeader(conn, "Etag, mprGetMD5Hash(cacheName), slen(cacheName)", 0));
            if (status == HTTP_CODE_OK) {
                espWriteString(conn, content);
            }
            httpSetStatus(conn, status);
#else
            espWriteString(conn, content);
#endif
            return 1;
        }
    }
    return 0;
}


static void saveCachedResponse(HttpConn *conn)
{
    EspReq      *req;
    EspAction   *action;
    MprBuf      *buf;
    char        *key, *extraUri;

    req = conn->data;
    if (req->finalized) {
        buf = req->cacheBuffer;
        req->cacheBuffer = 0;
        mprAddNullToBuf(buf);
        action = req->action;
        extraUri = req->action->uri;
        if (action->uri && scmp(action->uri, "*") == 0) {
            extraUri = conn->rx->pathInfo;
        }
        key = makeCacheKey(conn, req->actionKey, extraUri);
        mprWriteCache(esp->cache, key, mprGetBufStart(buf), action->lifespan, 0, 0);
        espWriteBlock(conn, mprGetBufStart(buf), mprGetBufLength(buf));
        espFinalize(conn);
    }
}


void espUpdateCache(HttpConn *conn, cchar *actionKey, cchar *data, int lifesecs, cchar *uri)
{
    mprWriteCache(esp->cache, makeCacheKey(conn, actionKey, uri), data, lifesecs * MPR_TICKS_PER_SEC, 0, 00);
}


bool espWriteCached(HttpConn *conn, cchar *actionKey, cchar *uri)
{
    cchar   *content;

    if ((content = mprReadCache(esp->cache, makeCacheKey(conn, actionKey, uri), 0)) == 0) {
        return 0;
    }
    espWriteString(conn, content);
    return 1;
}


static char *getControllerEntry(cchar *controllerName)
{
    char    *cp, *entry;

    entry = sfmt("espInit_controller_%s", mprTrimPathExtension(mprGetPathBase(controllerName)));
    for (cp = entry; *cp; cp++) {
        if (!isalnum((int) *cp) && *cp != '_') {
            *cp = '_';
        }
    }
    return entry;
}


static int runAction(HttpConn *conn)
{
    MprModule   *mp;
    EspLoc      *el;
    EspReq      *req;
    EspRoute    *route;
    EspAction   *action;
    char        *key, *name, *entry;
    int         updated;

    req = conn->data;
    el = req->el;
    route = req->route;
    updated = 0;

    /*
        Expand any form var $tokens. This permits ${controller} and user form data to be used in the controller name
     */
    if (schr(route->controllerName, '$')) {
        route->controllerName = stemplate(route->controllerName, conn->rx->formVars);
    }
    route->controllerPath = mprJoinPath(el->controllersDir, route->controllerName);
    req->cacheName = mprGetMD5Hash(route->controllerPath, slen(route->controllerPath), "controller_");
    req->module = mprGetNormalizedPath(sfmt("%s/%s%s", el->cacheDir, req->cacheName, BLD_SHOBJ));

    if (el->update) {
        if (!mprPathExists(route->controllerPath, R_OK)) {
            httpError(conn, HTTP_CODE_INTERNAL_SERVER_ERROR, "Can't find controller %s", route->controllerPath);
            return 0;
        }
        if (!moduleIsCurrent(conn, route->controllerPath, req->module)) {
            /* Modules are named by source to aid debugging */
            if ((mp = mprLookupModule(route->controllerPath)) != 0) {
                //  What if some modules cant be unloaded?
                //  MOB - must complete all other running requests first
                mprUnloadModule(mp);
            }
            //  WARNING: GC yield here
            if (!espCompile(conn, route->controllerPath, req->module, req->cacheName, 0)) {
                return 0;
            }
        }
        if (mprLookupModule(route->controllerPath) == 0) {
            req->entry = getControllerEntry(route->controllerName);
            //  MOB - who keeps reference to module?
            if ((mp = mprCreateModule(route->controllerPath, req->module, req->entry, el)) == 0) {
                httpMemoryError(conn);
                return 0;
            }
            //  MOB - this should return an error msg
            if (mprLoadModule(mp) < 0) {
                httpError(conn, HTTP_CODE_INTERNAL_SERVER_ERROR, 
                    "Can't load compiled esp module for %s", route->controllerPath);
                return 0;
            }
            updated = 1;
        }

    } else if (el->app) {
        name = mprJoinPath(el->cacheDir, el->app);
        if (mprLookupModule(name) == 0) {
            entry = sfmt("espInit_app_%s", mprGetPathBase(el->dir));
            if ((mp = mprCreateModule(name, el->app, entry, el)) == 0) {
                httpMemoryError(conn);
                return 0;
            }
            if (mprLoadModule(mp) < 0) {
                httpError(conn, HTTP_CODE_INTERNAL_SERVER_ERROR, "Can't load compiled esp module for %s", name);
                return 0;
            }
        }
    }
    key = mprJoinPath(el->controllersDir, req->actionKey);
    if ((action = mprLookupKey(esp->actions, key)) == 0) {
        key = sfmt("%s/%s-missing", route->controllerPath, mprTrimPathExtension(route->controllerName));
        if ((action = mprLookupKey(esp->actions, key)) == 0) {
            if ((action = mprLookupKey(esp->actions, "missing")) == 0) {
                httpError(conn, HTTP_CODE_INTERNAL_SERVER_ERROR, "Missing action for %s", req->actionKey);
                return 0;
            }
        }
    }
    req->action = action;
    
    if (el->lifespan) {
        /* Must stabilize form data prior to controllers injecting variables */
        httpGetFormData(conn);
        if (!updated && fetchCachedResponse(conn)) {
            return 1;
        }
        req->cacheBuffer = mprCreateBuf(-1, -1);
    }
    if (action->actionFn) {
        (action->actionFn)(conn);
        return 1;
    }
    return 0;
}


static void runView(HttpConn *conn)
{
    MprModule   *mp;
    EspLoc      *el;
    EspReq      *req;
    EspRoute    *route;
    EspViewFn   view;
    
    req = conn->data;
    el = req->el;
    route = req->route;
    
    if (route->controllerName) {
        req->view = mprJoinPath(el->viewsDir, req->actionKey);
    } else {
        req->view = mprJoinPath(conn->host->documentRoot, req->actionKey);
    }
    req->source = mprJoinPathExt(req->view, ".esp");
    req->cacheName = mprGetMD5Hash(req->source, slen(req->source), "view_");
    req->module = mprGetNormalizedPath(sfmt("%s/%s%s", req->el->cacheDir, req->cacheName, BLD_SHOBJ));

    if (el->update) {
        if (!mprPathExists(req->source, R_OK)) {
            httpError(conn, HTTP_CODE_INTERNAL_SERVER_ERROR, "Can't find view %s", req->source);
            return;
        }
        if (!moduleIsCurrent(conn, req->source, req->module)) {
            /* Modules are named by source to aid debugging */
            if ((mp = mprLookupModule(req->source)) != 0) {
                //  What if some modules cant be unloaded?
                //  MOB - must complete all other running requests first
                mprUnloadModule(mp);
            }
            //  WARNING: this will allow GC
            if (!espCompile(conn, req->source, req->module, req->cacheName, 1)) {
                return;
            }
        }
        if (mprLookupModule(req->source) == 0) {
            req->entry = sfmt("espInit_%s", req->cacheName);
            //  MOB - who keeps reference to module?
            if ((mp = mprCreateModule(req->source, req->module, req->entry, el)) == 0) {
                httpMemoryError(conn);
                return;
            }
            //  MOB - this should return an error msg
            if (mprLoadModule(mp) < 0) {
                httpError(conn, HTTP_CODE_INTERNAL_SERVER_ERROR, "Can't load compiled esp module for %s", req->source);
                return;
            }
        }
    }
    if ((view = mprLookupKey(esp->views, mprGetPortablePath(req->source))) == 0) {
        httpError(conn, HTTP_CODE_INTERNAL_SERVER_ERROR, "Can't find defined view for %s", req->view);
        return;
    }
	httpAddHeaderString(conn, "Content-Type", "text/html");
    (view)(conn);
}


static bool moduleIsCurrent(HttpConn *conn, cchar *source, cchar *module)
{
    EspReq      *req;
    MprPath     sinfo, minfo;

    req = conn->data;
    if (mprPathExists(module, R_OK)) {
        mprGetPathInfo(source, &sinfo);
        mprGetPathInfo(module, &minfo);
        //  MOB - also want a universal touch to rebuild all. Touch appweb.conf
        /* The loaded module is named by source to aid debugging */
        if (sinfo.mtime < minfo.mtime) {
            return 1;
        }
    }
    return 0;
}


void espCacheControl(EspLoc *el, cchar *actionKey, int lifesecs, cchar *uri)
{
    EspAction  *action;
    
    if ((action = mprLookupKey(esp->actions, mprJoinPath(el->controllersDir, actionKey))) == 0) {
        if ((action = mprAllocObj(EspAction, manageAction)) == 0) {
            return;
        }
    }
    if (uri) {
        action->uri = sclone(uri);
    }
    if (lifesecs == 0) {
        action->lifespan = el->lifespan;
    } else {
        action->lifespan = lifesecs * MPR_TICKS_PER_SEC;
    }
}


void espDefineAction(EspLoc *el, cchar *actionKey, void *actionFn)
{
    EspAction   *action;

    mprAssert(el);
    mprAssert(actionKey && *actionKey);
    mprAssert(actionFn);

    if ((action = mprAllocObj(EspAction, manageAction)) == 0) {
        return;
    }
    action->actionFn = actionFn;
    mprAddKey(esp->actions, mprJoinPath(el->controllersDir, actionKey), action);
}


/*
    Path should be an app-relative path to the view file (relative-path.esp)
 */
void espDefineView(EspLoc *el, cchar *path, void *view)
{
    mprAssert(el);
    mprAssert(path && *path);
    mprAssert(view);

	path = mprGetPortablePath(mprJoinPath(el->dir, path));
    mprAddKey(esp->views, path, view);
}


static EspLoc *allocEspLoc(HttpLoc *loc)
{
    EspLoc  *el;

    if ((el = mprAllocObj(EspLoc, espManageEspLoc)) == 0) {
        return 0;
    }
    httpSetLocationData(loc, ESP_NAME, el);
    if ((el->routes = mprCreateList(-1, 0)) == 0) {
        return 0;
    }
#if UNUSED
    if ((esp->actions = mprCreateHash(-1, MPR_HASH_STATIC_VALUES)) == 0) {
        return 0;
    }
    if ((esp->views = mprCreateHash(-1, MPR_HASH_STATIC_VALUES)) == 0) {
        return 0;
    }
#endif
#if FUTURE
    //  MOB - only do this where required
    if ((el->tls = mprCreateThreadLocal()) == 0) {
        return 0;
    }
#endif
    el->dir = mprGetAbsPath((loc->alias) ? loc->alias->filename : loc->host->serverRoot);
    el->controllersDir = el->dir;
    el->databasesDir = el->dir;
    el->layoutsDir = el->dir;
    el->modelsDir = el->dir;
    el->viewsDir = el->dir;
    el->staticDir = el->dir;

    /*
        Setup default parameters for $expansion of Http location paths
     */
    httpAddLocationToken(loc, "CONTROLLERS_DIR", el->controllersDir);
    httpAddLocationToken(loc, "DATABASES_DIR", el->databasesDir);
    httpAddLocationToken(loc, "LAYOUTS_DIR", el->layoutsDir);
    httpAddLocationToken(loc, "MODELS_DIR", el->modelsDir);
    httpAddLocationToken(loc, "STATIC_DIR", el->staticDir);
    httpAddLocationToken(loc, "VIEWS_DIR", el->viewsDir);

#if DEBUG_IDE
    el->cacheDir = mprGetAppDir();
#else
    el->cacheDir = mprJoinPath(mprGetAppDir(), "../" BLD_LIB_NAME);
#endif

    el->lifespan = ESP_LIFESPAN;
    el->keepSource = 0;
#if BLD_DEBUG
	el->update = 1;
	el->showErrors = 1;
#endif
    el->loc = loc;
    return el;
}


static EspLoc *cloneEspLoc(EspLoc *parent, HttpLoc *loc)
{
    EspLoc      *el;
    
    mprAssert(parent);
    mprAssert(loc);

    if ((el = mprAllocObj(EspLoc, espManageEspLoc)) == 0) {
        return 0;
    }
    httpSetLocationData(loc, ESP_NAME, el);
    el->loc = loc;
    el->update = parent->update;
    el->keepSource = parent->keepSource;
    el->showErrors = parent->showErrors;
    el->lifespan = parent->lifespan;
    if (parent->compile) {
        el->compile = sclone(parent->compile);
    }
    if (parent->link) {
        el->link = sclone(parent->link);
    }
    if (parent->env) {
        el->env = mprCloneList(parent->env);
    }
    if (parent->routes) {
        el->routes = mprCloneList(parent->routes);
    } else {
        el->routes = mprCreateList(-1, 0);
    }
    el->dir = parent->dir;
    el->cacheDir = parent->cacheDir;
    el->controllersDir = parent->controllersDir;
    el->databasesDir = parent->databasesDir;
    el->layoutsDir = parent->layoutsDir;
    el->modelsDir = parent->modelsDir;
    el->viewsDir = parent->viewsDir;
    el->staticDir = parent->staticDir;

    if (mprHasMemError()) {
        return 0;
    }
    return el;
}


static void setMvcDirs(EspLoc *el)
{
    el->cacheDir = mprJoinPath(el->dir, "cache");
    httpAddLocationToken(el->loc, "CACHE_DIR", el->cacheDir);

    el->controllersDir = mprJoinPath(el->dir, "controllers");
    httpAddLocationToken(el->loc, "CONTROLLERS_DIR", el->controllersDir);

    el->databasesDir = mprJoinPath(el->dir, "databases");
    httpAddLocationToken(el->loc, "DATABASES_DIR", el->databasesDir);

    el->layoutsDir  = mprJoinPath(el->dir, "layouts");
    httpAddLocationToken(el->loc, "LAYOUTS_DIR", el->layoutsDir);

    el->modelsDir  = mprJoinPath(el->dir, "models");
    httpAddLocationToken(el->loc, "MODELS_DIR", el->modelsDir);

    el->staticDir = mprJoinPath(el->dir, "static");
    httpAddLocationToken(el->loc, "STATIC_DIR", el->staticDir);

    el->viewsDir = mprJoinPath(el->dir, "views");
    httpAddLocationToken(el->loc, "VIEWS_DIR", el->viewsDir);
}


static void addRoute(EspLoc *el, cchar *name, cchar *methods, cchar *pattern, cchar *action, cchar *controller, 
        cchar *prefix, cchar *controllerPattern)
{
    pattern = sfmt(pattern, prefix);
    action = sfmt(action, controllerPattern);
    controller = sfmt(controller, controllerPattern);
    mprAddItem(el->routes, espCreateRoute(name, methods, pattern, action, controller));
}


static int parseEsp(Http *http, cchar *key, char *value, MaConfigState *state)
{
    HttpLoc     *loc;
    HttpHost    *host;
    HttpAlias   *alias;
    HttpDir     *dir, *parentDir;
    EspLoc      *el, *parent;
    EspRoute    *route;
    char        *name, *ekey, *evalue, *prefix, *path, *next, *methods, *prior, *pattern;
    char        *action, *controller, *mvc;
    int         needRoutes;
    
    host = state->host;
    loc = state->loc;

    if (!sstarts(key, "Esp")) {
        return 0;
    }
    if ((el = httpGetLocationData(loc, ESP_NAME)) == 0) {
        if (loc->parent && (parent = httpGetLocationData(loc->parent, ESP_NAME)) != 0) {
            el = cloneEspLoc(parent, loc);
        } else {
            el = allocEspLoc(loc);
        }
        if (el == 0) {
            return MPR_ERR_MEMORY;
        }
    }
    mprAssert(el);
    mprAssert(el->loc);

    if (scasecmp(key, "EspAlias") == 0) {
        /*
            EspAlias prefix [path [mvc]]
            If the prefix matches an existing location block, it modifies that. Otherwise a new location is created.
         */
        if (maGetConfigValue(&prefix, value, &next, 1) < 0) {
            return MPR_ERR_BAD_SYNTAX;
        }
        if (maGetConfigValue(&path, next, &next, 1) < 0) {
            path = ".";
        }
        maGetConfigValue(&mvc, next, &next, 1);
        prefix = stemplate(prefix, loc->tokens);
        if (scmp(prefix, "/") == 0) {
            prefix = MPR->emptyString;
        }
        needRoutes = 0;
        if ((loc = httpLookupLocation(host, prefix)) == 0) {
            /*
                This EjsAlias is for a new location. Create a location block and set needRoutes
             */
            loc = httpCreateInheritedLocation(state->loc);
            el = cloneEspLoc(el, loc);
            httpSetLocationHost(loc, host);
            httpSetLocationPrefix(loc, prefix);
            httpSetLocationAuth(loc, state->dir->auth);
            httpAddLocation(host, loc);
            httpSetHandler(loc, "espHandler");
            needRoutes++;
        } else {
            httpAddHandler(loc, "espHandler", 0);
        }
        path = httpMakePath(loc, path);
        el->dir = mprGetAbsPath(path);
        if (httpLookupDir(host, path) == 0) {
            parentDir = mprGetFirstItem(host->dirs);
            dir = httpCreateDir(path, parentDir);
            httpAddDir(host, dir);
        }
        if (loc->alias == 0) {
            alias = httpCreateAlias(prefix, path, 0);
            mprLog(4, "EspAlias \"%s\" for \"%s\"", prefix, path);
            httpSetLocationAlias(loc, alias);
            httpAddAlias(host, alias);
        }
        if (mvc) {
            setMvcDirs(el);
            el->routes = mprCreateList(-1, 0);
            mprAddItem(el->routes, espCreateRoute("home", "GET,POST,PUT", "%^/$", 
                stemplate("${STATIC_DIR}/index.esp", loc->tokens), NULL));
            mprAddItem(el->routes, espCreateRoute("static", "GET", "%^/static/(.*)", 
                stemplate("${STATIC_DIR}/$1", loc->tokens), NULL));
            mprAddItem(el->routes, 
                espCreateRoute("default", NULL, "^/{controller}(/{action})", "${controller}-${action}", "${controller}.c"));
        }
        if (mvc || needRoutes) {
            mprAddItem(el->routes, espCreateRoute("esp", NULL, "%\\.[eE][sS][pP]$", NULL, NULL));
        }
        return 1;

    } else if (scasecmp(key, "EspCompile") == 0) {
        el->compile = sclone(value);
        return 1;

    } else if (scasecmp(key, "EspDir") == 0) {
        /*
            EspDir name dir
         */
        if (maGetConfigValue(&name, value, &next, 1) < 0) {
            return MPR_ERR_BAD_SYNTAX;
        }
        if (scmp(name, "mvc") == 0) {
            setMvcDirs(el);
        } else {
            path = stemplate(mprJoinPath(el->dir, next), loc->tokens);
            if (scmp(name, "cache") == 0) {
                el->cacheDir = path;
            } if (scmp(name, "controllers") == 0) {
                el->controllersDir = path;
            } else if (scmp(name, "databases") == 0) {
                el->databasesDir = path;
            } else if (scmp(name, "layouts") == 0) {
                el->layoutsDir = path;
            } else if (scmp(name, "models") == 0) {
                el->modelsDir = path;
            } else if (scmp(name, "static") == 0) {
                el->staticDir = path;
            } else if (scmp(name, "views") == 0) {
                el->viewsDir = path;
            }
            httpAddLocationToken(loc, name, path);
        }
        return 1;

    } else if (scasecmp(key, "EspEnv") == 0) {
        if (maGetConfigValue(&ekey, value, &next, 1) < 0) {
            return MPR_ERR_BAD_SYNTAX;
        }
        if (maGetConfigValue(&evalue, next, &next, 1) < 0) {
            return MPR_ERR_BAD_SYNTAX;
        }
        if (el->env == 0) {
            el->env = mprCreateList(-1, 0);
        }
        if ((prior = getenv(ekey)) != 0) {
            mprAddItem(el->env, sfmt("%s=%s;%s", ekey, evalue, prior));
        } else {
            mprAddItem(el->env, sfmt("%s=%s", ekey, evalue));
        }
        if (scasecmp(ekey, "PATH") == 0) {
            if (el->searchPath) {
                el->searchPath = sclone(evalue);
            } else {
                el->searchPath = sjoin(el->searchPath, MPR_SEARCH_SEP, evalue, 0);
            }
        }
        return 1;

    } else if (scasecmp(key, "EspKeepSource") == 0) {
        el->keepSource = (scasecmp(value, "on") == 0 || scasecmp(value, "yes") == 0);
        return 1;

    } else if (scasecmp(key, "EspLifespan") == 0) {
        el->lifespan = ((MprTime) atoi(value)) * MPR_TICKS_PER_SEC;
        return 1;

    } else if (scasecmp(key, "EspLink") == 0) {
        el->link = sclone(value);
        return 1;

    } else if (scasecmp(key, "EspLoad") == 0) {
        el->app = mprJoinPath(el->cacheDir, "app");
        return 1;

    } else if (scasecmp(key, "EspReset") == 0) {
        if (scasecmp(value, "all") == 0) {
            el = allocEspLoc(loc);
        } else if (scasecmp(value, "routes") == 0) {
            el->routes = mprCreateList(-1, 0);
        }
        return 1;

    } else if (scasecmp(key, "EspRestfulRoutes") == 0) {
        /*
            EspRestfulRoutes [/prefix controller]
         */
        if (maGetConfigValue(&prefix, value, &controller, 1) < 0 || value == 0 || *value == '\0') {
            prefix = "{controller}";
            controller = "${controller}";
        }
        prefix = strim(prefix, "/", MPR_TRIM_START);
        addRoute(el, "init",    "GET",    "^/%s/init",       "%s-init",      "%s.c", prefix, controller);
        addRoute(el, "index",   "GET",    "^/%s(/)$",        "%s-index",     "%s.c", prefix, controller);
        addRoute(el, "create",  "POST",   "^/%s(/)",         "%s-create",    "%s.c", prefix, controller);
        addRoute(el, "edit",    "GET",    "^/%s/{id}/edit",  "%s-edit",      "%s.c", prefix, controller);
        addRoute(el, "show",    "GET",    "^/%s/{id}",       "%s-show",      "%s.c", prefix, controller);
        addRoute(el, "update",  "PUT",    "^/%s/{id}",       "%s-update",    "%s.c", prefix, controller);
        addRoute(el, "destroy", "DELETE", "^/%s/{id}",       "%s-destroy",   "%s.c", prefix, controller);
        addRoute(el, "default", "ALL",    "^/%s(/{action})", "%s-${action}", "%s.c", prefix, controller);
        return 1;

    } else if (scasecmp(key, "EspRoute") == 0) {
        /*
            EspRoute name methods pattern action [controller]
         */
        if (maGetConfigValue(&name, value, &next, 1) < 0) {
            return MPR_ERR_BAD_SYNTAX;
        }
        if (maGetConfigValue(&methods, next, &next, 1) < 0) {
            return MPR_ERR_BAD_SYNTAX;
        }
        if (maGetConfigValue(&pattern, next, &next, 1) < 0) {
            return MPR_ERR_BAD_SYNTAX;
        }
        maGetConfigValue(&action, next, &next, 1);
        if (action) {
            action = stemplate(action, loc->tokens);
        }
        maGetConfigValue(&controller, next, &next, 1);
        if (controller) {
            controller = stemplate(controller, loc->tokens);
        }
        if ((route = espCreateRoute(name, methods, pattern, action, controller)) == 0) {
            return MPR_ERR_MEMORY;
        }
        mprAddItem(el->routes, route);
        return 1;
        
    } else if (scasecmp(key, "EspShowErrors") == 0) {
		el->showErrors = (scasecmp(value, "on") == 0 || scasecmp(value, "yes") == 0);
        return 1;

    } else if (scasecmp(key, "EspUpdate") == 0) {
        el->update = scasecmp(value, "on") == 0;
        return 1;
    }
    return 0;
}


void espManageEspLoc(EspLoc *el, int flags)
{
    if (flags & MPR_MANAGE_MARK) {
        mprMark(el->routes);
        mprMark(el->compile);
        mprMark(el->link);
        mprMark(el->env);
        mprMark(el->dir);
        mprMark(el->cacheDir);
        mprMark(el->controllersDir);
        mprMark(el->databasesDir);
        mprMark(el->layoutsDir);
        mprMark(el->modelsDir);
        mprMark(el->viewsDir);
        mprMark(el->staticDir);
        mprMark(el->searchPath);
        mprMark(el->app);
    }
}


static void manageReq(EspReq *req, int flags)
{
    if (flags & MPR_MANAGE_MARK) {
        mprMark(req->entry);
        mprMark(req->view);
        mprMark(req->controller);
        mprMark(req->source);
        mprMark(req->module);
        mprMark(req->cacheName);
        mprMark(req->cacheBuffer);
        mprMark(req->route);
        mprMark(req->el);
        mprMark(req->commandLine);
        mprMark(req->actionKey);
        mprMark(req->action);
        mprMark(req->session);
    }
}


static void manageAction(EspAction *ap, int flags)
{
    if (flags & MPR_MANAGE_MARK) {
        mprMark(ap->uri);
    }
}


static void manageEsp(Esp *esp, int flags)
{
    if (flags & MPR_MANAGE_MARK) {
        mprMark(esp->actions);
        mprMark(esp->views);
        mprMark(esp->cache);
    }
}


int maEspHandlerInit(Http *http)
{
    Esp             *ep;
    HttpStage       *handler;

    if ((handler = httpCreateHandler(http, "espHandler", HTTP_STAGE_QUERY_VARS | HTTP_STAGE_VIRTUAL, NULL)) == 0) {
        return MPR_ERR_CANT_CREATE;
    }
    handler->open = openEsp; 
    handler->start = startEsp; 
    handler->parse = (HttpParse) parseEsp; 
//MOB - fix
    if ((esp = ep = handler->stageData = mprAllocObj(Esp, manageEsp)) == 0) {
        return MPR_ERR_MEMORY;
    }
    if ((ep->views = mprCreateHash(-1, MPR_HASH_STATIC_VALUES)) == 0) {
        return 0;
    }
    if ((ep->actions = mprCreateHash(-1, 0)) == 0) {
        return 0;
    }
    if ((ep->cache = mprCreateCache(MPR_CACHE_SHARED)) == 0) {
        return MPR_ERR_MEMORY;
    }
    return 0;
}


#else /* BLD_FEATURE_ESP */

int maEspHandlerInit(Http *http)
{
    mprNop(0);
    return 0;
}


#endif /* BLD_FEATURE_ESP */
/*
    @copy   default
    
    Copyright (c) Embedthis Software LLC, 2003-2011. All Rights Reserved.
    Copyright (c) Michael O'Brien, 1993-2011. All Rights Reserved.
    
    This software is distributed under commercial and open source licenses.
    You may use the GPL open source license described below or you may acquire 
    a commercial license from Embedthis Software. You agree to be fully bound 
    by the terms of either license. Consult the LICENSE.TXT distributed with 
    this software for full details.
    
    This software is open source; you can redistribute it and/or modify it 
    under the terms of the GNU General Public License as published by the 
    Free Software Foundation; either version 2 of the License, or (at your 
    option) any later version. See the GNU General Public License for more 
    details at: http://www.embedthis.com/downloads/gplLicense.html
    
    This program is distributed WITHOUT ANY WARRANTY; without even the 
    implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
    
    This GPL license does NOT permit incorporating this software into 
    proprietary programs. If you are unable to comply with the GPL, you must
    acquire a commercial license to use this software. Commercial licenses 
    for this software and support services are available from Embedthis 
    Software at http://www.embedthis.com 
    
    Local variables:
    tab-width: 4
    c-basic-offset: 4
    End:
    vim: sw=4 ts=4 expandtab

    @end
 */
