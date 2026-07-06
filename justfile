# Run the full test suite (matches CI)
test:
    bundle exec rake test

bundle-update *ARGS:
    bundle update {{ARGS}}

# Run the full local CI equivalent (matches .github/workflows/check.yml, minus the Dropbox deploy)
ci: lint convert test

# Lint the README (CI "Check Syntax": mdl --style style.rb via check_readme.sh)
lint:
    sh check_readme.sh

# Regenerate schema artifacts from README (CI "Convert" steps)
convert:
    bundle exec ruby converter.rb
    bundle exec ruby convert_to_schema.rb
