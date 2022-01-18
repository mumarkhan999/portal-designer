.DEFAULT_GOAL := test

TOX = ''

.PHONY: clean compile_translations dummy_translations extract_translations fake_translations help html_coverage \
	migrate pull_translations push_translations quality pii_check requirements test update_translations validate \
	dev_requirements test_requirements quality_requirements doc_requirements prod_requirements check_keywords

help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  clean                      delete generated byte code and coverage reports"
	@echo "  compile_translations       compile translation files, outputting .po files for each supported language"
	@echo "  dummy_translations         generate dummy translation (.po) files"
	@echo "  extract_translations       extract strings to be translated, outputting .mo files"
	@echo "  fake_translations          generate and compile dummy translation files"
	@echo "  help                       display this help message"
	@echo "  html_coverage              generate and view HTML coverage report"
	@echo "  migrate                    apply database migrations"
	@echo "  dev_requirements           install requirements for local development"
	@echo "  test_requirements          install requirements for testing"
	@echo "  quality_requirements       install requirements for quality"
	@echo "  doc_requirements           install requirements for documentation"
	@echo "  prod_requirements          install requirements for production"
	@echo "  pull_translations          pull translations from Transifex"
	@echo "  push_translations          push source translation files (.po) from Transifex"
	@echo "  quality                    run Pycodestyle and Pylint"
	@echo "  pii_check                  check for PII annotations on all Django models"
	@echo "  requirements               install requirements for local development"
	@echo "  test                       run tests and generate coverage report"
	@echo "  validate                   run tests, quality, and PII annotation checks"
	@echo "  start-devstack             run a local development copy of the server"
	@echo "  open-devstack              open a shell on the server started by start-devstack"
	@echo "  pkg-devstack               build the designer image from the latest configuration and code"
	@echo "  detect_changed_source_translations       check if translation files are up-to-date"
	@echo "  validate_translations      install fake translations and check if translation files are up-to-date"
	@echo ""

ifdef TOXENV
TOX := tox -- #to isolate each tox environment if TOXENV is defined
endif

clean:
	find . -name '*.pyc' -delete
	coverage erase
	rm -rf assets
	rm -rf pii_report

requirements: dev_requirements

static:
	python manage.py collectstatic --noinput

dev_requirements:
	pip install -qr requirements/dev.txt --exists-action w

test_requirements:
	pip install -qr requirements/test.txt --exists-action w

quality_requirements:
	pip install -qr requirements/quality.txt --exists-action w

doc_requirements:
	pip install -qr requirements/doc.txt --exists-action w

production-requirements:
	pip install -qr requirements.txt --exists-action w

test: clean test_requirements
	$(TOX)python -Wd -m pytest

quality: quality_requirements
	pycodestyle designer *.py
	pylint --django-settings-module=designer.settings.test --rcfile=pylintrc designer *.py

pii_check:
	DJANGO_SETTINGS_MODULE=designer.settings.test \
	code_annotations django_find_annotations --config_file .pii_annotations.yml --lint --report --coverage

validate: test quality pii_check

migrate:
	python manage.py migrate

html_coverage:
	coverage html && open htmlcov/index.html

COMMON_CONSTRAINTS_TXT=requirements/common_constraints.txt
.PHONY: $(COMMON_CONSTRAINTS_TXT)
$(COMMON_CONSTRAINTS_TXT):
	wget -O "$(@)" https://raw.githubusercontent.com/edx/edx-lint/master/edx_lint/files/common_constraints.txt || touch "$(@)"

upgrade: export CUSTOM_COMPILE_COMMAND=make upgrade
upgrade: $(COMMON_CONSTRAINTS_TXT)	## update the requirements/*.txt files with the latest packages satisfying requirements/*.in
	sed 's/pyjwt\[crypto\]<2.0.0//g' requirements/common_constraints.txt > requirements/common_constraints.tmp
	mv requirements/common_constraints.tmp requirements/common_constraints.txt
	sed 's/social-auth-core<4.0.3//g' requirements/common_constraints.txt > requirements/common_constraints.tmp
	mv requirements/common_constraints.tmp requirements/common_constraints.txt
	sed 's/edx-auth-backends<4.0.0//g' requirements/common_constraints.txt > requirements/common_constraints.tmp
	mv requirements/common_constraints.tmp requirements/common_constraints.txt
	sed 's/edx-drf-extensions<7.0.0//g' requirements/common_constraints.txt > requirements/common_constraints.tmp
	mv requirements/common_constraints.tmp requirements/common_constraints.txt
	sed 's/Django<2.3//g' requirements/common_constraints.txt > requirements/common_constraints.tmp
	mv requirements/common_constraints.tmp requirements/common_constraints.txt
	pip install -qr requirements/pip-tools.txt
	# Make sure to compile files after any other files they include!
	pip-compile --upgrade --allow-unsafe --rebuild -o requirements/pip.txt requirements/pip.in
	pip-compile --upgrade -o requirements/pip-tools.txt requirements/pip-tools.in
	pip-compile --upgrade -o requirements/base.txt requirements/base.in
	pip-compile --upgrade -o requirements/test.txt requirements/test.in
	pip-compile --upgrade -o requirements/doc.txt requirements/doc.in
	pip-compile --upgrade -o requirements/quality.txt requirements/quality.in
	pip-compile --upgrade -o requirements/dev.txt requirements/dev.in
	pip-compile --upgrade -o requirements/production.txt requirements/production.in
	# Let tox control the Django version for tests
	grep -e "^django==" requirements/production.txt > requirements/django.txt
	sed '/^[dD]jango==/d' requirements/test.txt > requirements/test.tmp
	mv requirements/test.tmp requirements/test.txt

extract_translations:
	python manage.py makemessages -l en -v1 -d django
	python manage.py makemessages -l en -v1 -d djangojs

dummy_translations:
	cd designer && i18n_tool dummy

compile_translations:
	python manage.py compilemessages

fake_translations: extract_translations dummy_translations compile_translations

pull_translations:
	tx pull -af --mode reviewed

push_translations:
	tx push -s

detect_changed_source_translations:
	cd designer && i18n_tool changed

validate_translations: fake_translations detect_changed_source_translations

# Docker commands below

dev.provision:
	bash ./provision-designer.sh

dev.init: dev.up dev.migrate

dev.makemigrations:
	docker exec -it designer.app bash -c 'cd /edx/app/designer/designer && python manage.py makemigrations'

dev.migrate: # Migrates databases. Application and DB server must be up for this to work.
	docker exec -it designer.app bash -c 'cd /edx/app/designer/designer && make migrate'

dev.up: # Starts all containers
	docker-compose up -d --build

dev.down: # Kills containers and all of their data that isn't in volumes
	docker-compose down

dev.destroy: dev.down #Kills containers and destroys volumes. If you get an error after running this, also run: docker volume rm portal-designer_designer_mysql
	docker volume rm designer_designer_mysql

dev.stop: # Stops containers so they can be restarted
	docker-compose stop

%-shell: ## Run a shell on the specified service container
	docker exec -it designer.$* bash

%-logs: ## View the logs of the specified service container
	docker-compose logs -f --tail=500 $*

attach:
	docker attach designer.app

check_keywords: ## Scan the Django models in all installed apps in this project for restricted field names
	python manage.py check_reserved_keywords --override_file db_keyword_overrides.yml
