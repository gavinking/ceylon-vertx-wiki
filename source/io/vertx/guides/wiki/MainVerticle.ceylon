import ceylon.json {
    JsonArray,
    JsonObject
}
import ceylon.time {
    now
}

import com.github.rjeschke.txtmark {
    Processor
}

import io.vertx.ceylon.core {
    Verticle,
    Future,
    newFuture=future
}
import io.vertx.ceylon.jdbc {
    JDBCClient,
    jdbcClient
}
import io.vertx.ceylon.web {
    newRouter=router,
    RoutingContext
}
import io.vertx.ceylon.web.handler {
    bodyHandler
}
import io.vertx.core.logging {
    LoggerFactory
}

import java.util {
    Arrays {
        asList
    }
}

shared class MainVerticle() extends Verticle() {

    value logger = LoggerFactory.getLogger(`MainVerticle`);

    late JDBCClient dbClient;

    void indexHandler(RoutingContext context) {
        dbClient.getConnection((connection) {
            if (!is Throwable connection) {
                connection.query(sqlAllPages,
                    (resultSet) {
                        connection.close();
                        if (!is Throwable resultSet) {
                            assert (exists results = resultSet.results); //TODO!
                            value pages =
                                    results.map((json) => json.first?.string)
                                        .coalesced;
                            context.put("title", "Wiki home");
                            context.put("pages", asList(*pages));
                            renderTemplate(context, "index.ftl");
                        } else {
                            context.fail(resultSet);
                        }
                    });
            } else {
                context.fail(connection);
            }
        });
    }

    void pageRenderingHandler(RoutingContext context) {
        value page = context.request().getParam("page");

        dbClient.getConnection((connection) {
            if (!is Throwable connection) {
                connection.queryWithParams(sqlGetPage,
                    JsonArray { page },
                    (fetch) {
                        connection.close();
                        if (!is Throwable fetch) {
                            assert (exists results = fetch.results); //TODO!
                            value row =
                                    results.first
                                    else JsonArray {
                                        -1,
                                        "# A new page

                                         Feel-free to write in Markdown!
                                         "
                                    };

                            value id = row[0];
                            value rawContent = row[1]?.string;
                            context.put("title", page);
                            context.put("id", id);
                            context.put("newPage", results.empty then "yes" else "no");
                            context.put("rawContent", rawContent);
                            context.put("content", Processor.process(rawContent));
                            context.put("timestamp", now().date().string);

                            renderTemplate(context, "page.ftl");
                        } else {
                            context.fail(fetch);
                        }
                    });
            } else {
                context.fail(connection);
            }
        });
    }

    void pageCreateHandler(RoutingContext context) {
        value pageName =
                context.request().getParam("name")
                else "";
        value location
                = pageName.empty then "/"
                else "/wiki/" + pageName;
        context.response()
            .setStatusCode(303)
            .putHeader("Location", location)
            .end();
    }

    void pageUpdateHandler(RoutingContext context) {

        value params = context.request().params();
        value id = params.get("id");
        value title = params.get("title") else "";
        value markdown = params.get("markdown") else "";
        value newPage = params.get("newPage")?.equals("yes") else false;

        dbClient.getConnection((connection) {
            if (!is Throwable connection) {
                value sql = newPage then sqlCreatePage else sqlSavePage;
                value params = newPage
                    then JsonArray { title, markdown }
                    else JsonArray { markdown, id };
                connection.updateWithParams(sql, params,
                    (update) {
                        connection.close();
                        if (!is Throwable update) {
                            context.response()
                                .setStatusCode(303)
                                .putHeader("Location", "/wiki/" + title)
                                .end();
                        } else {
                            context.fail(update);
                        }
                    });
            } else {
                context.fail(connection);
            }
        });
    }

    function prepareDatabase() {
        value future = newFuture.future();

        dbClient
                = jdbcClient.createShared(vertx,
                    JsonObject {
                        "url" -> "jdbc:hsqldb:file:db/wiki",
                        "driver_class" -> "org.hsqldb.jdbcDriver",
                        "max_pool_size" -> 30
                    });

        dbClient.getConnection((connection) {
            if (!is Throwable connection) {
                connection.execute(sqlCreatePagesTable,
                    (create) {
                        connection.close();
                        if (is Throwable create) {
                            logger.error("Database preparation error", create);
                            future.fail(create);
                        } else {
                            future.complete();
                        }
                    });
            } else {
                logger.error("Could not open a database connection", connection);
                future.fail(connection);
            }
        });

        return future;
    }

    void pageDeletionHandler(RoutingContext context) {
        value id = context.request().getParam("id");

        dbClient.getConnection((connection) {
            if (!is Throwable connection) {
                connection.updateWithParams(sqlDeletePage,
                    JsonArray { id },
                    (delete) {
                        connection.close();
                        if (!is Throwable delete) {
                            context.response()
                                .setStatusCode(303)
                                .putHeader("Location", "/")
                                .end();
                        } else {
                            context.fail(delete);
                        }
                    });
            } else {
                context.fail(connection);
            }
        });
    }

    function startHttpServer() {
        value future = newFuture.future();
        value server = vertx.createHttpServer();

        value router = newRouter.router(vertx);
        router.get("/").handler(indexHandler);
        router.get("/wiki/:page").handler(pageRenderingHandler);
        router.post().handler(bodyHandler.create().handle);
        router.post("/save").handler(pageUpdateHandler);
        router.post("/create").handler(pageCreateHandler);
        router.post("/delete").handler(pageDeletionHandler);

        server
            .requestHandler(router.accept)
            .listen(8080, (server) {
                if (!is Throwable server) {
                    logger.info("HTTP server running on port 8080");
                    future.complete();
                } else {
                    logger.error("Could not start a HTTP server", server);
                    future.fail(server);
                }
            });

        return future;
    }

    startAsync(Future<Anything> startFuture)
            => prepareDatabase()
            .compose((_) => startHttpServer())
            .setHandler((result) {
                if (!is Throwable result) {
                    startFuture.complete();
                } else {
                    startFuture.fail(result);
                }
            });

}
