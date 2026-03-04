extends Node


func _on_git_hub_button_pressed():
	OS.shell_open("https://github.com/MudkipWorld/PNGTuber-Remix")

func _on_reddit_button_pressed():
	OS.shell_open("https://www.reddit.com/user/Pomeg_the_cat")

func _on_websocket_doc_pressed() -> void:
	OS.shell_open("https://github.com/vj4sothername/PNGTuber-websocket-documentation/blob/main/WebSocket_API_Documentation.md")
