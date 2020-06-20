#!/bin/sh

ag -l --nocolor $@ . | xargs basename -s .java
