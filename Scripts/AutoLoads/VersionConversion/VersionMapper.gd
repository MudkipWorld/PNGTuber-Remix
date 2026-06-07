extends Resource
class_name VersionMapper

## Which file version this converter uses
@export var from_version := ""

## Which converter it will be sent to next
@export var to_version := ""

## The Converter script that does the converting
@export var converter: GDScript
