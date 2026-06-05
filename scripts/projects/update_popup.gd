extends ColorRect


func _ready():
	if TranslationServer.get_locale() == "fr":
		$Panel/VBoxContainer/RichTextLabel.append_text("""	
	Les mises à jour sont fortement recommandées afin d'éviter des dysfonctionnements majeurs de l'application. 
	Veuillez les effectuer dès que vous en avez la possibilité (IMPORTANT).   

	Procédure de mise à jour :
	1 - Cliquez sur le bouton "Mettre à jour".
	2 - Téléchargez la dernière version sur le site web.
	3 - Désinstallez Kollab de votre machine.
	4 - Réinstallez Kollab sur votre machine.

	Si vous rencontrez des problèmes concernant quoi que ce soit, envoyez un email au support à : 
	[color=#3ba4d8][url]contact@kollabsound.com[/url][/color] ou sur le serveur Discord : [color=#3ba4d8][url]https://discord.gg/85ekjJMCgT[/url][/color]
	""")
	else:
		$Panel/VBoxContainer/RichTextLabel.append_text("""	
	Updates are strongly recommended to avoid major application malfunctions. 
	Please update as soon as you can (IMPORTANT).   

	Update procedure :
	1 - Click on the "Update" button.
	2 - Download the latest version from the website.
	3 - Uninstall Kollab from your machine.
	4 - Reinstall Kollab on your machine.

	If you have any problems with any aspect of Kollab, please email support at : 
	[color=#3ba4d8][url]contact@kollabsound.com[/url][/color] or on the Discord server: [color=#3ba4d8][url]https://discord.gg/85ekjJMCgT[/url][/color]
	""")

func _on_dl_update_btn_pressed():
	OS.shell_open("https://kollabsound.com/download/")
