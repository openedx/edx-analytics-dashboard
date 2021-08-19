TOX=''

ifdef TOXENV
TOX := tox -- #to isolate each tox environment if TOXENV is defined
endif

ROOT = $(shell echo "$$PWD")
COVERAGE_DIR = $(ROOT)/build/coverage
NODE_BIN=./node_modules/.bin
PYTHON_ENV=py38
DJANGO_VERSION=django32

DJANGO_SETTINGS_MODULE ?= "analytics_dashboard.settings.local"

.PHONY: requirements clean docs

# Generates a help message. Borrowed from https://github.com/pydanny/cookiecutter-djangopackage.
help: ## display this help message
	@echo "Please use \`make <target>\` where <target> is one of"
	@perl -nle'print $& if m{^[\.a-zA-Z_-]+:.*?## .*$$}' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m  %-25s\033[0m %s\n", $$1, $$2}'

clean: ## delete generated byte code and coverage reports
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -type d -exec rm -rf {} ';' || true
	coverage erase
	rm -rf assets
	rm -rf pii_report

run-local: ## Run local (non-devstack) development server on port 8000
	python manage.py runserver 0.0.0.0:8000 --settings=analytics_dashboard.settings.local

dbshell-local: ## Run local (non-devstack) database shell
	python manage.py dbshell --settings=analytics_dashboard.settings.local

shell: ## Run Python shell
	python manage.py shell

coverage: clean
	export COVERAGE_DIR=$(COVERAGE_DIR) && \
	$(TOX)pytest --cov-report html

test_python: clean ## run pyton tests and generate coverage report
	$(TOX)pytest common analytics_dashboard --cov common --cov analytics_dashboard

quality: pycodestyle pylint isort_check ## run all code quality checks

pycodestyle:  # run pycodestyle
	$(TOX)pycodestyle acceptance_tests analytics_dashboard common

pylint:  # run pylint
	$(TOX)pylint -j 0 --rcfile=pylintrc acceptance_tests analytics_dashboard common

isort_check: ## check that isort has been run
	$(TOX)isort --check-only --recursive --diff acceptance_tests/ analytics_dashboard/ common/

isort: ## run isort to sort imports in all Python files
	$(TOX)isort --recursive --diff acceptance_tests/ analytics_dashboard/ common/

pii_check: ## check for PII annotations on all Django models
	## Not yet implemented

validate: validate_python validate_js

validate_python: test_python quality

#FIXME validate_js: requirements.js
validate_js:
	npm run test
	npm run lint -s

migrate: ## apply database migrations
	python manage.py migrate  --run-syncdb

html_coverage: ## generate and view HTML coverage report
	# Not implemented

extract_translations: ## extract strings to be translated, outputting .mo files
	$(TOX)python manage.py makemessages -l en -v1 --ignore="docs/*" --ignore="src/*" --ignore="i18n/*" --ignore="assets/*" --ignore="static/bundles/*" -d django
	$(TOX)python manage.py makemessages -l en -v1 --ignore="docs/*" --ignore="src/*" --ignore="i18n/*" --ignore="assets/*" --ignore="static/bundles/*" -d djangojs

# TODO: Does this work?
dummy_translations: ## generate dummy translation (.po) files
	cd analytics_dashboard && i18n_tool dummy

compile_translations: # compiles djangojs and django .po and .mo files
	$(TOX)python manage.py compilemessages

generate_fake_translations: extract_translations dummy_translations compile_translations ## generate and compile dummy translation files

pull_translations: ## pull translations from Transifex
	cd analytics_dashboard && tx pull -af

push_translations: ## push source translation files (.po) from Transifex
	cd analytics_dashboard && tx push -s

detect_changed_source_translations: ## check if translation files are up-to-date
	cd analytics_dashboard && i18n_tool changed

update_translations: pull_translations generate_fake_translations

# extract, compile, and check if translation files are up-to-date
validate_translations: extract_translations compile_translations detect_changed_source_translations
	i18n_tool validate -

# Docker commands

docker_build:
	docker build . --target app -t "openedx/insights:latest"
	docker build . --target newrelic -t "openedx/insights:latest-newrelic"

docker_auth:
	echo "$$DOCKERHUB_PASSWORD" | docker login -u "$$DOCKERHUB_USERNAME" --password-stdin

docker_tag: docker_build
	docker build . --target app -t "openedx/insights:${GITHUB_SHA}"
	docker build . --target newrelic -t "openedx/insights:${GITHUB_SHA}-newrelic"

docker_push: docker_tag docker_auth ## push to docker hub
	docker push "openedx/insights:latest"
	docker push "openedx/insights:${GITHUB_SHA}"
	docker push "openedx/insights:latest-newrelic"
	docker push "openedx/insights:${GITHUB_SHA}-newrelic"

requirements: requirements.py requirements.js

requirements.py: piptools
	pip-sync -q requirements/base.txt

requirements.js:
	npm install --unsafe-perm

test.requirements: piptools
	pip-sync -q requirements/test.txt

develop: piptools requirements.js
	pip-sync -q requirements/local.txt

requirements.a11y:
	./.travis/a11y_reqs.sh

runserver_a11y:
	$(TOX)python manage.py runserver 0.0.0.0:9000 --noreload --traceback > dashboard.log 2>&1 &

accept: runserver_a11y
ifeq ("${DISPLAY_LEARNER_ANALYTICS}", "True")
	$(TOX)python manage.py waffle_flag enable_learner_analytics --create --everyone
endif
ifeq ("${ENABLE_COURSE_LIST_FILTERS}", "True")
	$(TOX)python manage.py waffle_switch enable_course_filters on --create
endif
ifeq ("${ENABLE_COURSE_LIST_PASSING}", "True")
	$(TOX)python ./manage.py waffle_switch enable_course_passing on --create
endif
	$(TOX)python manage.py create_acceptance_test_soapbox_messages
	$(TOX)pytest -v acceptance_tests --ignore=acceptance_tests/course_validation
	$(TOX)python manage.py delete_acceptance_test_soapbox_messages

# local acceptance tests are typically run with by passing in environment variables on the commandline
# e.g. API_SERVER_URL="http://localhost:9001/api/v0" API_AUTH_TOKEN="edx" make accept_local
accept_local:
	./manage.py create_acceptance_test_soapbox_messages
	pytest -v acceptance_tests --ignore=acceptance_tests/course_validation
	./manage.py delete_acceptance_test_soapbox_messages

a11y:
ifeq ("${DISPLAY_LEARNER_ANALYTICS}", "True")
	$(TOX)python manage.py waffle_flag enable_learner_analytics --create --everyone
endif
	$(TOX)pytest -v a11y_tests -k 'not NUM_PROCESSES==1' --ignore=acceptance_tests/course_validation

course_validation:
	python -m acceptance_tests.course_validation.generate_report

demo:
	python manage.py waffle_switch show_engagement_forum_activity off --create
	python manage.py waffle_switch enable_course_api off --create
	python manage.py waffle_switch display_course_name_in_nav off --create

static: ## generate static files
	$(TOX)python manage.py collectstatic --noinput

piptools:
	pip3 install -q -r requirements/pip_tools.txt

export CUSTOM_COMPILE_COMMAND = make upgrade
upgrade: piptools ## update the requirements/*.txt files with the latest packages satisfying requirements/*.in
	pip-compile --upgrade -o requirements/pip_tools.txt requirements/pip_tools.in
	pip-compile --upgrade -o requirements/base.txt requirements/base.in
	pip-compile --upgrade -o requirements/doc.txt requirements/doc.in
	pip-compile --upgrade -o requirements/test.txt requirements/test.in
	pip-compile --upgrade -o requirements/tox.txt requirements/tox.in
	pip-compile --upgrade -o requirements/local.txt requirements/local.in
	pip-compile --upgrade -o requirements/optional.txt requirements/optional.in
	pip-compile --upgrade -o requirements/production.txt requirements/production.in
	pip-compile --upgrade -o requirements/travis.txt requirements/travis.in
	# Let tox control the Django version for tests
	grep -e "^django==" requirements/base.txt > requirements/django.txt
	sed '/^[dD]jango==/d' requirements/test.txt > requirements/test.tmp
	mv requirements/test.tmp requirements/test.txt

docs:
	tox -e docs
