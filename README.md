# Test Plateforme Prestashop
Du 3 au 5 octobre 2018

## Sujet
>Mise à jour d'une application Symfony
>
> Methodologie
>
> Le candidat prépare chez lui l'exercice en se documentant et cherchant la meilleure manière de faire.
> 2 jours après, 2 personnes de Prestashop voient le candidat et il explique ce qu'il a fait et les raison qui l'ont amené à faire cela.
>
> Exercice
>
> - Écrit une application Symfony qui affiche en http sur / "hello world"
> - Fait la tourner sur un container docker
> - Met à jour l'application pour qu'elle affiche : "hello PrestaShop"
> - Met à jour le container docker avec l'application à jour avec le minimum de downtime
> - Explique nous la stratégie la plus efficace pour faire un deployment blue green

## Compte rendu

### Application Symfony

> - Écrit une application Symfony qui affiche en http sur / "hello world"

La page [setup](https://symfony.com/doc/current/setup.html) de la doc Symfony
donne une commande composer pour créer directement une application minimale via
Symfony flex.
Je n'utilise pas le `website-skeleton` qui inclue de nombreuses dépendances, mais
le basique `skeleton`.

```
$ composer create-project symfony/skeleton hello
Installing symfony/skeleton (v4.1.5.3)
  - Installing symfony/skeleton (v4.1.5.3) Downloading: 100%
Created project in hello
Loading composer repositories with package information
Installing dependencies (including require-dev) from lock file
Package operations: 20 installs, 0 updates, 0 removals
  - Installing symfony/flex (v1.1.1) Downloading: 100%

Prefetching 17 packages 🎶
  - Downloading (100%)

  - Installing psr/cache (1.0.1) Loading from cache
  - Installing psr/container (1.0.0) Loading from cache
  - Installing psr/simple-cache (1.0.1) Loading from cache
  - Installing symfony/polyfill-mbstring (v1.9.0) Loading from cache
  - Installing symfony/console (v4.1.6) Loading from cache
  - Installing symfony/routing (v4.1.6) Loading from cache
  - Installing symfony/http-foundation (v4.1.6) Loading from cache
  - Installing symfony/event-dispatcher (v4.1.6) Loading from cache
  - Installing psr/log (1.0.2) Loading from cache
  - Installing symfony/debug (v4.1.6) Loading from cache
  - Installing symfony/http-kernel (v4.1.6) Loading from cache
  - Installing symfony/finder (v4.1.6) Loading from cache
  - Installing symfony/filesystem (v4.1.6) Loading from cache
  - Installing symfony/dependency-injection (v4.1.6) Loading from cache
  - Installing symfony/config (v4.1.6) Loading from cache
  - Installing symfony/cache (v4.1.6) Loading from cache
  - Installing symfony/framework-bundle (v4.1.6) Loading from cache
  - Installing symfony/yaml (v4.1.6) Loading from cache
  - Installing symfony/dotenv (v4.1.6) Loading from cache
Generating autoload files
Symfony operations: 4 recipes (810cee2b3ce92df03e2bb28e6650fd1f)
  - Configuring symfony/flex (>=1.0): From github.com/symfony/recipes:master
  - Configuring symfony/framework-bundle (>=3.3): From github.com/symfony/recipes:master
  - Configuring symfony/console (>=3.3): From github.com/symfony/recipes:master
  - Configuring symfony/routing (>=4.0): From github.com/symfony/recipes:master
Executing script cache:clear [OK]
Executing script assets:install public [OK]
[...]
```

Une fois mon app créé via la commande, je suis en mesure d'initialiser mon repo
Git et de commencer à versionner mon projet.

```
$ cd hello
$ git init
$ git commit --allow-empty
$ git add .
$ git commit
```

Je peux immédiatement tester mon app à l'aide du server web php :
```
$ php -S 127.0.0.1:1234 -t public
```

L'url http://127.0.0.1:1234 affiche maintenant la page par défaut de Symfony.

La doc [page creation](https://symfony.com/doc/current/page_creation.html) nous
indique comment créer facilement notre page `Hello world` avec la création
d'une route et d'un contrôleur.

À la différence de la doc, je créé une classe [invocable](https://secure.php.net/manual/en/language.oop5.magic.php#object.invoke).

En effet j'ai pris l'habitude avec Symfony d'appliquer le [Action Domain Responder](http://pmjones.io/adr/)
pattern. Kevin Dunglas a expliqué sur une [issue Github](https://github.com/symfony/symfony/pull/16863#issuecomment-162221353)
comment le mettre concrètement en place avec Symfony :
- une seule action par classe de contrôleur,
- l'action est enregistrée dans Symfony comme un service,
- les dépendances de l'action sont injectées.

## Le container docker

> - Fait la tourner sur un container docker

Pour dockeriser l'application, je vais créer un container app directement à partir
du container officiel [php](https://hub.docker.com/_/php/) dans sa version FPM.
Ce container va donc intégrer le code source de l'application et un serveur FPM.

Il est à noter que pour ce container je modifie 2 fichiers de configuration:

`opcache.ini` avec la directive `opcache.validate_timestamps`
[1](https://secure.php.net/manual/en/opcache.configuration.php#ini.opcache.validate-timestamps)
à `0` afin que le cache d'opcode ne s'invalde jamais, c'est inutile car une fois
dans notre container, le code source n'est plus modifié.

`fpm.conf` pour logger sur stdout/stderr

Ce container copie l'intégralité de notre code source lors de son build, charge
le dépendances avec composer et warmup le cache pour être prêt à tourner.

Je vais aussi utiliser un 2eme container qui fera tourner [nginx](https://hub.docker.com/_/nginx/).
Nginx se contente ici de renvoyer tous les appels vers le container de l'app.

Pour faciliter les commande, j'ai créé un `Makefile` auto-documenté.

```
$ make
docker-build-app               build the app container using docker
docker-build-nginx             build the nginx container using docker
docker-logs-app                display the logs from the app container
docker-logs-nginx              display the logs from the nginx container
docker-run-app                 start running the app container
docker-run-nginx               start running the nginx container
docker-stop-app                stop the app container
docker-stop-nginx              stop the nginx container
```

Démarrage de l'app après clone :

```
$ make docker-build-app
$ make docker-build-nginx
$ make docker-run-app
$ make docker-run-nginx
```

Par défaut le makefile pour le container nginx expose le port 1234 : http://127.0.0.1:1234

## Mise à jour de l'app

> - Met à jour l'application pour qu'elle affiche : "hello PrestaShop"

L'idée c'est de simuler un changement de version de l'app on est ok ?
donc je commit juste le changement de texte :)

## Mise à jour de l'application

> - Met à jour le container docker avec l'application à jour avec le minimum de downtime

Bon alors tant qu'à faire on va tenter le 0 downtime.
Pour celà on va faire quelques petits changements dans notre manière de brancher
nos containers.
Plutôt que de lier dire

Pour cela on modifie un peu la manière de relier notre container `app` avec `nginx`.
Au lieu d'utiliser l'option `--link` lors du lancement de nginx pour le relier
au container app, on va créer un custom network pour nos container.
On associe ensuite un alias pour chacun des container lors de leur lancement,
respectivement `nginx` et `blue` (anciennement `app`).
Le but est de décoreler la relation entre nos 2 container du lancement de nginx.

A présent on peut donc démarrer une nouvelle version de notre container applicatif,
au hasard, `green`, et si on le place dans le nouveau network, il sera aussi accessible
par nginx.

Maintenant que notre nouveau container est accessible à nginx, il ne reste plus
qu'à update sa configuration pour le faire pointer sur `green` au lieu de `blue`
et on aura ainsi achevé notre mise à jour applicative.

Pour ce faire, on va utiliser un `docker exec` sur notre container nginx,
remplacer dans le `nginx.conf` l'usage du backend `blue` par `green` en utilisant
une commande `sed`.
Enfin on envoie à nginx un signal `HUP` [2](https://nginx.org/en/docs/control.html)
pour qu'il recharge sa configuration tout en terminant proprement les requètes en cours.

Donc si on reprend les étapes:
- on build le container nginx `make docker-build-nginx`
- on build le container applicatif `make docker-build-app`
- on crée le docker network `make docker-network-create`
- on démarre le container applicatif blue `make docker-run-blue`
- on démarre le container nginx `make docker-run-nginx`
- l'app fonctionne à présent sur http://127.0.0.1:1234

- on modifie notre code source dans une nouvelle version
- on build le container applicatif `make docker-build-app`
- on démarre le container applicatif green `make docker-run-green`
- on migre de blue vers green `make docker-blue2green`
- on stop blue `make docker-stop-blue`
