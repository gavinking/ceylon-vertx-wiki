import io.vertx.ceylon.core.buffer {
    Buffer
}
import io.vertx.ceylon.web {
    RoutingContext
}
import io.vertx.ext.web.templ {
    FreeMarkerTemplateEngine
}

FreeMarkerTemplateEngine templateEngine
        = FreeMarkerTemplateEngine.create();

void renderTemplate(RoutingContext context,
        String template,
        String contentType = "text/html")
        => templateEngine.render(
            Util.convert(context),
            "templates/",
            template,
            (page) {
                if (page.succeeded()) {
                    context.response()
                        .putHeader("Content-Type", contentType)
                        .end(Buffer(page.result()));
                } else {
                    context.fail(page.cause());
                }
            });
