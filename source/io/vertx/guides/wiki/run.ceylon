import io.vertx.ceylon.core {
    vertx
}

shared void run() {
    value name = "ceylon:`` `module`.name ``/`` `module`.version ``";
//    value name = `class MainVerticle`.qualifiedName.replace("::", ".");
    print("Deploying: " + name);
    vertx.vertx().deployVerticle(name, (result)
    => if (is Throwable result)
    then result.printStackTrace()
    else print("Deployed: " + result));
}