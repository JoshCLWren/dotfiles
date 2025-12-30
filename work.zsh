# Work-specific configuration for YouVersion/LifeChurch
# NOTE: Update paths and tooling for the active platform when sourcing from non-macOS hosts.

# Work-specific aliases
alias mikey='mikeybuild --aiohttp --spec ~/Code/Youversion/service-specs/services/organizations/index.yaml --app-path ~/Code/Youversion/'
alias you='cd ~/Code/YouVersion/'
alias build="red; mikey; make tests"
alias red='redspec organizations'

# Work-specific functions
redcli-auto() {
    DOCKER_DEFAULT_PLATFORM=linux/amd64 docker run \
        --mount type=bind,source="$(pwd)",destination=/hostdir,consistency=cached \
        --rm us-central1-docker.pkg.dev/yv-registry-prod-0e53/yv-production/lifechurch/youversion/red/openapi/openapi:${3:-latest} \
        /red-openapi/bin/red-openapi generate-python-project \
        --template-path /red-openapi \
        --out /hostdir/generated \
        --spec /hostdir/"$2"/services/"$1"/index.yaml \
        --remove-refs && \
    pushd generated/python/"yv-$1" > /dev/null && \
    pip uninstall -y "yv-$1" 2>/dev/null || true && \
    pip install . && \
    popd > /dev/null
}

# YV wrapper function
_yv_wrapper() {
  local command="$1"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$command" in
  shell)
    eval `yv "sh-$command" "$@"`;;
  *)
    command yv "$command" "$@";;
  esac
}
yv=_yv_wrapper

# Bible Import toolkit
# bi-activate() { eval "$(pyenv init -)"; eval "$(pyenv virtualenv-init -)"; pyenv shell bi; echo "Bible Import Toolkit environment activated."; }
alias bi-edit="code /Users/joshwren/code/youversion/bi-tools"

# GitLab token managed via .envrc files in project directories

# Source work-specific completions and scripts
[[ -f "$HOME/code/youversion/yv/libexec/../completions/yv.zsh" ]] && source "$HOME/code/youversion/yv/libexec/../completions/yv.zsh"
# Lazy load content cron logs script
if [[ -f "$HOME/code/youversion/content/get-content-cron-logs.sh" ]]; then
  get_content_cron_logs() {
    unfunction get_content_cron_logs
    source "$HOME/code/youversion/content/get-content-cron-logs.sh"
    get_content_cron_logs "$@"
  }
fi
