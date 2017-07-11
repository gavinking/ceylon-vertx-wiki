package io.vertx.guides.wiki;

import io.vertx.ceylon.core.buffer.Buffer;
import io.vertx.ext.web.RoutingContext;

public class Util {

    public static RoutingContext convert(io.vertx.ceylon.web.RoutingContext src) {
        return io.vertx.ceylon.web.RoutingContext.TO_JAVA.convert(src);
    }

}
