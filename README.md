# Ceylon Vert.x Wiki Example

A port of the Vert.x Wiki sample to Ceylon. 

## Requirements

This project depends on:

- Ceylon 1.3.2
- Vert.x 3.4.2

If you do not already have the Ceylon command line 
distribution installed, you don't need to install it, since
the `ceylonb` command is self-installing.

## Enabling Vert.x Ceylon support

You must [install](http://vertx.io/download/) Vert.x 3.4.2 
and then enable the `vertx` command line support for Ceylon
by:

- editing `vertx-stack.json` and setting `included` to `true` 
  for the dependency `vertx-lang-ceylon`, and then
- running `vertx resolve --dir=lib` from the Vert.x 
  installation directory.

## Compiling and running

In this directory type:

    ./ceylonb compile
    vertx run ceylon:io.vertx.guides.wiki/1.0.0

Navigate to <http://localhost:8080/>.