Instructions
- Installer Python 3.10: https://www.python.org/ftp/python/3.10.8/python-3.10.8-amd64.exe
- Ouvrir invite de commande à l'endroit où le projet a été récupéré
- Executer: python setup.py
- Executer: .venv\Scripts\Activate.bat
- Executer: robot --outputdir results start_eurekamatic.robot
- Un navigateur Edge va ouvrir et se rendre à la page d'authentification
- S'authentifier au site manuellent
- Entrer les critères de recherche avancée et cliquer sur rechercher
- Attendre que le navigateur ferme lorsqu'il a terminé (même si semble rien faire parfois)
- Le résultat est le fichier articles.json situé dans le répertoire "results"
- Conserver articles.json à un autre endroit car il sera effacé au prochain lancement.
