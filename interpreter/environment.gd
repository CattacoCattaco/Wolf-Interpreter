class_name WolfEnvironment
extends RefCounted

## A reference to the interpreter which created this
var interpreter: Interpreter

var values: Dictionary[String, Variant] = {}
var types: Dictionary[String, String] = {}
